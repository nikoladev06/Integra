"""Curtir e descurtir. Idempotentes, e a idempotência é do banco.

`PUT` e `DELETE` em vez de um `POST /curtir` com corpo booleano: o método já diz que
repetir não acumula, sem o servidor ter que ler o corpo para saber o que fazer.

As duas exigem que o post **exista** — e só isso. No academic-service elas exigiam
poder *ver* o post, porque a contagem de curtidas de um comunicado restrito não pode
ser alterável por quem não o alcança. Aqui não há post inalcançável, então a
checagem encolhe para existência, e `garantir_existe` é o nome que diz isso.
"""

from uuid import UUID

from sqlalchemy import delete
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from feed_service.models import Curtida
from feed_service.services import posts
from integra_shared.security import UsuarioAutenticado


async def curtir(sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado) -> None:
    """Idempotente **no banco**, não em código.

    `ON CONFLICT DO NOTHING` em vez de "consultar se já curtiu, depois inserir":
    entre a consulta e a inserção cabem duas requisições do mesmo usuário — dois
    toques rápidos no coração —, e o segundo insert violaria a chave primária com um
    500.
    """
    await posts.garantir_existe(sessao, post_id)

    await sessao.execute(
        insert(Curtida)
        .values(post_id=post_id, usuario_id=usuario.id)
        .on_conflict_do_nothing(index_elements=["post_id", "usuario_id"])
    )


async def descurtir(sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado) -> None:
    """Idempotente por natureza: apagar o que não existe apaga zero linhas."""
    await posts.garantir_existe(sessao, post_id)

    await sessao.execute(
        delete(Curtida).where(Curtida.post_id == post_id, Curtida.usuario_id == usuario.id)
    )
