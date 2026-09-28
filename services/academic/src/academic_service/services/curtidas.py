"""Curtir e descurtir. Idempotentes, e a idempotência é do banco.

`PUT` e `DELETE` em vez de um `POST /curtir` com corpo booleano: o método já diz
que repetir não acumula, sem o servidor ter que ler o corpo para saber o que fazer.

As duas operações **exigem poder ver o post**, e não é detalhe: sem a checagem, a
contagem de curtidas de um comunicado restrito a um curso seria alterável por quem
não pode lê-lo — e a contagem é visível para quem pode.
"""

from uuid import UUID

from sqlalchemy import delete
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from academic_service.models import Curtida
from academic_service.services import posts
from integra_shared.security import UsuarioAutenticado


async def curtir(sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado) -> None:
    """Idempotente **no banco**, não em código.

    `ON CONFLICT DO NOTHING` em vez de "consultar se já curtiu, depois inserir":
    entre a consulta e a inserção cabem duas requisições do mesmo usuário — dois
    toques rápidos no coração —, e o segundo insert violaria a chave primária com
    um 500. A chave composta (post, usuário) é o que torna a garantia estrutural.
    """
    await posts.garantir_visivel(sessao, post_id, usuario)

    await sessao.execute(
        insert(Curtida)
        .values(post_id=post_id, usuario_id=usuario.id)
        .on_conflict_do_nothing(index_elements=["post_id", "usuario_id"])
    )


async def descurtir(sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado) -> None:
    """Idempotente por natureza: apagar o que não existe apaga zero linhas."""
    await posts.garantir_visivel(sessao, post_id, usuario)

    await sessao.execute(
        delete(Curtida).where(Curtida.post_id == post_id, Curtida.usuario_id == usuario.id)
    )
