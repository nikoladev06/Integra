"""Candidatar-se, listar candidaturas e marcar como visualizada.

## O que cada lado pode

    aluno     cria a própria candidatura; lê as próprias
    empresa   lê as candidaturas das PRÓPRIAS vagas; marca visualizada

Ninguém mais alcança nenhuma das duas listas. Um aluno não vê quem mais se
candidatou — isso seria expor a concorrência de cada um a todos os outros —, e uma
empresa não vê candidatura de vaga que não é dela.

## A idempotência é do banco, e a resposta diz qual caso ocorreu

`UNIQUE (vaga, candidato)` torna impossível duas linhas para o mesmo par, nem por
dois toques rápidos no botão. O serviço consulta antes e devolve a existente com
200; a restrição é a rede de segurança para a corrida que a consulta não cobre.

201 e 200 não são cosmética: a tela mostra "candidatura enviada" no primeiro caso e
nada no segundo, porque avisar duas vezes faz o usuário achar que se candidatou duas
vezes.

## `visualizadaEm` não anda

Marcar de novo é idempotente e **não** move a data. Ela é a da primeira vez, que é o
que o aluno lê como "foi vista" — uma data que anda a cada abertura da empresa
contaria quantas vezes olharam, que não é informação que ele ganhe em ver.
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import Select, func, select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import aliased

from integra_shared import paginacao
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado
from jobs_service.models import Candidatura, EstadoDaCandidatura, Vaga
from jobs_service.services import vagas


def nao_encontrada() -> AppError:
    """Inexistente, ou de outra pessoa/empresa. Mesma resposta para os dois."""
    return AppError(
        code="nao_encontrado", message="Candidatura não encontrada", status_code=404
    )


def vaga_fechada() -> AppError:
    """409 com código próprio: não há campo a corrigir.

    A vaga encerrou entre a listagem e o toque no botão. A tela diz isso, em vez de
    pedir uma correção que não existe — que é o que um 422 faria ela dizer.
    """
    return AppError(
        code="vaga_fechada",
        message="Esta vaga não está mais recebendo candidaturas",
        status_code=409,
    )


async def candidatar(
    sessao: AsyncSession,
    vaga_id: UUID,
    usuario: UsuarioAutenticado,
) -> tuple[Candidatura, bool]:
    """Cria a candidatura, ou devolve a que já existe.

    Retorna `(candidatura, criada)`. O booleano é o que a rota usa para escolher entre
    201 e 200 — e ele sai daqui, e não de um `try/except IntegrityError`, porque a
    consulta prévia responde a pergunta que a tela faz ("já me candidatei?") sem
    depender do texto de um erro do driver.

    A ordem das duas conferências importa: **vaga existe** antes de **vaga aberta**.
    Uma vaga inexistente respondendo 409 diria que existe uma vaga fechada com aquele
    id.
    """
    vaga = await sessao.get(Vaga, vaga_id)
    if vaga is None:
        raise vagas.nao_encontrada()

    existente = (
        await sessao.execute(
            select(Candidatura).where(
                Candidatura.vaga_id == vaga_id,
                Candidatura.candidato_id == usuario.id,
            )
        )
    ).scalar_one_or_none()

    if existente is not None:
        # Antes da checagem de vaga fechada, de propósito: quem já se candidatou
        # continua vendo a própria candidatura depois de a empresa encerrar o
        # processo. Recusar aqui faria a tela dele perder o item ao recarregar.
        return existente, False

    if not vaga.aberta:
        raise vaga_fechada()

    candidatura = Candidatura(vaga_id=vaga_id, candidato_id=usuario.id)
    sessao.add(candidatura)
    await sessao.flush()
    await sessao.refresh(candidatura)
    return candidatura, True


async def marcar_visualizada(
    sessao: AsyncSession,
    candidatura_id: UUID,
    usuario: UsuarioAutenticado,
) -> Candidatura:
    """A única transição de estado do serviço, e num sentido só.

    Autoriza pela **vaga**, e não pela candidatura: quem marca é a empresa autora da
    vaga, que não é o `candidato_id` nem aparece na linha da candidatura. Carregar a
    vaga é o que torna a checagem possível — e é por isso que ela não pode ser um
    `candidatura.empresa_id` denormalizado, que envelheceria se a vaga trocasse de
    dono (não troca hoje, mas a coluna sugeriria que pode).
    """
    candidatura = await sessao.get(Candidatura, candidatura_id)
    if candidatura is None:
        raise nao_encontrada()

    vaga = await sessao.get(Vaga, candidatura.vaga_id)
    if vaga is None or vaga.empresa_id != usuario.id:
        raise nao_encontrada()

    if candidatura.estado != EstadoDaCandidatura.VISUALIZADA:
        candidatura.estado = EstadoDaCandidatura.VISUALIZADA
        candidatura.visualizada_em = datetime.now(UTC)
        await sessao.flush()
        await sessao.refresh(candidatura)

    return candidatura


# ─────────────────────────────  listagens  ─────────────────────────────


# Uma linha de candidatura: ela e o total de candidaturas DA VAGA dela.
LinhaDeCandidatura = tuple[Candidatura, int]


def _consulta() -> Select:
    """Candidatura + o total de candidaturas da vaga, numa consulta só.

    O total entra aqui, e não sai zero na montagem: um número que a resposta declara e
    não é verdade é pior que um número ausente — e o campo é obrigatório no contrato.
    Como subconsulta correlacionada, ele custa uma linha de SQL e nenhuma ida extra ao
    banco.
    """
    # Um alias é obrigatório: sem ele a subconsulta contaria sobre a MESMA tabela da
    # consulta externa, e a correlação `vaga_id == vaga_id` viraria uma tautologia
    # sobre a própria linha — total 1 em toda candidatura.
    outra = aliased(Candidatura)
    total = (
        select(func.count())
        .select_from(outra)
        .where(outra.vaga_id == Candidatura.vaga_id)
        .scalar_subquery()
    )
    return select(Candidatura, total).order_by(
        Candidatura.criado_em.desc(), Candidatura.id.desc()
    )


async def total_da_vaga(sessao: AsyncSession, vaga_id: UUID) -> int:
    """Quantas candidaturas a vaga tem.

    Existe para os dois caminhos que devolvem UMA candidatura — candidatar-se e marcar
    visualizada — não precisarem da consulta paginada só pelo total. Uma contagem
    direta é mais barata que montar a página de um item.
    """
    return (
        await sessao.execute(
            select(func.count()).select_from(Candidatura).where(Candidatura.vaga_id == vaga_id)
        )
    ).scalar_one()


async def listar_da_vaga(
    sessao: AsyncSession,
    vaga_id: UUID,
    usuario: UsuarioAutenticado,
    limite: int,
    cursor: str | None,
) -> tuple[list[LinhaDeCandidatura], str | None]:
    """As candidaturas recebidas. Só a empresa autora da vaga.

    O portão é `vagas.obter_da_empresa`, que responde 404 para qualquer outra conta —
    e não 403, que confirmaria que a vaga existe e tem candidatos.

    **Listar não marca como visualizada.** A transição é um `PATCH` explícito: um
    `GET` que muda estado é disparado pelo pre-fetch de qualquer cliente sem ninguém
    ter aberto nada.
    """
    await vagas.obter_da_empresa(sessao, vaga_id, usuario)
    return await _paginar(sessao, _consulta().where(Candidatura.vaga_id == vaga_id), limite, cursor)


async def listar_do_candidato(
    sessao: AsyncSession,
    usuario: UsuarioAutenticado,
    limite: int,
    cursor: str | None,
) -> tuple[list[LinhaDeCandidatura], str | None]:
    """As candidaturas do aluno autenticado. Sempre as dele — o id vem do token."""
    return await _paginar(
        sessao, _consulta().where(Candidatura.candidato_id == usuario.id), limite, cursor
    )


async def _paginar(
    sessao: AsyncSession,
    consulta: Select,
    limite: int,
    cursor: str | None,
) -> tuple[list[LinhaDeCandidatura], str | None]:
    limite = paginacao.limite_valido(limite)

    if cursor:
        data, id_ = paginacao.decodificar(cursor)
        consulta = consulta.where(tuple_(Candidatura.criado_em, Candidatura.id) < tuple_(data, id_))

    # `unique()` é obrigatório: `Candidatura.vaga` é `lazy="joined"`, e o SQLAlchemy
    # exige a deduplicação explícita quando a consulta traz um JOIN de coleção.
    encontradas = [
        (linha[0], linha[1])
        for linha in (await sessao.execute(consulta.limit(limite + 1))).unique().all()
    ]

    tem_mais = len(encontradas) > limite
    pagina = encontradas[:limite]
    proximo = None
    if tem_mais and pagina:
        proximo = paginacao.codificar(pagina[-1][0].criado_em, pagina[-1][0].id)

    return pagina, proximo
