"""Montagem das respostas: junta o que está no banco com o que está no user-service.

Vive fora de `services/` de propósito. As funções de `services/` falam só com o
banco e são testáveis com uma sessão; estas falam HTTP com outro serviço. Misturar
os dois faria todo teste de regra de visibilidade precisar de um user-service no ar.

O trabalho é sempre o mesmo: coletar os ids que a página referencia, pedir os
resumos **em lote**, e casar. Uma página de 20 posts de 3 instituições custa uma
chamada, não vinte — e um post cuja instituição não resolve fica **fora** da
resposta, em vez de derrubá-la: sem FK entre schemas, a linha órfã é um estado
possível, e um 500 por post apagado do outro lado seria um feed inteiro perdido
por causa de um registro.
"""

from academic_service import usuarios
from academic_service.models import Comentario, Post
from academic_service.schemas import (
    AutorDeComentarioOut,
    ComentarioOut,
    CursoOut,
    InstituicaoDoPostOut,
    PostOut,
)
from academic_service.services.comentarios import pode_remover
from academic_service.services.posts import LinhaDeFeed, nao_encontrado
from integra_shared.security import UsuarioAutenticado


async def montar_posts(linhas: list[LinhaDeFeed], usuario: UsuarioAutenticado) -> list[PostOut]:
    """Converte linhas do banco em `PostOut`, resolvendo as instituições em lote."""
    if not linhas:
        return []

    resumos = await usuarios.resumos_de_universidades({post.universidade_id for post, *_ in linhas})

    saida: list[PostOut] = []
    for post, curtidas, comentarios, curtiu in linhas:
        instituicao = resumos.get(post.universidade_id)
        if instituicao is None:
            # A universidade não existe mais no user-service. Silenciar é a escolha
            # certa aqui: o post perdeu o autor institucional, e um card sem
            # cabeçalho não é conteúdo.
            continue

        curso = instituicao.curso(post.curso_id) if post.restrito_a_curso else None

        saida.append(
            PostOut(
                id=post.id,
                instituicao=InstituicaoDoPostOut(
                    id=instituicao.id,
                    nome=instituicao.nome,
                    sigla=instituicao.sigla,
                    foto_url=instituicao.foto_url,
                ),
                visibilidade=post.visibilidade,
                curso=CursoOut(id=curso.id, nome=curso.nome) if curso else None,
                conteudo=post.conteudo,
                total_de_curtidas=curtidas,
                total_de_comentarios=comentarios,
                curtido_por_mim=curtiu,
                # Quem edita e apaga é a conta autora, e só ela. A tela lê isto em
                # vez de comparar ids por conta própria — e concluir diferente do
                # servidor num caso de borda.
                pode_editar=post.autor_id == usuario.id,
                criado_em=post.criado_em,
                editado_em=post.editado_em,
            )
        )

    return saida


async def montar_post(linha: LinhaDeFeed, usuario: UsuarioAutenticado) -> PostOut:
    """Um post só. Levanta se a instituição não resolver.

    Diferente do feed: aqui o cliente pediu **este** post, e devolver 404 por uma
    instituição apagada é mais honesto que devolver o post sem cabeçalho.
    """
    montados = await montar_posts([linha], usuario)
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
    `services.comentarios`. Uma segunda escrita da regra produziria botão que
    aparece na tela e é recusado pelo servidor.
    """
    if not comentarios:
        return []

    autores = await usuarios.resumos_de_autores({c.autor_id for c in comentarios})

    saida: list[ComentarioOut] = []
    for comentario in comentarios:
        autor = autores.get(comentario.autor_id)
        if autor is None:
            # Conta apagada. O comentário fica fora em vez de aparecer como
            # "anônimo": atribuir texto a ninguém é pior que omitir a linha.
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
