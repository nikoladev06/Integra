"""auth-service — identidade e sessão.

Sprint 1 entrega só o esqueleto e o `/health`. As rotas de
`contracts/auth.openapi.yaml` são implementadas na Sprint 3.
"""

from integra_shared import criar_app, obter_settings
from integra_shared.db import criar_engine, ping

settings = obter_settings()

_engine = criar_engine(settings.database_url) if settings.database_url else None


async def _banco_responde() -> bool:
    if _engine is None:
        return True
    return await ping(_engine)


app = criar_app(
    "auth-service",
    verificacoes={"database": _banco_responde} if _engine else {},
    settings=settings,
)
