"""Rotas de perfil e busca de pessoas."""

from uuid import UUID

from fastapi import APIRouter, Query

from user_service.api.deps import SessaoDep, TokenDeServico, UsuarioDep
from user_service.schemas import (
    AtualizarPerfilIn,
    CriarUsuarioIn,
    PaginaDePerfis,
    PerfilOut,
    PerfilPublicoOut,
)
from user_service.services import perfis

router = APIRouter(tags=["perfil"])


@router.get("/users/me", response_model=PerfilOut)
async def meu_perfil(sessao: SessaoDep, usuario: UsuarioDep) -> PerfilOut:
    return PerfilOut.model_validate(await perfis.obter(sessao, usuario.id))


@router.patch("/users/me", response_model=PerfilOut)
async def atualizar_meu_perfil(
    dados: AtualizarPerfilIn, sessao: SessaoDep, usuario: UsuarioDep
) -> PerfilOut:
    return PerfilOut.model_validate(await perfis.atualizar(sessao, usuario.id, dados))


@router.get("/users", response_model=PaginaDePerfis)
async def buscar_usuarios(
    sessao: SessaoDep,
    _: UsuarioDep,
    q: str = Query(min_length=2),
    universidadeId: UUID | None = None,
    cursoId: UUID | None = None,
    limit: int = Query(default=20, le=50),
) -> PaginaDePerfis:
    achados = await perfis.buscar_pessoas(
        sessao, q, universidade_id=universidadeId, curso_id=cursoId, limite=limit
    )
    return PaginaDePerfis(
        itens=[PerfilPublicoOut.model_validate(u) for u in achados],
        proximo_cursor=None,
    )


@router.get("/users/{userId}", response_model=PerfilPublicoOut)
async def perfil_de(
    userId: UUID,
    sessao: SessaoDep,
    _: UsuarioDep,
) -> PerfilPublicoOut:
    # `PerfilPublicoOut` omite e-mail, telefone e **CPF** por construção: os
    # campos não existem no tipo de saída, então não há como uma rota nova
    # esquecer de removê-los.
    return PerfilPublicoOut.model_validate(await perfis.obter(sessao, userId))


# ───────────────────────  rotas internas (serviço)  ───────────────────────


@router.post(
    "/users/interno",
    response_model=PerfilOut,
    status_code=201,
    include_in_schema=False,
    dependencies=[TokenDeServico],
)
async def criar_interno(dados: CriarUsuarioIn, sessao: SessaoDep) -> PerfilOut:
    """Cria o perfil durante o cadastro. Chamada pelo auth-service.

    `include_in_schema=False` a mantém fora do OpenAPI público — ela não é parte
    do contrato que o cliente Flutter consome, e o guarda de deriva em
    `test_contratos.py` a ignora pelo mesmo motivo.
    """
    return PerfilOut.model_validate(await perfis.criar(sessao, dados))


@router.get(
    "/users/interno/{userId}",
    response_model=PerfilOut,
    include_in_schema=False,
    dependencies=[TokenDeServico],
)
async def perfil_interno(
    userId: UUID,
    sessao: SessaoDep,
) -> PerfilOut:
    """Perfil para o auth-service montar o access token, no login.

    Existe porque `GET /users/{userId}` exige JWT — e no login ainda não há token
    para apresentar: é justamente ele que está sendo emitido.

    Devolve `PerfilOut`, com `vinculo`, porque é de lá que saem os claims
    `vinculoUniversidadeId` e `vinculoCursoId`.
    """
    return PerfilOut.model_validate(await perfis.obter(sessao, userId))
