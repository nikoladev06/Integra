"""Rotas do auth-service, espelhando `contracts/auth.openapi.yaml`."""

from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import APIRouter, Depends, Response
from sqlalchemy.ext.asyncio import AsyncSession

from auth_service.database import fabrica_de_sessao
from auth_service.schemas import (
    CadastroIn,
    CadastroOut,
    LoginIn,
    ParDeTokensOut,
    RefreshIn,
    TrocarSenhaIn,
)
from auth_service.services import registro, sessoes
from integra_shared.security import UsuarioAtual


async def obter_sessao() -> AsyncIterator[AsyncSession]:
    async with fabrica_de_sessao() as sessao:
        try:
            yield sessao
            await sessao.commit()
        except Exception:
            await sessao.rollback()
            raise


SessaoDep = Annotated[AsyncSession, Depends(obter_sessao)]

router = APIRouter(prefix="/auth", tags=["sessão"])


@router.post("/register", response_model=CadastroOut, status_code=201)
async def cadastrar(dados: CadastroIn, sessao: SessaoDep) -> CadastroOut:
    """Não faz login automático: o cliente redireciona para a tela de entrada."""
    return CadastroOut(user_id=await registro.cadastrar(sessao, dados))


@router.post("/login", response_model=ParDeTokensOut)
async def entrar(dados: LoginIn, sessao: SessaoDep) -> ParDeTokensOut:
    return await sessoes.entrar(sessao, dados.email, dados.senha)


@router.post("/refresh", response_model=ParDeTokensOut)
async def renovar(dados: RefreshIn, sessao: SessaoDep) -> ParDeTokensOut:
    return await sessoes.renovar(sessao, dados.refresh_token)


@router.post("/logout", status_code=204)
async def sair(dados: RefreshIn, sessao: SessaoDep) -> Response:
    await sessoes.sair(sessao, dados.refresh_token)
    return Response(status_code=204)


@router.put("/password", status_code=204)
async def trocar_senha(dados: TrocarSenhaIn, sessao: SessaoDep, usuario: UsuarioAtual) -> Response:
    """Único caminho de mudança de senha. Não há recuperação por e-mail.

    Revoga todas as sessões, inclusive a que fez a troca — o cliente precisa
    refazer o login.
    """
    await sessoes.trocar_senha(
        sessao,
        usuario.id,
        dados.senha_atual,
        dados.nova_senha,
        dados.confirmacao,
    )
    return Response(status_code=204)
