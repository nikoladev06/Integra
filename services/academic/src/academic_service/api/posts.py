"""Rotas de post: feed, detalhe, publicação, edição, remoção e curtidas."""

from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response

from academic_service import apresentacao, usuarios
from academic_service.api.deps import (
    InstituicaoDep,
    SessaoDep,
    UsuarioDep,
    obter_instituicao_ativa,
)
from academic_service.models import Visibilidade
from academic_service.paginacao import LIMITE_MAXIMO, LIMITE_PADRAO
from academic_service.schemas import EditarPostIn, PaginaDePosts, PostOut, PublicarPostIn
from academic_service.services import curtidas, posts
from integra_shared.security import UsuarioAutenticado

router = APIRouter(prefix="/academic", tags=["posts"])

Escopo = Literal["geral", "minha"]


@router.get("/posts", response_model=PaginaDePosts)
async def feed(
    sessao: SessaoDep,
    usuario: UsuarioDep,
    escopo: Escopo = "geral",
    limit: int = Query(default=LIMITE_PADRAO, ge=1, le=LIMITE_MAXIMO),
    cursor: str | None = None,
) -> PaginaDePosts:
    """O feed institucional — a barra de escopo no topo da tela.

        geral  (padrão)  a universidade do vínculo + todas as seguidas
        minha            só a universidade do vínculo ativo

    O escopo escolhe **quais universidades** entram, nunca **qual conteúdo**: a
    matriz de visibilidade vale igual nos dois casos, e sai do vínculo do token.
    Não há parâmetro de universidade arbitrária — o conjunto vem do vínculo e da
    lista de seguidas, e não do que o cliente pedir.

    Para um aluno, `minha` é atendido **inteiramente a partir do token**, sem
    chamar o user-service — com o user-service fora do ar, o feed da própria
    instituição continua respondendo. Sem vínculo ele responde vazio, que não é
    erro: é o estado de quem ainda não informou o CPF em nenhuma instituição, e a
    tela mostra o caminho em vez de um vazio genérico.

    Para uma conta `faculdade`, "minha" é **a instituição que ela administra**, e
    essa não viaja no token: conta institucional não tem vínculo. Aí a chamada é
    inevitável, e é a mesma que autoriza publicar.
    """
    universidades = await _universidades_do_escopo(escopo, usuario)

    linhas, proximo = await posts.listar(sessao, usuario, universidades, limit, cursor)
    return PaginaDePosts(
        itens=await apresentacao.montar_posts(linhas, usuario),
        proximo_cursor=proximo,
    )


async def _universidades_do_escopo(escopo: Escopo, usuario: UsuarioAutenticado) -> list[UUID]:
    """Quais instituições entram no feed. **Nunca o que se vê dentro delas.**

    Separado da rota porque a distinção é a que o desenho todo protege: esta função
    escolhe o conjunto, e `clausula_de_visibilidade` decide o alcance. Uma função só,
    devolvendo posts, seria onde as duas coisas se misturariam.
    """
    if escopo != "minha":
        return await usuarios.universidades_do_escopo(usuario.id)

    if usuario.tipo == "faculdade":
        return [(await usuarios.universidade_da_conta(usuario.id)).id]

    return [usuario.vinculo_universidade_id] if usuario.vinculo_universidade_id else []


@router.post("/posts", response_model=PostOut, status_code=201)
async def publicar(
    dados: PublicarPostIn,
    sessao: SessaoDep,
    instituicao: InstituicaoDep,
    usuario: UsuarioDep,
) -> PostOut:
    """Publica em nome da instituição da conta autenticada.

    `InstituicaoDep` é o portão: conta `faculdade` e ativada, e a universidade que
    ela administra. A universidade **não** é campo do corpo — se fosse, uma
    faculdade publicaria no nome de outra.
    """
    post = await posts.publicar(sessao, usuario.id, instituicao, dados)
    return await apresentacao.montar_post((post, 0, 0, False), usuario)


