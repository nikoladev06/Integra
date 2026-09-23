"""Tabelas do auth-service, no schema `auth`.

Este serviço guarda **apenas credenciais e sessões**. Nome, username, afiliação
e tudo mais é do user-service. A separação é o que permite derrubar o auth sem
derrubar a leitura de perfil.
"""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Index, String, func
from sqlalchemy.dialects.postgresql import UUID as PgUUID
from sqlalchemy.orm import Mapped, mapped_column

from integra_shared.db import criar_base

Base = criar_base("auth")


def _agora() -> datetime:
    return datetime.now(UTC)


class Credencial(Base):
    __tablename__ = "credenciais"

    # O mesmo id do usuário no user-service. Gerado aqui, no cadastro, e enviado
    # junto na criação do perfil — assim os dois lados falam do mesmo usuário
    # sem precisar de uma tabela de correspondência.
    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)

    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)

    # Hash Argon2id, nunca a senha. O algoritmo, o sal e os parâmetros de custo
    # viajam dentro da própria string, então trocar o custo no futuro não invalida
    # os hashes antigos — cada um carrega o seu.
    senha_hash: Mapped[str] = mapped_column(String(200))

    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    senha_alterada_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class RefreshToken(Base):
    """Sessão de longa duração, rotacionada a cada uso.

    Guardamos o **hash** do token, não ele: um vazamento do banco não entrega
    sessões utilizáveis. Pelo mesmo motivo o login guarda hash de senha.
    """

    __tablename__ = "refresh_tokens"
    __table_args__ = (
        Index("ix_refresh_tokens_familia", "familia_id"),
        Index("ix_refresh_tokens_credencial", "credencial_id"),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)
    credencial_id: Mapped[UUID] = mapped_column(ForeignKey("credenciais.id", ondelete="CASCADE"))

    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)

    # Todos os tokens descendentes de um mesmo login compartilham a família.
    # Reapresentar um token já usado revoga a família inteira: é o sinal de que
    # o token vazou, e manter a sessão viva depois disso seria manter o atacante.
    familia_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), default=uuid4)

    expira_em: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    usado_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    revogado_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_agora, server_default=func.now()
    )

    @property
    def utilizavel(self) -> bool:
        return (
            self.revogado_em is None
            and self.usado_em is None
            and self.expira_em > datetime.now(UTC)
        )
