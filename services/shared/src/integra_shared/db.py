"""Acesso ao PostgreSQL.

Na Sprint 1 existe só a conexão e o ping — não há modelo nem migração ainda.
O ping é o que dá sentido ao `/health`: sem ele o endpoint responderia 200 com o
banco fora, e o gate da sprint ("/health respondendo pela VM") não provaria nada
além de o processo estar vivo.

Um serviço por schema, conforme o escopo. A separação começa lógica — todos os
schemas na mesma instância Postgres — e só vira física se o custo justificar.
"""

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine


def criar_engine(dsn: str) -> AsyncEngine:
    return create_async_engine(
        dsn,
        # pool_pre_ping descarta conexões mortas antes de usá-las. Sem isso, a
        # primeira requisição depois de o Postgres reiniciar falha sempre.
        pool_pre_ping=True,
        pool_size=5,
        max_overflow=5,
    )


async def ping(engine: AsyncEngine) -> bool:
    async with engine.connect() as conexao:
        await conexao.execute(text("SELECT 1"))
    return True
