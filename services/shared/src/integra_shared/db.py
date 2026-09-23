"""Acesso ao PostgreSQL: engine, sessão e a base dos modelos.

Um schema por serviço, conforme o escopo. A separação começa lógica — todos os
schemas na mesma instância Postgres — e só vira física se o custo justificar.
Cada serviço declara o seu em `Base.metadata.schema`, e as migrações de um nunca
enxergam as tabelas do outro.
"""

from collections.abc import AsyncIterator

from sqlalchemy import MetaData, text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

# Nomes previsíveis para índices e constraints. Sem isto, o Alembic gera nomes
# que o Postgres inventa, e uma migração que tenta remover uma constraint criada
# noutra máquina não a encontra.
CONVENCAO_DE_NOMES = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


def criar_base(schema: str) -> type[DeclarativeBase]:
    """Base declarativa presa a um schema."""

    class Base(DeclarativeBase):
        metadata = MetaData(schema=schema, naming_convention=CONVENCAO_DE_NOMES)

    return Base


def criar_engine(dsn: str) -> AsyncEngine:
    return create_async_engine(
        dsn,
        # pool_pre_ping descarta conexões mortas antes de usá-las. Sem isso, a
        # primeira requisição depois de o Postgres reiniciar falha sempre.
        pool_pre_ping=True,
        pool_size=5,
        max_overflow=5,
    )


def criar_fabrica_de_sessao(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(
        engine,
        expire_on_commit=False,
        autoflush=False,
    )


async def ping(engine: AsyncEngine) -> bool:
    async with engine.connect() as conexao:
        await conexao.execute(text("SELECT 1"))
    return True


def criar_dependencia_de_sessao(fabrica: async_sessionmaker[AsyncSession]):
    """Dependência FastAPI que abre uma sessão por requisição.

    A transação fecha aqui, e não em cada rota: commit no fim do caminho feliz,
    rollback em qualquer exceção. Deixar isso a cargo da rota é como metade
    delas acaba esquecendo o rollback e vazando conexão em erro.
    """

    async def _sessao() -> AsyncIterator[AsyncSession]:
        async with fabrica() as sessao:
            try:
                yield sessao
                await sessao.commit()
            except Exception:
                await sessao.rollback()
                raise

    return _sessao
