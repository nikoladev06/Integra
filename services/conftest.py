"""Infraestrutura de teste compartilhada.

**Os testes rodam contra um Postgres de verdade**, não SQLite. O projeto usa
schemas, `pg_trgm`, `ON CONFLICT` e o tipo UUID nativo — nada disso existe no
SQLite, e um teste que passa contra outro banco testa outra coisa.

O banco vem de `INTEGRA_TEST_DATABASE_URL`, ou do Postgres local do compose.
Sem banco alcançável os testes de integração são pulados com uma mensagem
explícita, em vez de falharem parecendo bug de código.
"""

import os
from collections.abc import AsyncIterator

import pytest
import pytest_asyncio
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

DSN_PADRAO = "postgresql+asyncpg://integra:integra@127.0.0.1:55432/integra"
DSN = os.environ.get("INTEGRA_TEST_DATABASE_URL", DSN_PADRAO)


@pytest_asyncio.fixture
async def sessao() -> AsyncIterator[AsyncSession]:
    """Sessão dentro de uma transação desfeita ao fim do teste.

    O engine é criado POR TESTE, não uma vez por sessão. Um engine async guarda
    um pool preso ao event loop em que nasceu, e o pytest-asyncio abre um loop
    novo a cada teste — reaproveitá-lo rende
    `InternalClientError: got result for unknown protocol state`, um erro do
    driver que não diz nada sobre a causa. Criar por teste custa milissegundos e
    elimina a classe inteira de problema.

    A transação é desfeita ao final, então cada teste vê o banco como o
    encontrou. `TRUNCATE` seria mais lento e apagaria o seed, que os testes usam
    como dado de partida.
    """
    motor = create_async_engine(DSN)
    try:
        try:
            async with motor.connect() as conexao:
                await conexao.execute(text("SELECT 1"))
        except Exception as erro:
            pytest.skip(
                f"Postgres indisponível em {DSN.split('@')[-1]}: {type(erro).__name__}. "
                "Suba com: cd infra && docker compose up -d postgres"
            )

        async with motor.connect() as conexao:
            transacao = await conexao.begin()
            fabrica = async_sessionmaker(bind=conexao, expire_on_commit=False)

            async with fabrica() as s:
                yield s

            await transacao.rollback()
    finally:
        await motor.dispose()