@router.get("/posts/{postId}", response_model=PostOut)
async def detalhe(postId: UUID, sessao: SessaoDep, usuario: UsuarioDep) -> PostOut:
    """Um post por id, sujeito à matriz e **não** limitado ao escopo.

    É o caminho de quem abriu o post pelo perfil da instituição, sem seguir nem ter
    vínculo: um `publico` é legível ali. Fora do alcance responde 404, igual a
    inexistente — ver `services.posts.nao_encontrado`.
    """
    linha = await posts.obter_visivel(sessao, postId, usuario)
    return await apresentacao.montar_post(linha, usuario)


@router.patch("/posts/{postId}", response_model=PostOut)
async def editar(
    postId: UUID,
    dados: EditarPostIn,
    sessao: SessaoDep,
    instituicao: InstituicaoDep,
    usuario: UsuarioDep,
) -> PostOut:
    """Edita um post da própria instituição, alcance incluído.

    O custo está no contrato: quem já leu não é avisado da mudança. `editadoEm`
    passa a não nulo, e a tela mostra "editado" — é o que mantém a alteração
    visível em vez de silenciosa.
    """
    post = await posts.editar(sessao, postId, usuario, instituicao, dados)
    linha = await posts.obter_visivel(sessao, post.id, usuario)
    return await apresentacao.montar_post(linha, usuario)


@router.delete(
    "/posts/{postId}",
    status_code=204,
    # A dependência entra pelo decorador, e não como parâmetro: esta rota precisa
    # do **portão** (conta `faculdade` ativada), não do valor que ele devolve.
    # Recebê-lo num parâmetro que nada usa convidaria alguém a "limpar o código
    # não usado" e, com isso, abrir a rota.
    dependencies=[Depends(obter_instituicao_ativa)],
)
async def remover(
    postId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> Response:
    """Apaga. Curtidas e comentários vão junto, sem remoção lógica."""
    await posts.remover(sessao, postId, usuario)
    return Response(status_code=204)


# ────────────────────────────  curtidas  ────────────────────────────


@router.put("/posts/{postId}/curtidas", status_code=204, tags=["curtidas"])
async def curtir(postId: UUID, sessao: SessaoDep, usuario: UsuarioDep) -> Response:
    """Idempotente. Exige **poder ver** o post, não só conhecer o id."""
    await curtidas.curtir(sessao, postId, usuario)
    return Response(status_code=204)


@router.delete("/posts/{postId}/curtidas", status_code=204, tags=["curtidas"])
async def descurtir(postId: UUID, sessao: SessaoDep, usuario: UsuarioDep) -> Response:
    """Idempotente: descurtir o que não estava curtido responde 204."""
    await curtidas.descurtir(sessao, postId, usuario)
    return Response(status_code=204)


# ─────────────  posts de uma universidade (o perfil dela)  ─────────────


@router.get("/universidades/{universidadeId}/posts", response_model=PaginaDePosts)
async def da_universidade(
    universidadeId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
    visibilidade: Visibilidade | None = None,
    limit: int = Query(default=LIMITE_PADRAO, ge=1, le=LIMITE_MAXIMO),
    cursor: str | None = None,
) -> PaginaDePosts:
    """As abas do perfil da instituição, alcançado pela busca.

    Mesma matriz: para quem não tem vínculo aqui, só os `publico` — exatamente o
    que a tela promete a quem ainda não informou o CPF. Existe separada do feed
    porque o feed é limitado ao vínculo e às seguidas, e quem chegou pela busca não
    é nenhum dos dois e ainda assim tem direito aos públicos.

    `visibilidade` é o que separa as três abas — geral, institucional e por curso.
    **Filtro de apresentação, nunca de autorização:** ele entra na consulta com
    `AND` sobre a cláusula de visibilidade, então `?visibilidade=curso` sem vínculo
    naquele curso responde lista vazia, e não os restritos.
    """
    linhas, proximo = await posts.listar(
        sessao, usuario, [universidadeId], limit, cursor, visibilidade=visibilidade
    )
    return PaginaDePosts(
        itens=await apresentacao.montar_posts(linhas, usuario),
        proximo_cursor=proximo,
    )
