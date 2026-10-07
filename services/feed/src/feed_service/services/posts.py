"""Publicar, ler, editar e apagar posts profissionais.

O contraste com `academic_service.services.posts` é o que define este arquivo:

**Nenhuma leitura filtra por permissão.** Lá toda consulta passava pela cláusula de
visibilidade, e a disciplina era não deixar existir função que devolvesse post sem
filtrar. Aqui o filtro não existe porque não há o que filtrar — todo post é legível
por qualquer conta autenticada. `garantir_existe` confere existência, e é só isso
que o nome promete.

**404 significa uma coisa só.** Lá ele cobria "não existe" e "você não alcança",
de propósito, para um 403 não confirmar que existe comunicado restrito naquele id.
Aqui só há o primeiro caso — com uma exceção: nas rotas que exigem ser o autor,
"de outra pessoa" também responde 404, para uma conta não descobrir por diferença
de status que existe um post de id X.
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import Select, and_, func, literal, select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

from feed_service import escopo as regra_de_escopo
from feed_service.models import Comentario, Curtida, Post, TipoDeAutor
from feed_service.schemas import EditarPostIn, PublicarPostIn
from integra_shared import paginacao
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado

# Uma linha do feed: o post e os três agregados que dependem de quem está lendo.
LinhaDeFeed = tuple[Post, int, int, bool]


def nao_encontrado() -> AppError:
    """Post inexistente — ou de outra conta, nas rotas que exigem ser o autor."""
    return AppError(code="nao_encontrado", message="Post não encontrado", status_code=404)


def _campo_invalido(campo: str, mensagem: str) -> AppError:
    return AppError(
        code="validation_error",
        message="Verifique os campos destacados",
        status_code=422,
        fields={campo: [mensagem]},
    )


# ────────────────────────────  publicação  ────────────────────────────


async def publicar(
    sessao: AsyncSession,
    autor_id: UUID,
    autor_tipo: TipoDeAutor,
    autor_universidade_id: UUID | None,
    dados: PublicarPostIn,
) -> Post:
    """Publica em nome da conta autenticada.

    Os três campos de autor vêm de fora do corpo, e é a ausência deles no
    `PublicarPostIn` que garante o desenho: `autor_id` do token, `autor_tipo` do
    user-service (autoritativo) e `autor_universidade_id` do vínculo no token.

    O vínculo é copiado **agora** porque é o que decide `recomendado` daqui para
    frente. Quem trocar de faculdade depois deixa este post na comunidade anterior —
    consequência escrita no contrato, e o preço de não perguntar ao user-service
    "quais usuários têm vínculo nestas universidades?" a cada página.
    """
    post = Post(
        autor_id=autor_id,
        autor_tipo=autor_tipo,
        autor_universidade_id=autor_universidade_id,
        conteudo=dados.conteudo_limpo,
        imagem_url=dados.imagem_url,
    )
    sessao.add(post)
    await sessao.flush()
    await sessao.refresh(post)
    return post


async def editar(
    sessao: AsyncSession,
    post_id: UUID,
    usuario: UsuarioAutenticado,
    dados: EditarPostIn,
) -> Post:
    """Edita o próprio post. Conteúdo e imagem, e nada mais.

    `autor_tipo` e `autor_universidade_id` não estão no corpo e não são editáveis:
    se fossem, uma edição moveria o post para outro escopo ou para a comunidade de
    outra universidade — e um post já lido mudaria de vizinhança sem ninguém saber.

    `imagemUrl: null` remove a imagem; omitir o campo a mantém. A distinção usa
    `model_fields_set`, porque comparar com `None` daria o mesmo resultado nos dois
    casos e "tire a imagem" ficaria impossível de dizer.
    """
    if dados.vazio:
        raise _campo_invalido("_", "Informe ao menos um campo para alterar")

    post = await _obter_do_autor(sessao, post_id, usuario)

    if dados.conteudo is not None:
        post.conteudo = dados.conteudo.strip()
    if dados.mencionou_imagem:
        post.imagem_url = dados.imagem_url
    post.editado_em = datetime.now(UTC)

    await sessao.flush()
    await sessao.refresh(post)
    return post


async def remover(sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado) -> None:
    """Apaga. Curtidas e comentários vão junto, por `ON DELETE CASCADE`.

    A imagem no storage fica. Apagá-la aqui acoplaria a remoção de um post à
    disponibilidade do storage — e um `DELETE` que falha porque o MinIO caiu deixa o
    usuário sem conseguir apagar o próprio post.
    """
    post = await _obter_do_autor(sessao, post_id, usuario)
    await sessao.delete(post)
    await sessao.flush()


async def _obter_do_autor(sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado) -> Post:
    """O post, se existir e se for desta conta. Caso contrário, 404 e não 403.

    404 porque um 403 confirmaria que existe um post com aquele id publicado por
    outra pessoa. Aqui o vazamento é pequeno — o post é público de qualquer forma —,
    mas o status distinto também não ajuda ninguém a depurar: quem edita o próprio
    post sabe que ele é seu.
    """
    post = await sessao.get(Post, post_id)
    if post is None or post.autor_id != usuario.id:
        raise nao_encontrado()
    return post


# ─────────────────────────────  leitura  ─────────────────────────────


def _consulta_de_leitura(usuario: UsuarioAutenticado) -> Select:
    """Post + os três agregados que dependem de quem está lendo.

    Subconsultas correlacionadas, e não `JOIN` com `GROUP BY`: com dois `JOIN`
    (curtidas e comentários) as linhas se multiplicam entre si e as duas contagens
    saem infladas uma pela outra — o bug clássico de contar dois relacionamentos
    numa consulta só.
    """
    curtidas = (
        select(func.count())
        .select_from(Curtida)
        .where(Curtida.post_id == Post.id)
        .scalar_subquery()
    )
    comentarios = (
        select(func.count())
        .select_from(Comentario)
        .where(Comentario.post_id == Post.id)
        .scalar_subquery()
    )
    curtiu = (
        select(literal(1))
        .where(and_(Curtida.post_id == Post.id, Curtida.usuario_id == usuario.id))
        .exists()
    )

    # Sem `where` de permissão, e a ausência é a diferença central em relação ao
    # academic-service. Ver o docstring do módulo.
    return select(Post, curtidas, comentarios, curtiu).order_by(
        Post.criado_em.desc(), Post.id.desc()
    )


async def obter(sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado) -> LinhaDeFeed:
    """Um post por id, com os agregados do leitor. Sem filtro de permissão."""
    consulta = _consulta_de_leitura(usuario).where(Post.id == post_id)
    linha = (await sessao.execute(consulta)).first()
    if linha is None:
        raise nao_encontrado()
    return (linha[0], linha[1], linha[2], linha[3])


async def garantir_existe(sessao: AsyncSession, post_id: UUID) -> Post:
    """O portão de curtir e comentar: o post existe.

    Existe como função nomeada pelo contraste com o acadêmico, onde a equivalente
    (`garantir_visivel`) também autorizava. Aqui ela confere só existência, e o nome
    diz isso — uma função chamada `garantir_visivel` neste serviço faria a próxima
    pessoa acreditar que há uma checagem de alcance que não existe.
    """
    post = await sessao.get(Post, post_id)
    if post is None:
        raise nao_encontrado()
    return post


async def listar_feed(
    sessao: AsyncSession,
    usuario: UsuarioAutenticado,
    seguidos: list[UUID],
    universidades: list[UUID],
    escopo: regra_de_escopo.Escopo,
    limite: int,
    cursor: str | None,
) -> tuple[list[LinhaDeFeed], str | None]:
    """Uma página do feed, do mais recente para o mais antigo.

    Dois filtros, e a diferença entre eles é o desenho:

    - **o conjunto** (`seguidos` + `universidades`) decide *quem* aparece. Vem do
      user-service, e é curadoria: errado, mostra gente a mais ou a menos.
    - **o escopo** decide *que tipo de conta* passa. Vem do cliente, e entra com
      `AND` sobre o conjunto — só estreita. Um `OR` aqui faria `escopo=empresas`
      trazer empresa que o leitor não segue, o que o contrato promete não fazer.
    """
    consulta = _consulta_de_leitura(usuario).where(
        regra_de_escopo.clausula_do_feed(usuario.id, seguidos, universidades)
    )

    filtro_de_tipo = regra_de_escopo.clausula_de_tipo(escopo)
    if filtro_de_tipo is not None:
        consulta = consulta.where(filtro_de_tipo)

    return await _paginar(sessao, consulta, limite, cursor)


async def listar_do_autor(
    sessao: AsyncSession,
    usuario: UsuarioAutenticado,
    autor_id: UUID,
    limite: int,
    cursor: str | None,
) -> tuple[list[LinhaDeFeed], str | None]:
    """A aba "publicações" de um perfil.

    Existe separada do feed pelo mesmo motivo da rota equivalente do acadêmico: o
    feed é limitado ao conjunto do leitor, e quem abriu um perfil pela busca não
    está nele. Sem escopo e sem origem — a pergunta "por que estou vendo isto?" não
    se faz numa lista que a pessoa pediu por nome.
    """
    consulta = _consulta_de_leitura(usuario).where(Post.autor_id == autor_id)
    return await _paginar(sessao, consulta, limite, cursor)


async def _paginar(
    sessao: AsyncSession,
    consulta: Select,
    limite: int,
    cursor: str | None,
) -> tuple[list[LinhaDeFeed], str | None]:
    """Keyset sobre `(criado_em, id)`, na mesma ordem do `ORDER BY`.

    Um item além do pedido: é como se sabe que existe página seguinte sem uma
    segunda consulta de `COUNT`, que sobre feed grande custa mais que a própria
    página.
    """
    limite = paginacao.limite_valido(limite)

    if cursor:
        data, id_ = paginacao.decodificar(cursor)
        # Comparação de tupla. Comparar só a data pularia ou repetiria posts
        # publicados no mesmo instante.
        consulta = consulta.where(tuple_(Post.criado_em, Post.id) < tuple_(data, id_))

    resultado = (await sessao.execute(consulta.limit(limite + 1))).all()

    tem_mais = len(resultado) > limite
    linhas: list[LinhaDeFeed] = [
        (linha[0], linha[1], linha[2], linha[3]) for linha in resultado[:limite]
    ]
    proximo = None
    if tem_mais and linhas:
        ultimo = linhas[-1][0]
        proximo = paginacao.codificar(ultimo.criado_em, ultimo.id)

    return linhas, proximo
