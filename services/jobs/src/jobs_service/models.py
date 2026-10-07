"""Tabelas do jobs-service, no schema `jobs`.

## Duas tabelas, e por que vaga não é post

    Vaga         o anúncio, com ESTADO (aberta/fechada)
    Candidatura  (vaga, candidato) — com estado próprio e id próprio

A diferença em relação a um post é o que justifica o serviço separado: uma vaga tem
estado e uma relação N:N com alunos. O protótipo chamava tudo de `ProfessionalPost`,
e o resultado era uma lista em que "candidatar-se" e "curtir" eram a mesma ação com
nomes diferentes.

## Encerrar é estado, e não remoção

Não há `DELETE` de vaga. Encerrar é `estado = fechada`, e as candidaturas recebidas
continuam existindo: o aluno continua vendo a vaga a que se candidatou, e a empresa
continua vendo quem se candidatou. Um `DELETE` que levasse as candidaturas junto
apagaria o histórico dos dois lados para encerrar um processo que terminou normal.

A consequência é que `fechada` sai da listagem padrão mas continua legível por id.
Esconder também no detalhe faria "minhas candidaturas" apontar para 404.

## Por que não há chave estrangeira para `usuarios`

`empresa_id` e `candidato_id` vivem no schema `user`, de outro serviço. Mesma
decisão dos outros dois serviços, e pelo mesmo motivo: a FK funcionaria no Postgres
de hoje, e é por isso que é a armadilha.
"""

from datetime import datetime
from enum import StrEnum
from uuid import UUID, uuid4

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID as PgUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from integra_shared.db import criar_base

Base = criar_base("jobs")

LIMITE_DO_TITULO = 120
LIMITE_DA_DESCRICAO = 5000
LIMITE_DO_LOCAL = 120


class TipoDeVaga(StrEnum):
    """O recorte do Integra: quem está na faculdade ou acabou de sair.

    Não há `pleno` nem `senior`, e a ausência é decisão de produto: seriam vagas para
    quem o app não atende, e a primeira delas na lista já muda o que o produto
    parece ser.
    """

    ESTAGIO = "estagio"
    JUNIOR = "junior"
    TRAINEE = "trainee"


class Modalidade(StrEnum):
    PRESENCIAL = "presencial"
    HIBRIDO = "hibrido"
    REMOTO = "remoto"


class EstadoDaVaga(StrEnum):
    ABERTA = "aberta"
    FECHADA = "fechada"


class EstadoDaCandidatura(StrEnum):
    """Dois estados, e o segundo é o que fecha o portão da Sprint 5.

    "A empresa vê a candidatura" precisa de algo que mude, senão a tela do aluno não
    tem o que dizer. Não há `aceita` nem `recusada`: sem mensagens diretas, que não
    têm serviço, "aceita" é um estado que não leva a lugar nenhum — o aluno ficaria
    esperando um contato que o app não sabe entregar.
    """

    ENVIADA = "enviada"
    VISUALIZADA = "visualizada"


def _enum(tipo: type[StrEnum], nome: str) -> Enum:
    return Enum(
        tipo,
        name=nome,
        schema="jobs",
        values_callable=lambda e: [i.value for i in e],
    )


