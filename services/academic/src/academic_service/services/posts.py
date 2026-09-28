"""Publicar, ler, editar e apagar comunicados.

Duas decisões atravessam o arquivo inteiro:

**Toda leitura passa pela cláusula de visibilidade.** Não existe função aqui que
devolva um post sem filtrar — nem a que carrega um post por id para curtir ou
comentar. Se existisse, ela seria o atalho que a próxima rota usaria.

**"Não pode ver" e "não existe" respondem igual.** Um 403 confirmaria que existe
um comunicado restrito naquele id; iterando ids, alguém sem vínculo mapearia
quantos posts internos uma faculdade tem e quando publica. O status distinto não
ajudaria quem depura o suficiente para pagar isso.
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import Select, and_, func, literal, select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

from academic_service import paginacao
from academic_service.models import Comentario, Curtida, Post, Visibilidade
from academic_service.schemas import EditarPostIn, PublicarPostIn
from academic_service.usuarios import UniversidadeDaConta
from academic_service.visibilidade import clausula_de_visibilidade
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado

# Uma linha do feed: o post e os três agregados que dependem de quem está lendo.
LinhaDeFeed = tuple[Post, int, int, bool]


def _campo_invalido(campo: str, mensagem: str) -> AppError:
    """422 nomeando o campo, para o formulário destacar a linha certa.

    O Pydantic não dá conta destas: elas cruzam dois campos (`visibilidade` e
    `cursoId`) ou dependem do que já está gravado no post. Ver a nota em
    `schemas.PublicarPostIn`.
    """
    return AppError(
        code="validation_error",
        message="Verifique os campos destacados",
        status_code=422,
        fields={campo: [mensagem]},
    )


def nao_encontrado() -> AppError:
    """Post inexistente **ou** fora do alcance do leitor. Mesma resposta.

    A mesma disciplina do "inserir CPF" no user-service: dois casos distintos para
    quem depura, uma informação só para quem sonda.
    """
    return AppError(code="nao_encontrado", message="Post não encontrado", status_code=404)


# ────────────────────────────  publicação  ────────────────────────────


async def publicar(
    sessao: AsyncSession,
    autor_id: UUID,
    universidade: UniversidadeDaConta,
    dados: PublicarPostIn,
) -> Post:
    """Publica em nome da instituição da conta autora.

    `universidade` já vem do user-service com o estado de ativação e a lista de
    cursos — a rota é que decide o que fazer com `conta_ativa`, porque a resposta
    é 403 de autorização e não pertence a esta camada.

    O que esta função garante é a coerência do alcance, nos dois sentidos: post
    restrito precisa de um curso **desta** instituição, e post que não é restrito
    não leva `cursoId`.
    """
    _conferir_alcance(dados.visibilidade, dados.curso_id, universidade)

    post = Post(
        universidade_id=universidade.id,
        autor_id=autor_id,
        visibilidade=dados.visibilidade,
        curso_id=dados.curso_id,
        conteudo=dados.conteudo_limpo,
    )
    sessao.add(post)
    await sessao.flush()
    await sessao.refresh(post)
    return post


def _conferir_alcance(
    visibilidade: Visibilidade,
    curso_id: UUID | None,
    universidade: UniversidadeDaConta,
) -> None:
    """A invariante de alcance, na publicação e na edição.

    Uma função, porque as duas rotas precisam da mesma checagem, e porque o
    `CheckConstraint` do banco recusaria a linha de qualquer jeito: melhor um 422
    com o campo nomeado do que o Postgres devolvendo 500.

    Recusar o `cursoId` sobrando, em vez de ignorá-lo, é o ponto: aceito em
    silêncio num post `institucional`, ele pareceria uma restrição que não existe,
    e quem publicou acharia que restringiu.
    """
    if visibilidade != Visibilidade.CURSO:
        if curso_id is not None:
            raise _campo_invalido("cursoId", "Só posts restritos a curso levam cursoId")
        return

    if curso_id is None:
        raise _campo_invalido("cursoId", "Escolha o curso a que o post fica restrito")
    if not universidade.tem_curso(curso_id):
        raise _campo_invalido("cursoId", "Este curso não é da sua instituição")


async def editar(
    sessao: AsyncSession,
    post_id: UUID,
    usuario: UsuarioAutenticado,
    universidade: UniversidadeDaConta,
    dados: EditarPostIn,
) -> Post:
    """Edita um post da própria instituição, alcance incluído.

    O custo de permitir mudar o alcance está registrado no contrato: quem já leu
    não é avisado. O que fica sob controle aqui são as invariantes — a edição não
    pode produzir um estado que a publicação recusaria:

    - passar a `curso` exige um `curso_id`, informado agora ou já no post;
    - sair de `curso` **limpa** `curso_id`, em vez de deixar restrição órfã;
    - o curso, quando fica, é sempre desta instituição.

    O último item vale mesmo quando o `PATCH` não mexe no curso: se a instituição
    apagou aquele curso desde a publicação, editar o texto não deve reescrever o
    post com uma restrição que não existe mais — responde 422 e diz o que corrigir.
    """
    if dados.vazio:
        raise _campo_invalido("_", "Informe ao menos um campo para alterar")

    post = await _obter_do_autor(sessao, post_id, usuario)

    visibilidade = dados.visibilidade or post.visibilidade

    if visibilidade == Visibilidade.CURSO:
        # O que falta pode estar no post gravado: passar a `curso` sem informar
        # `cursoId` é válido se o post já tinha um.
        curso_id = dados.curso_id if dados.curso_id is not None else post.curso_id
    else:
        # Sair de `curso` limpa a restrição, em vez de deixar uma órfã no registro.
        curso_id = dados.curso_id

    _conferir_alcance(visibilidade, curso_id, universidade)

    if dados.conteudo is not None:
        post.conteudo = dados.conteudo.strip()
    post.visibilidade = visibilidade
    post.curso_id = curso_id
    post.editado_em = datetime.now(UTC)

    await sessao.flush()
    await sessao.refresh(post)
    return post


async def remover(sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado) -> None:
    """Só a conta autora. Curtidas e comentários vão junto, por `ON DELETE CASCADE`.

    Sem remoção lógica: um comunicado apagado não deve seguir legível por quem
    conhecer o id.
    """
    post = await _obter_do_autor(sessao, post_id, usuario)
    await sessao.delete(post)
    await sessao.flush()


async def _obter_do_autor(sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado) -> Post:
    """O post, se existir e se for desta conta. Caso contrário, 404.

    404 e não 403, mesmo aqui: uma faculdade descobrir por diferença de status
    que existe um post de id X publicado por outra é o mesmo vazamento, só com
    outro requerente.
    """
    post = await sessao.get(Post, post_id)
    if post is None or post.autor_id != usuario.id:
        raise nao_encontrado()
    return post


# ─────────────────────────────  leitura  ─────────────────────────────


def _consulta_de_leitura(usuario: UsuarioAutenticado) -> Select:
    """A consulta base: post + agregados, já filtrada pela visibilidade.

    Os três agregados são **por leitor**, e por isso vivem na consulta em vez de
    em colunas: `curtido_por_mim` é diferente para cada pessoa que abre o feed.

    Subconsultas correlacionadas, e não `JOIN` com `GROUP BY`: com dois `JOIN`
    (curtidas e comentários) as linhas se multiplicam entre si, e as duas
    contagens saem infladas uma pela outra — o bug clássico de contar dois
    relacionamentos numa consulta só.
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

    return (
        select(Post, curtidas, comentarios, curtiu)
        .where(clausula_de_visibilidade(usuario))
        .order_by(Post.criado_em.desc(), Post.id.desc())
    )


