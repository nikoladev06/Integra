"""academic-service — comunicados institucionais, curtidas e comentários.

O primeiro serviço que **lê** a regra do vínculo em vez de escrevê-la. Até a
Sprint 3, vínculo era um registro que o user-service criava; aqui ele passa a
decidir o que alguém vê, e é onde a separação entre formação declarada e vínculo
verificado se prova útil ou não serve para nada.
"""

from academic_service.api import comentarios, posts
from academic_service.database import engine
from academic_service.settings import settings
from integra_shared import criar_app
from integra_shared.db import ping


async def _banco_responde() -> bool:
    return await ping(engine)


app = criar_app(
    "academic-service",
    verificacoes={"database": _banco_responde},
    settings=settings,
)

# A ordem não importa aqui, ao contrário do user-service: nenhum caminho literal
# compete com um parametrizado. `/academic/posts/{postId}` e
# `/academic/comentarios/{comentarioId}` não colidem, e `/academic/posts` tem um
# segmento a menos que os dois.
for router in (posts.router, comentarios.router):
    app.include_router(router)
