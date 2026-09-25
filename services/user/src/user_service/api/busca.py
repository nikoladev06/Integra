"""A busca unificada do cabeçalho."""

from typing import Annotated

from fastapi import APIRouter, Query

from user_service.api.deps import SessaoDep, UsuarioDep
from user_service.schemas import (
    PerfilPublicoOut,
    ResultadoDeBuscaOut,
    UniversidadeOut,
)
from user_service.services import busca

router = APIRouter(tags=["busca"])


@router.get("/busca", response_model=ResultadoDeBuscaOut)
async def buscar(
    sessao: SessaoDep,
    _: UsuarioDep,
    q: str = Query(min_length=2),
    tipos: Annotated[list[str] | None, Query()] = None,
    limitePorTipo: int = Query(default=5, le=20),
) -> ResultadoDeBuscaOut:
    """Uma consulta, resultados agrupados por tipo.

    `tipos` inválidos são ignorados em silêncio em vez de virarem 422: a caixa de
    busca é o caminho mais quente do app, e derrubar a consulta inteira por um
    valor de filtro desconhecido troca "achei menos" por "não achei nada".
    """
    pedidos = None
    if tipos:
        validos = {t for t in tipos if t in busca.TIPOS_VALIDOS}
        pedidos = frozenset(validos) if validos else None

    resultado = await busca.buscar(sessao, q, tipos=pedidos, limite_por_tipo=limitePorTipo)

    return ResultadoDeBuscaOut(
        universidades=[UniversidadeOut.model_validate(u) for u in resultado["universidades"]],
        empresas=[PerfilPublicoOut.model_validate(u) for u in resultado["empresas"]],
        pessoas=[PerfilPublicoOut.model_validate(u) for u in resultado["pessoas"]],
    )
