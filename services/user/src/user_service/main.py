"""user-service — perfil, formação, vínculo e o grafo de seguidores."""

from integra_shared import criar_app
from integra_shared.db import ping
from user_service.api import busca, instituicoes, perfis, seguir, vinculos
from user_service.database import engine
from user_service.settings import settings


async def _banco_responde() -> bool:
    return await ping(engine)


app = criar_app(
    "user-service",
    verificacoes={"database": _banco_responde},
    settings=settings,
)

# A ordem importa: `/users/me` e `/users/interno` precisam ser registradas antes
# de `/users/{userId}`, senão o parâmetro de caminho captura "me" e "interno"
# como se fossem identificadores.
for router in (
    perfis.router,
    vinculos.router,
    instituicoes.router,
    busca.router,
    seguir.router,
):
    app.include_router(router)
