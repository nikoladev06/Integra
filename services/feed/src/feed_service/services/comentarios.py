"""Comentários sob um post profissional.

Mesmo formato do academic-service, com uma diferença de sujeito na moderação: lá
quem remove comentário de terceiro é a **faculdade autora do comunicado**; aqui é a
pessoa (ou empresa) autora do post. A regra é a mesma — quem publicou manda no que
está embaixo — e sem ela a única saída para tirar algo do próprio post seria apagar
o post inteiro.

O que **não** se repete daqui é a checagem de visibilidade antes de cada operação.
Lá toda função começava por `garantir_visivel`, porque uma listagem de comentários
aberta entregaria a discussão de um post restrito sem nunca devolver o post. Aqui não
há post restrito, então o que se confere é que o post existe.
"""

from uuid import UUID

from sqlalchemy import select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

from feed_service.models import Comentario, Post
from feed_service.schemas import ComentarIn
from feed_service.services import posts
from integra_shared import paginacao
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado


async def listar(
    sessao: AsyncSession,
    post_id: UUID,
    limite: int,
    cursor: str | None,
) -> tuple[list[Comentario], str | None]:
    """Do mais antigo para o mais novo — conversa se lê na ordem em que aconteceu.

    A ordem crescente inverte o keyset em relação ao feed (`>` em vez de `<`), e é a
    única diferença entre as duas paginações. Vale a repetição: uma função genérica
    com um parâmetro de direção esconderia qual das duas ordens uma rota usa, e a
    ordem é justamente o que muda o significado da lista.
    """
    await posts.garantir_existe(sessao, post_id)

    limite = paginacao.limite_valido(limite)
    consulta = (
        select(Comentario)
        .where(Comentario.post_id == post_id)
        .order_by(Comentario.criado_em.asc(), Comentario.id.asc())
    )

    if cursor:
        data, id_ = paginacao.decodificar(cursor)
        consulta = consulta.where(tuple_(Comentario.criado_em, Comentario.id) > tuple_(data, id_))

    encontrados = list((await sessao.execute(consulta.limit(limite + 1))).scalars())

    tem_mais = len(encontrados) > limite
    pagina = encontrados[:limite]
    proximo = None
    if tem_mais and pagina:
        proximo = paginacao.codificar(pagina[-1].criado_em, pagina[-1].id)

    return pagina, proximo


async def comentar(
    sessao: AsyncSession,
    post_id: UUID,
    usuario: UsuarioAutenticado,
    dados: ComentarIn,
) -> Comentario:
    """Comenta. Qualquer conta autenticada, inclusive a autora do post."""
    await posts.garantir_existe(sessao, post_id)

    comentario = Comentario(
        post_id=post_id,
        autor_id=usuario.id,
        conteudo=dados.conteudo_limpo,
    )
    sessao.add(comentario)
    await sessao.flush()
    await sessao.refresh(comentario)
    return comentario


async def remover(sessao: AsyncSession, comentario_id: UUID, usuario: UsuarioAutenticado) -> None:
    """O autor do comentário, ou o autor do post."""
    comentario = await sessao.get(Comentario, comentario_id)
    if comentario is None:
        raise _nao_encontrado()

    post = await posts.garantir_existe(sessao, comentario.post_id)

    if not pode_remover(comentario, post, usuario):
        raise _nao_encontrado()

    await sessao.delete(comentario)
    await sessao.flush()


def pode_remover(comentario: Comentario, post: Post, usuario: UsuarioAutenticado) -> bool:
    """Autor do comentário, ou autor do post.

    Função nomeada porque a mesma regra aparece duas vezes: aqui, para autorizar, e
    na montagem de `ComentarioOut.podeRemover`, para a tela decidir se mostra o
    botão. Duas escritas divergiriam, e o sintoma seria um botão que existe na tela e
    é recusado pelo servidor.
    """
    return usuario.id in (comentario.autor_id, post.autor_id)


def _nao_encontrado() -> AppError:
    """Inexistente, ou de outra pessoa sob post que não é seu. Mesma resposta."""
    return AppError(code="nao_encontrado", message="Comentário não encontrado", status_code=404)
