"""feed-service — posts profissionais de alunos e empresas.

O serviço que a Sprint 4 preparou sem escrever: o formato de comentário, a
paginação por keyset e a barra de escopo já existiam do lado acadêmico. O que é
novo aqui é o oposto do que era difícil lá — **não há matriz de visibilidade**.
Todo post é legível por qualquer conta autenticada, e o escopo é curadoria em vez
de autorização.
"""

from feed_service.api import arquivos, comentarios, posts
from feed_service.database import engine
from feed_service.settings import settings
from integra_shared import criar_app
from integra_shared.db import ping


async def _banco_responde() -> bool:
    return await ping(engine)


app = criar_app(
    "feed-service",
    verificacoes={"database": _banco_responde},
    settings=settings,
)

# `arquivos` vem ANTES de `posts`, e a ordem é a única coisa não estética neste
# laço: `/feed/posts/imagem/upload-url` e `/feed/posts/{postId}` competem, e a
# parametrizada capturaria "imagem" como id — o FastAPI responderia 422 ao validar
# o UUID sem nunca chegar à rota certa.
for router in (arquivos.router, posts.router, comentarios.router):
    app.include_router(router)
