"""Tabelas do user-service, no schema `user`.

A correção estrutural que justifica este serviço: no protótipo `universidade` e
`curso` eram texto livre no `UserModel`, o que torna impossível responder "quais
alunos são desta faculdade" ou "restrito a este curso" — as duas perguntas
centrais do pilar Acadêmico. Aqui são entidades com chave estrangeira.
"""

from datetime import UTC, datetime
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

Base = criar_base("user")


class TipoConta(StrEnum):
    ALUNO = "aluno"
    FACULDADE = "faculdade"
    EMPRESA = "empresa"


def _agora() -> datetime:
    return datetime.now(UTC)


class Universidade(Base):
    __tablename__ = "universidades"

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)
    nome: Mapped[str] = mapped_column(String(200), unique=True)
    sigla: Mapped[str] = mapped_column(String(20), index=True)
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    cursos: Mapped[list["Curso"]] = relationship(back_populates="universidade")


class Curso(Base):
    __tablename__ = "cursos"
    # O mesmo nome de curso existe em várias universidades; a unicidade é do par.
    __table_args__ = (UniqueConstraint("universidade_id", "nome"),)

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)
    universidade_id: Mapped[UUID] = mapped_column(
        ForeignKey("universidades.id", ondelete="CASCADE"), index=True
    )
    nome: Mapped[str] = mapped_column(String(200))
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    universidade: Mapped[Universidade] = relationship(back_populates="cursos")


class Usuario(Base):
    __tablename__ = "usuarios"
    __table_args__ = (
        # A afiliação fica embutida em vez de numa tabela `afiliacoes`: hoje um
        # usuário tem exatamente um vínculo e não há requisito de histórico.
        # Uma tabela separada só se paga quando houver transferência a rastrear.
        CheckConstraint(
            "(universidade_id IS NULL) = (curso_id IS NULL)",
            name="afiliacao_completa_ou_ausente",
        ),
        # Índices GIN trigram, não btree: a busca é `ILIKE '%termo%'`, com
        # curinga dos DOIS lados, e um btree comum não serve para isso — o
        # planejador o ignora e cai em varredura completa da tabela.
        # Dependem da extensão pg_trgm, criada em infra/postgres/init/.
        Index(
            "ix_usuarios_trgm_username",
            "username",
            postgresql_using="gin",
            postgresql_ops={"username": "gin_trgm_ops"},
        ),
        Index(
            "ix_usuarios_trgm_nome",
            "nome_completo",
            postgresql_using="gin",
            postgresql_ops={"nome_completo": "gin_trgm_ops"},
        ),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True)

    nome_completo: Mapped[str] = mapped_column(String(200))
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)

    # Cópia do e-mail que o auth-service guarda como credencial.
    #
    # Denormalizar entre serviços normalmente envelhece — foi o erro do protótipo
    # ao copiar `nomeCompleto` dentro de cada post. Aqui é seguro por um motivo
    # específico: **o contrato não permite trocar de e-mail**, nem aqui nem lá.
    # Se essa funcionalidade entrar um dia, os dois lados passam a ter que
    # atualizar juntos, e esta linha vira o ponto de falha.
    email: Mapped[str] = mapped_column(String(320), unique=True)
    telefone: Mapped[str | None] = mapped_column(String(20))

    tipo: Mapped[TipoConta] = mapped_column(
        Enum(
            TipoConta,
            name="tipo_conta",
            schema="user",
            values_callable=lambda e: [i.value for i in e],
        ),
        default=TipoConta.ALUNO,
    )

    universidade_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("universidades.id", ondelete="RESTRICT"), index=True
    )
    curso_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("cursos.id", ondelete="RESTRICT"), index=True
    )

    foto_url: Mapped[str | None] = mapped_column(String(500))
    bio: Mapped[str | None] = mapped_column(String(280))

    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    alterado_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    universidade: Mapped[Universidade | None] = relationship(lazy="joined")
    curso: Mapped[Curso | None] = relationship(lazy="joined")


class SeguindoUniversidade(Base):
    """Universidades que o usuário acompanha além da própria.

    **Seguir não concede acesso a conteúdo restrito.** Quem segue sem ter
    vínculo vê apenas os posts de visibilidade `publico`; os `institucional` e
    `curso` continuam exigindo afiliação. Essa assimetria é o que impede seguir
    de virar um botão de escalar privilégio, e quem a aplica é o
    academic-service na consulta — esta tabela só registra a intenção.
    """

    __tablename__ = "seguindo_universidades"

    usuario_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True
    )
    universidade_id: Mapped[UUID] = mapped_column(
        ForeignKey("universidades.id", ondelete="CASCADE"), primary_key=True
    )
    seguida_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_agora, server_default=func.now()
    )


class SeguindoUsuario(Base):
    """Pessoas e empresas que o usuário segue, para o feed profissional."""

    __tablename__ = "seguindo_usuarios"
    __table_args__ = (CheckConstraint("seguidor_id <> seguido_id", name="nao_seguir_a_si_mesmo"),)

    seguidor_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True
    )
    seguido_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True, index=True
    )
    seguido_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_agora, server_default=func.now()
    )
