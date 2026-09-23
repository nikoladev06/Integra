"""Rotas do grafo de seguidores."""

from uuid import UUID

from fastapi import APIRouter, Response

from user_service.api.deps import SessaoDep, UsuarioDep
from user_service.models import TipoConta
from user_service.schemas import PerfilPublicoOut, UniversidadeSeguidaOut
from user_service.services import seguir

router = APIRouter(prefix="/users/me/seguindo", tags=["seguir"])


@router.get("/universidades", response_model=list[UniversidadeSeguidaOut])
async def universidades_seguidas(
    sessao: SessaoDep, usuario: UsuarioDep
) -> list[UniversidadeSeguidaOut]:
    return await seguir.listar_universidades(sessao, usuario.id)


@router.put("/universidades/{universidadeId}", status_code=204)
async def seguir_universidade(
    universidadeId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> Response:
    await seguir.seguir_universidade(sessao, usuario.id, universidadeId)
    return Response(status_code=204)


@router.delete("/universidades/{universidadeId}", status_code=204)
async def deixar_de_seguir_universidade(
    universidadeId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> Response:
    await seguir.deixar_de_seguir_universidade(sessao, usuario.id, universidadeId)
    return Response(status_code=204)


@router.get("/usuarios", response_model=list[PerfilPublicoOut])
async def usuarios_seguidos(
    sessao: SessaoDep, usuario: UsuarioDep, tipo: TipoConta | None = None
) -> list[PerfilPublicoOut]:
    seguidos = await seguir.listar_usuarios(sessao, usuario.id, tipo)
    return [PerfilPublicoOut.model_validate(u) for u in seguidos]


@router.put("/usuarios/{userId}", status_code=204)
async def seguir_usuario(
    userId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> Response:
    await seguir.seguir_usuario(sessao, usuario.id, userId)
    return Response(status_code=204)


@router.delete("/usuarios/{userId}", status_code=204)
async def deixar_de_seguir_usuario(
    userId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> Response:
    await seguir.deixar_de_seguir_usuario(sessao, usuario.id, userId)
    return Response(status_code=204)
