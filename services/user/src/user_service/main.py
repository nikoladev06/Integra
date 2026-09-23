"""user-service — perfil, tipo de conta e vínculo institucional."""

from integra_shared import criar_app
from integra_shared.db import ping
from user_service.api import instituicoes, perfis, seguir
from user_service.database import engine
from user_service.settings import settings


async def _banco_responde() -> bool:
    return await ping(engine)


app = criar_app(
    "user-service",
    verificacoes={"database": _banco_responde},
    settings=settings,
)

for router in (perfis.router, instituicoes.router, seguir.router):
    app.include_router(router)
