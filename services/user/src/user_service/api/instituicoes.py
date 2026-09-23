"""Universidades e cursos.

Sem autenticação: são consultados na tela de cadastro, antes de existir conta.
"""

from uuid import UUID

from fastapi import APIRouter

from user_service.api.deps import SessaoDep
from user_service.schemas import CursoOut, UniversidadeOut
from user_service.services import perfis

router = APIRouter(tags=["instituições"])


@router.get("/universidades", response_model=list[UniversidadeOut])
async def listar_universidades(sessao: SessaoDep, q: str | None = None) -> list[UniversidadeOut]:
    encontradas = await perfis.listar_universidades(sessao, q)
    return [UniversidadeOut.model_validate(u) for u in encontradas]


@router.get("/universidades/{universidadeId}/cursos", response_model=list[CursoOut])
async def listar_cursos(
    universidadeId: UUID,
    sessao: SessaoDep,
) -> list[CursoOut]:
    cursos = await perfis.listar_cursos(sessao, universidadeId)
    return [CursoOut.model_validate(c) for c in cursos]