class Vaga(Base):
    """Uma vaga publicada por uma conta `empresa` ativada."""

    __tablename__ = "vagas"
    __table_args__ = (
        # A invariante do local, no banco e não só no schema Pydantic: uma vaga
        # presencial ou híbrida sem lugar não é uma vaga, é um anúncio incompleto.
        #
        # Nos dois sentidos, como o `curso_id` do academic-service: um `local`
        # sobrando numa vaga remota pareceria uma restrição geográfica que não
        # existe, e o candidato descartaria a vaga por causa dela.
        CheckConstraint(
            "(modalidade = 'remoto') = (local IS NULL)",
            name="local_exatamente_quando_nao_e_remoto",
        ),
        # O índice da listagem: filtra por estado (quase sempre `aberta`) e ordena
        # por data decrescente.
        Index("ix_vagas_estado_criado_em", "estado", "criado_em"),
        # O da aba de vagas do perfil de uma empresa.
        Index("ix_vagas_empresa_criado_em", "empresa_id", "criado_em"),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)

    # A conta `empresa` autora. **Não vem do corpo da requisição**: é a conta
    # autenticada. Aceitá-la do cliente deixaria uma empresa publicar no nome de
    # outra — a mesma disciplina do `universidade_id` do academic-service.
    empresa_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True))

    titulo: Mapped[str] = mapped_column(String(LIMITE_DO_TITULO))
    descricao: Mapped[str] = mapped_column(String(LIMITE_DA_DESCRICAO))

    tipo: Mapped[TipoDeVaga] = mapped_column(_enum(TipoDeVaga, "tipo_de_vaga"))
    modalidade: Mapped[Modalidade] = mapped_column(_enum(Modalidade, "modalidade"))

    # Cidade e estado, em texto livre. Nulo exatamente quando a modalidade é
    # `remoto` — ver o CheckConstraint acima.
    local: Mapped[str | None] = mapped_column(String(LIMITE_DO_LOCAL))

    estado: Mapped[EstadoDaVaga] = mapped_column(
        _enum(EstadoDaVaga, "estado_da_vaga"), default=EstadoDaVaga.ABERTA
    )

    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    editado_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    candidaturas: Mapped[list["Candidatura"]] = relationship(
        back_populates="vaga", cascade="all, delete-orphan"
    )

    @property
    def aberta(self) -> bool:
        return self.estado == EstadoDaVaga.ABERTA


class Candidatura(Base):
    """Um aluno candidatado a uma vaga. Uma linha por par, garantido pelo banco."""

    __tablename__ = "candidaturas"
    __table_args__ = (
        # A idempotência do `POST`, e ela é estrutural: dois toques rápidos no botão
        # não criam duas linhas nem por condição de corrida. O serviço devolve a
        # existente com 200 em vez de tentar inserir e tratar o erro.
        UniqueConstraint("vaga_id", "candidato_id", name="uq_candidaturas_vaga_candidato"),
        # A lista que a empresa abre, e a lista do aluno. Duas, porque as duas
        # existem como tela e nenhum índice serve às duas.
        Index("ix_candidaturas_vaga_criado_em", "vaga_id", "criado_em"),
        Index("ix_candidaturas_candidato_criado_em", "candidato_id", "criado_em"),
    )

    # Id próprio, e não chave composta: `PATCH /jobs/candidaturas/{id}` precisa
    # endereçá-la sem o cliente montar um par de ids. A unicidade continua sendo do
    # banco, pela `UniqueConstraint` acima.
    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)

    vaga_id: Mapped[UUID] = mapped_column(ForeignKey("vagas.id", ondelete="CASCADE"))
    candidato_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True))

    estado: Mapped[EstadoDaCandidatura] = mapped_column(
        _enum(EstadoDaCandidatura, "estado_da_candidatura"),
        default=EstadoDaCandidatura.ENVIADA,
    )

    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    # A data da PRIMEIRA vez. Marcar de novo não a move: é o que o aluno lê como
    # "foi vista", e uma data que anda a cada abertura da empresa contaria outra
    # coisa — quantas vezes olharam, que não é informação que ele ganhe em ver.
    visualizada_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # `joined` e não lazy: toda resposta de candidatura mostra a vaga como contexto —
    # "onde me candidatei" sem título de vaga não é uma linha legível. Num engine
    # async, o acesso preguiçoso a um relacionamento levanta `MissingGreenlet` em vez
    # de emitir a consulta, então "carregar sob demanda" aqui não é uma opção mais
    # barata: é um erro em tempo de execução.
    vaga: Mapped[Vaga] = relationship(back_populates="candidaturas", lazy="joined")
