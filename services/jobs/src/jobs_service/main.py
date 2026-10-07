"""jobs-service — vagas de estágio e júnior, e candidaturas de alunos.

O território mais novo da Sprint 5. O tipo de conta `empresa` já existia desde o
cadastro institucional da Sprint 3, mas nada até aqui tinha **estado** que duas
partes transicionam — e é isso que uma candidatura tem.
"""

from integra_shared import criar_app
from integra_shared.db import ping
from jobs_service.api import candidaturas, vagas
from jobs_service.database import engine
from jobs_service.settings import settings


async def _banco_responde() -> bool:
    return await ping(engine)


app = criar_app(
    "jobs-service",
    verificacoes={"database": _banco_responde},
    settings=settings,
)

# `candidaturas` vem antes de `vagas`? Não importa: os prefixos não competem —
# `/jobs/vagas/...` e `/jobs/candidaturas/...` divergem no segundo segmento. A ordem
# que importa é DENTRO de `candidaturas`, onde `/jobs/candidaturas/me` tem que ser
# registrada antes de `/jobs/candidaturas/{candidaturaId}`.
for router in (vagas.router, candidaturas.router):
    app.include_router(router)
