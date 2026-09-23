"""auth-service — identidade e sessão."""

from auth_service.api import rotas
from auth_service.database import engine
from auth_service.settings import settings
from integra_shared import criar_app
from integra_shared.db import ping


async def _banco_responde() -> bool:
    return await ping(engine)


app = criar_app(
    "auth-service",
    verificacoes={"database": _banco_responde},
    settings=settings,
)
app.include_router(rotas.router)
