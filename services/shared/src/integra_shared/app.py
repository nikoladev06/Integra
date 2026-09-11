"""Fábrica de aplicação: todo serviço Integra sobe por aqui.

Centralizar isto significa que corrigir o formato de erro, ou acrescentar um
middleware, acontece uma vez para os cinco serviços.
"""

from fastapi import FastAPI

from integra_shared import health
from integra_shared.config import Settings, obter_settings
from integra_shared.errors import registrar_handlers


def criar_app(
    nome_servico: str,
    verificacoes: dict[str, health.Verificacao] | None = None,
    settings: Settings | None = None,
) -> FastAPI:
    settings = settings or obter_settings()

    app = FastAPI(
        title=f"Integra — {nome_servico}",
        version=settings.versao,
        # Documentação interativa só fora de produção: em produção ela publica o
        # mapa completo da API para qualquer um que alcance a porta.
        docs_url="/docs" if settings.ambiente == "local" else None,
        redoc_url=None,
        openapi_url="/openapi.json" if settings.ambiente == "local" else None,
    )

    registrar_handlers(app)
    app.include_router(health.criar_router(nome_servico, settings.versao, verificacoes))
    return app
