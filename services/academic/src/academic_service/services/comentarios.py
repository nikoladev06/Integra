"""Comentários sob um comunicado.

**Só quem pode ver o post pode comentar e pode ler os comentários.** As duas
metades, e a segunda é a que se esquece: uma listagem de comentários aberta
entregaria o conteúdo da discussão de um post restrito sem nunca devolver o post.

Toda função aqui começa por `posts.garantir_visivel`. Não há caminho que chegue a
um comentário sem passar por aquela porta.
"""

from uuid import UUID

from sqlalchemy import select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

from academic_service import paginacao
from academic_service.models import Comentario, Post
from academic_service.schemas import ComentarIn
from academic_service.services import posts
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado


async def listar(
    sessao: AsyncSession,
    post_id: UUID,
    usuario: UsuarioAutenticado,
    limite: int,
    cursor: str | None,
) -> tuple[list[Comentario], str | None]:
    """Do mais antigo para o mais novo — conversa se lê na ordem em que aconteceu.

    A ordem crescente inverte o keyset em relação ao feed (`>` em vez de `<`), e é
    a única diferença entre as duas paginações. Vale a repetição: uma função
    genérica com um parâmetro de direção esconderia qual das duas ordens uma rota
    usa, e a ordem é justamente o que muda o significado da lista.
    """
    await posts.garantir_visivel(sessao, post_id, usuario)

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
    """Comenta, se puder ver o post.

    Qualquer tipo de conta comenta — inclusive a `faculdade` autora, respondendo no
    próprio comunicado. Restringir a `aluno` faria a instituição precisar de outro
    canal para responder à pergunta que alguém fez ali.
    """
    await posts.garantir_visivel(sessao, post_id, usuario)

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
    """O autor do comentário, ou a faculdade autora do post.

    A segunda metade é moderação: sem ela, a única saída de uma instituição para
    tirar algo de baixo do comunicado dela seria apagar o comunicado inteiro.

    A checagem de visibilidade vem **antes** da de propriedade, na mesma ordem do
    "inserir CPF" no user-service: quem não alcança o post não deve descobrir, por
    diferença de resposta, que existe um comentário com aquele id.
    """
    comentario = await sessao.get(Comentario, comentario_id)
    if comentario is None:
        raise _nao_encontrado()

    post = await posts.garantir_visivel(sessao, comentario.post_id, usuario)

    if not pode_remover(comentario, post, usuario):
        raise _nao_encontrado()

    await sessao.delete(comentario)
    await sessao.flush()


def pode_remover(comentario: Comentario, post: Post, usuario: UsuarioAutenticado) -> bool:
    """Autor do comentário, ou conta autora do post.

    Função nomeada porque a mesma regra aparece duas vezes: aqui, para autorizar, e
    na montagem de `ComentarioOut.podeRemover`, para a tela decidir se mostra o
    botão. Duas escritas divergiriam, e o sintoma seria um botão que existe na tela
    e é recusado pelo servidor.
    """
    return usuario.id in (comentario.autor_id, post.autor_id)


def _nao_encontrado() -> AppError:
    """Inexistente, ou de outra pessoa sob post que não é seu. Mesma resposta."""
    return AppError(code="nao_encontrado", message="Comentário não encontrado", status_code=404)
