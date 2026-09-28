"""Montagem das respostas: junta o banco com o que está no user-service.

Vive fora de `services/` de propósito, como no academic-service. As funções de
`services/` falam só com o banco e são testáveis com uma sessão; estas falam HTTP
com outro serviço. Misturar os dois faria todo teste de escopo precisar de um
user-service no ar.

O trabalho é sempre o mesmo: coletar os ids que a página referencia, pedir os
resumos **em lote**, e casar. Uma página de 20 posts de 3 autores custa uma chamada,
não vinte — e um post cujo autor não resolve fica **fora** da resposta, em vez de
derrubá-la: sem FK entre schemas, a linha órfã é um estado possível, e um 500 por
conta apagada do outro lado seria um feed inteiro perdido por causa de um registro.
"""

from uuid import UUID

from feed_service import escopo as regra_de_escopo
from feed_service import usuarios
from feed_service.models import Comentario, Post
from feed_service.schemas import (
    AutorDeComentarioOut,
    AutorDePostOut,
    ComentarioOut,
    PostOut,
)
from feed_service.services.comentarios import pode_remover
from feed_service.services.posts import LinhaDeFeed, nao_encontrado
from integra_shared.interno import ResumoDePerfil
from integra_shared.security import UsuarioAutenticado


def _autor_do_post(post: Post, resumo: ResumoDePerfil) -> AutorDePostOut:
    """O cabeçalho do card de post.

    `tipo` sai do **post**, nome e foto saem do resumo, e a divisão não é arbitrária:
    o tipo é coluna porque o escopo o filtra em SQL, e o nome não é coluna porque
    envelheceria ali — foi o que aconteceu no protótipo.
    """
    return AutorDePostOut(
        id=resumo.id,
        nome_completo=resumo.nome_completo,
        username=resumo.username,
        foto_url=resumo.foto_url,
        tipo=post.autor_tipo,
    )


async def montar_posts(
    linhas: list[LinhaDeFeed],
    usuario: UsuarioAutenticado,
    seguidos: set[UUID] | None = None,
) -> list[PostOut]:
    """Converte linhas do banco em `PostOut`, resolvendo os autores em lote.

    `seguidos` é o que decide `origem`, e é `None` fora do feed — no detalhe, na
    publicação e na aba de um perfil. Nesses casos `origem` sai nula, porque
    preenchê-la custaria uma ida ao user-service por post aberto para responder uma
    pergunta que ninguém fez ali.
    """
    if not linhas:
        return []

    resumos = await usuarios.resumos_de_autores({post.autor_id for post, *_ in linhas})

    saida: list[PostOut] = []
    for post, curtidas, comentarios, curtiu in linhas:
        autor = resumos.get(post.autor_id)
        if autor is None:
            # A conta não existe mais no user-service. O post fica fora: um card sem
            # cabeçalho não é conteúdo, e atribuir texto a "anônimo" é pior que
            # omitir a linha.
            continue

        saida.append(
            PostOut(
                id=post.id,
                autor=_autor_do_post(post, autor),
                conteudo=post.conteudo,
                imagem_url=post.imagem_url,
                origem=(
                    regra_de_escopo.origem(post.autor_id, usuario.id, seguidos)
                    if seguidos is not None
                    else None
                ),
                total_de_curtidas=curtidas,
                total_de_comentarios=comentarios,
                curtido_por_mim=curtiu,
                pode_editar=post.autor_id == usuario.id,
                criado_em=post.criado_em,
                editado_em=post.editado_em,
            )
        )

    return saida


async def montar_post(
    linha: LinhaDeFeed,
    usuario: UsuarioAutenticado,
    seguidos: set[UUID] | None = None,
) -> PostOut:
    """Um post só. Levanta 404 se o autor não resolver.

    Diferente do feed: aqui o cliente pediu **este** post, e um 404 por conta apagada
    é mais honesto que devolver o post sem cabeçalho.
    """
    montados = await montar_posts([linha], usuario, seguidos)
    if not montados:
        raise nao_encontrado()
    return montados[0]


async def montar_comentarios(
    comentarios: list[Comentario],
    post: Post,
    usuario: UsuarioAutenticado,
) -> list[ComentarioOut]:
    """Converte comentários, resolvendo os autores em lote.

    `podeRemover` é a **mesma função** que autoriza a remoção, importada de
    `services.comentarios`. Uma segunda escrita da regra produziria botão que aparece
    na tela e é recusado pelo servidor.
    """
    if not comentarios:
        return []

    autores = await usuarios.resumos_de_autores({c.autor_id for c in comentarios})

    saida: list[ComentarioOut] = []
    for comentario in comentarios:
        autor = autores.get(comentario.autor_id)
        if autor is None:
            continue

        saida.append(
            ComentarioOut(
                id=comentario.id,
                post_id=comentario.post_id,
                autor=AutorDeComentarioOut(
                    id=autor.id,
                    nome_completo=autor.nome_completo,
                    username=autor.username,
                    foto_url=autor.foto_url,
                ),
                conteudo=comentario.conteudo,
                pode_remover=pode_remover(comentario, post, usuario),
                criado_em=comentario.criado_em,
            )
        )

    return saida
