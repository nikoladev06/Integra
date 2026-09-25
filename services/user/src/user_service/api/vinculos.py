"""Rotas de formação e vínculo.

As duas juntas num arquivo de propósito: elas são fáceis de confundir, e ler as
rotas lado a lado deixa claro que formação é currículo e vínculo é acesso.
"""

from uuid import UUID

from fastapi import APIRouter, Response

from user_service.api.deps import SessaoDep, UsuarioDep
from user_service.schemas import (
    CriarVinculoIn,
    DeclararFormacaoIn,
    FormacaoOut,
    VinculoOut,
)
from user_service.services import formacoes, vinculos

router = APIRouter()


# ────────────────────────────  formação  ────────────────────────────


@router.post("/users/me/formacoes", response_model=FormacaoOut, status_code=201, tags=["formação"])
async def declarar_formacao(
    dados: DeclararFormacaoIn, sessao: SessaoDep, usuario: UsuarioDep
) -> FormacaoOut:
    """Sem nenhuma verificação. Nasce com `verificadaEm: null`."""
    criada = await formacoes.declarar(sessao, usuario.id, dados.universidade_id, dados.curso_id)
    return FormacaoOut.model_validate(criada)


@router.delete("/users/me/formacoes/{formacaoId}", status_code=204, tags=["formação"])
async def remover_formacao(
    formacaoId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> Response:
    await formacoes.remover(sessao, usuario.id, formacaoId)
    return Response(status_code=204)


# ─────────────────────────────  vínculo  ─────────────────────────────


@router.post(
    "/universidades/{universidadeId}/vinculo",
    response_model=VinculoOut,
    status_code=201,
    tags=["vínculo"],
)
async def criar_vinculo(
    universidadeId: UUID,
    dados: CriarVinculoIn,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> VinculoOut:
    """O item "inserir CPF" do menu do perfil da faculdade.

    O CPF é conferido **contra o da própria conta** antes de ser procurado na
    lista da instituição. Ver `services/vinculos.criar` para o porquê.
    """
    criado = await vinculos.criar(sessao, usuario.id, universidadeId, dados.cpf)
    return VinculoOut.model_validate(criado)


@router.get("/users/me/vinculo", response_model=VinculoOut | None, tags=["vínculo"])
async def meu_vinculo(sessao: SessaoDep, usuario: UsuarioDep) -> VinculoOut | None:
    vinculo = await vinculos.obter(sessao, usuario.id)
    return VinculoOut.model_validate(vinculo) if vinculo else None


@router.delete("/users/me/vinculo", status_code=204, tags=["vínculo"])
async def encerrar_vinculo(sessao: SessaoDep, usuario: UsuarioDep) -> Response:
    """O aluno sai quando quiser. Idempotente, e a formação segue verificada."""
    await vinculos.encerrar(sessao, usuario.id)
    return Response(status_code=204)
