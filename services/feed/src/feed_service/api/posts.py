"""Rotas de post: feed, detalhe, publicação, edição, remoção e curtidas."""

from uuid import UUID

from fastapi import APIRouter, Query, Response

from feed_service import apresentacao, usuarios
from feed_service.api.deps import AutorDep, SessaoDep, UsuarioDep
from feed_service.escopo import Escopo
from feed_service.schemas import EditarPostIn, PaginaDePosts, PostOut, PublicarPostIn
from feed_service.services import curtidas, posts
from integra_shared.paginacao import LIMITE_MAXIMO, LIMITE_PADRAO

router = APIRouter(prefix="/feed", tags=["posts"])


@router.get("/posts", response_model=PaginaDePosts)
async def feed(
    sessao: SessaoDep,
    usuario: UsuarioDep,
    escopo: Escopo = "geral",
    limit: int = Query(default=LIMITE_PADRAO, ge=1, le=LIMITE_MAXIMO),
    cursor: str | None = None,
) -> PaginaDePosts:
    """O feed profissional — o seletor do topo da tela.

        geral     (padrão)  pessoas e empresas
        empresas            só contas `empresa`
        pessoas             só contas `aluno`

    O escopo filtra por **quem publica**, e não por instituição como no acadêmico:
    aqui não há vínculo a consultar, e o que distingue um post de outro é o tipo de
    conta que o escreveu.

    O conjunto do feed é a união de "quem o leitor segue (mais ele mesmo)" e "alunos
    com vínculo numa universidade que ele tem vínculo ou segue". O escopo entra com
    `AND` sobre essa união: ele estreita, nunca amplia — `escopo=empresas` não traz
    empresa que o leitor não siga, porque empresa não entra por recomendação.

    Lista vazia é estado normal, e não erro: é o de quem ainda não seguiu ninguém nem
    informou o CPF em nenhuma instituição. Sem o user-service a rota responde 503, e
    não um feed pela metade que pareceria completo.
    """
    conjunto = await usuarios.escopo_do_feed(usuario.id)

    linhas, proximo = await posts.listar_feed(
        sessao,
        usuario,
        conjunto.seguidos,
        conjunto.universidades,
        escopo,
        limit,
        cursor,
    )
    return PaginaDePosts(
        itens=await apresentacao.montar_posts(linhas, usuario, set(conjunto.seguidos)),
        proximo_cursor=proximo,
    )


@router.post("/posts", response_model=PostOut, status_code=201)
async def publicar(
    dados: PublicarPostIn,
    sessao: SessaoDep,
    autor_tipo: AutorDep,
    usuario: UsuarioDep,
) -> PostOut:
    """Publica em nome da conta autenticada.

    `AutorDep` é o portão: recusa `faculdade` pelo token e conta institucional
    pendente pelo banco, e devolve o tipo com que o post fica marcado.

    O vínculo do autor é copiado do token **agora**, e é o que decide a quem este
    post será recomendado daqui para frente. `origem` sai nula na resposta: quem
    acabou de publicar não precisa que o servidor explique por que está vendo o
    próprio post.
    """
    post = await posts.publicar(
        sessao,
        usuario.id,
        autor_tipo,
        usuario.vinculo_universidade_id,
        dados,
    )
    return await apresentacao.montar_post((post, 0, 0, False), usuario)


@router.get("/posts/{postId}", response_model=PostOut)
async def detalhe(postId: UUID, sessao: SessaoDep, usuario: UsuarioDep) -> PostOut:
    """Um post por id. Legível por qualquer conta autenticada.

    404 aqui significa inexistente, e só isso — não há o caso do academic-service, em
    que 404 também cobre "existe mas você não alcança".
    """
    linha = await posts.obter(sessao, postId, usuario)
    return await apresentacao.montar_post(linha, usuario)


@router.patch("/posts/{postId}", response_model=PostOut)
async def editar(
    postId: UUID,
    dados: EditarPostIn,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> PostOut:
    """Edita o próprio post: conteúdo e imagem.

    Sem `AutorDep`: editar não é publicar. Uma empresa desativada depois de publicar
    continua podendo corrigir o texto do que já está no ar — impedi-la deixaria um
    post errado imutável, o que é pior que a edição. O que a rota exige é ser o autor,
    e isso `services.posts` confere.
    """
    post = await posts.editar(sessao, postId, usuario, dados)
    linha = await posts.obter(sessao, post.id, usuario)
    return await apresentacao.montar_post(linha, usuario)


@router.delete("/posts/{postId}", status_code=204)
async def remover(postId: UUID, sessao: SessaoDep, usuario: UsuarioDep) -> Response:
    """Apaga. Curtidas e comentários vão junto; a imagem no storage fica."""
    await posts.remover(sessao, postId, usuario)
    return Response(status_code=204)


# ────────────────────────────  curtidas  ────────────────────────────


@router.put("/posts/{postId}/curtidas", status_code=204, tags=["curtidas"])
async def curtir(postId: UUID, sessao: SessaoDep, usuario: UsuarioDep) -> Response:
    """Idempotente, por chave primária composta."""
    await curtidas.curtir(sessao, postId, usuario)
    return Response(status_code=204)


@router.delete("/posts/{postId}/curtidas", status_code=204, tags=["curtidas"])
async def descurtir(postId: UUID, sessao: SessaoDep, usuario: UsuarioDep) -> Response:
    """Idempotente: descurtir o que não estava curtido responde 204."""
    await curtidas.descurtir(sessao, postId, usuario)
    return Response(status_code=204)


# ─────────────  posts de um autor (a aba do perfil)  ─────────────


@router.get("/usuarios/{userId}/posts", response_model=PaginaDePosts)
async def do_usuario(
    userId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
    limit: int = Query(default=LIMITE_PADRAO, ge=1, le=LIMITE_MAXIMO),
    cursor: str | None = None,
) -> PaginaDePosts:
    """A aba "publicações" do perfil, que a Sprint 4 deixou como vazio honesto.

    Sem escopo e sem `origem`: a pergunta "por que estou vendo isto?" não se faz numa
    lista que a pessoa pediu por nome. E **sem chamar o user-service para o
    conjunto** — só para os resumos —, então esta rota continua respondendo em
    situações em que o feed já degradou.
    """
    linhas, proximo = await posts.listar_do_autor(sessao, usuario, userId, limit, cursor)
    return PaginaDePosts(
        itens=await apresentacao.montar_posts(linhas, usuario),
        proximo_cursor=proximo,
    )