async def obter_visivel(
    sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado
) -> LinhaDeFeed:
    """Um post por id, sujeito à matriz — e **não** limitado ao escopo.

    Um post `publico` de universidade que o leitor não segue é legível por id,
    porque é assim que o perfil da instituição o abre. Escopo é sobre quais
    instituições entram no feed; visibilidade é sobre o que se vê dentro delas.
    """
    consulta = _consulta_de_leitura(usuario).where(Post.id == post_id)
    linha = (await sessao.execute(consulta)).first()
    if linha is None:
        raise nao_encontrado()
    return (linha[0], linha[1], linha[2], linha[3])


async def garantir_visivel(
    sessao: AsyncSession, post_id: UUID, usuario: UsuarioAutenticado
) -> Post:
    """O portão de curtir e comentar.

    Existe porque **checar visibilidade na leitura e esquecer na escrita** é o erro
    clássico deste desenho. Com uma função só, a rota de comentário não tem como
    esquecer: ela não consegue o post sem passar por aqui.
    """
    consulta = (
        select(Post).where(Post.id == post_id).where(clausula_de_visibilidade(usuario)).limit(1)
    )
    post = (await sessao.execute(consulta)).scalar_one_or_none()
    if post is None:
        raise nao_encontrado()
    return post


async def listar(
    sessao: AsyncSession,
    usuario: UsuarioAutenticado,
    universidades: list[UUID] | None,
    limite: int,
    cursor: str | None,
    visibilidade: Visibilidade | None = None,
) -> tuple[list[LinhaDeFeed], str | None]:
    """Uma página do feed, do mais recente para o mais antigo.

    Três parâmetros decidem o que sai, e a diferença entre eles é o desenho todo:

    - **`usuario`** decide *o que o leitor pode ver*, pela cláusula de
      visibilidade. Vem do token, e é o único que autoriza.
    - **`universidades`** é o *escopo*: quais instituições entram. `None` significa
      sem restrição — usado pelo detalhe de um post e pelos testes, nunca pelo
      feed, porque um feed sem escopo mostraria comunicado de faculdade que o
      leitor nunca ouviu falar.
    - **`visibilidade`** é *filtro de apresentação*, das abas do perfil da
      instituição. Aplicado **junto** da cláusula, com `AND`, então ele só
      estreita: pedir `curso` sem vínculo naquele curso devolve vazio, e não os
      restritos. É por isso que ele pode vir do cliente e o vínculo não pode.

    Lista **vazia** de universidades responde página vazia sem consultar o banco.
    É o estado de quem não tem vínculo nem segue ninguém, e um `IN ()` vazio é a
    forma de escrever uma consulta que o Postgres aceita e que nunca casa — melhor
    não emiti-la.
    """
    if universidades is not None and not universidades:
        return [], None

    limite = paginacao.limite_valido(limite)
    consulta = _consulta_de_leitura(usuario)

    if universidades is not None:
        consulta = consulta.where(Post.universidade_id.in_(universidades))

    if visibilidade is not None:
        # `AND` com a cláusula de visibilidade, que `_consulta_de_leitura` já
        # aplicou. Nunca `OR`: um `OR` aqui transformaria o filtro em concessão, e
        # `?visibilidade=curso` passaria a devolver o que o leitor não alcança.
        consulta = consulta.where(Post.visibilidade == visibilidade)

    if cursor:
        data, id_ = paginacao.decodificar(cursor)
        # Comparação de tupla, na mesma ordem do `ORDER BY`. Comparar só a data
        # pularia ou repetiria posts publicados no mesmo instante.
        consulta = consulta.where(tuple_(Post.criado_em, Post.id) < tuple_(data, id_))

    # Um item além do pedido: é como se sabe que existe página seguinte sem uma
    # segunda consulta de `COUNT`, que sobre feed grande custa mais que a própria
    # página.
    resultado = (await sessao.execute(consulta.limit(limite + 1))).all()

    tem_mais = len(resultado) > limite
    linhas = [(linha[0], linha[1], linha[2], linha[3]) for linha in resultado[:limite]]
    proximo = None
    if tem_mais and linhas:
        ultimo = linhas[-1][0]
        proximo = paginacao.codificar(ultimo.criado_em, ultimo.id)

    return linhas, proximo
