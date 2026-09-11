"""Endpoint `/health`, igual nos cinco serviços.

Responde 200 com `status: ok` quando tudo responde, e 503 com `status: degraded`
quando alguma dependência não. O 503 é o que importa: um serviço que responde 200
enquanto o banco está fora faz o Traefik continuar mandando tráfego para ele.
"""

from collections.abc import Awaitable, Callable

from fastapi import APIRouter, Response, status
from pydantic import BaseModel

Verificacao = Callable[[], Awaitable[bool]]


class Health(BaseModel):
    status: str
    service: str
    version: str
    dependencies: dict[str, str] = {}


def criar_router(
    nome_servico: str,
    versao: str,
    verificacoes: dict[str, Verificacao] | None = None,
) -> APIRouter:
    router = APIRouter(tags=["health"])
    verificacoes = verificacoes or {}

    @router.get("/health", response_model=Health, summary="Liveness e readiness")
    async def health(response: Response) -> Health:
        resultados: dict[str, str] = {}
        for nome, verificar in verificacoes.items():
            try:
                resultados[nome] = "ok" if await verificar() else "unreachable"
            except Exception:
                # Uma verificação que estoura não pode derrubar o próprio /health —
                # seria perder justamente o sinal de que algo está errado.
                resultados[nome] = "unreachable"

        degradado = any(v == "unreachable" for v in resultados.values())
        if degradado:
            response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE

        return Health(
            status="degraded" if degradado else "ok",
            service=nome_servico,
            version=versao,
            dependencies=resultados,
        )

    return router
