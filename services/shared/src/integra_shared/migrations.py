"""Plumbing de Alembic compartilhado entre os serviços.

Cada serviço tem as próprias migrações — um schema, um histórico — mas o `env.py`
seria idêntico nos cinco. Ele mora aqui para que corrigir um detalhe de
configuração aconteça uma vez, e não cinco.
"""

import asyncio
from collections.abc import Sequence

from alembic import context
from sqlalchemy import MetaData, pool, text
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config


def executar_migracoes(metadata: MetaData, schema: str, dsn: str) -> None:
    """Roda as migrações do serviço, online ou offline.

    A reflexão fica presa ao schema do serviço (ver `_so_o_nosso_schema`), e a
    tabela de versão também: cada serviço tem o próprio histórico de migrações,
    e um nunca enxerga nem altera as tabelas do outro.
    """
    configuracao = context.config
    configuracao.set_main_option("sqlalchemy.url", dsn)

    def _so_o_nosso_schema(nome: str | None, tipo: str, pais: list) -> bool:
        """Filtra a reflexão ao schema deste serviço.

        `include_schemas=True` é necessário para o Alembic enxergar tabelas fora
        de `public` — sem ele, `autogenerate` acha o banco vazio e propõe criar
        tudo de novo, mesmo com as tabelas lá. Mas ligado sozinho ele passa a ver
        os schemas dos OUTROS serviços na mesma instância e tenta apagá-los como
        "não declarados nos modelos". O filtro resolve os dois: vê o próprio
        schema, ignora o resto.
        """
        if tipo == "schema":
            return nome == schema
        return True

    def _configurar(conexao: Connection | None = None) -> dict:
        return {
            "target_metadata": metadata,
            "version_table_schema": schema,
            "include_schemas": True,
            "include_name": _so_o_nosso_schema,
            "compare_type": True,
            "compare_server_default": True,
        }

    if context.is_offline_mode():
        context.configure(url=dsn, literal_binds=True, **_configurar())
        with context.begin_transaction():
            context.run_migrations()
        return

    asyncio.run(_online(configuracao, schema, _configurar))


async def _online(configuracao, schema: str, configurar) -> None:
    engine = async_engine_from_config(
        configuracao.get_section(configuracao.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with engine.connect() as conexao:
        await conexao.run_sync(_migrar, schema, configurar)
        await conexao.commit()

    await engine.dispose()


def _migrar(conexao: Connection, schema: str, configurar) -> None:
    # O schema precisa existir antes de o Alembic gravar a tabela de versão
    # nele. Em desenvolvimento o script de init do Postgres já cria; numa base
    # nova, sem aquele script, isto é o que evita falhar na primeira migração.
    conexao.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{schema}"'))
    context.configure(connection=conexao, **configurar(conexao))
    with context.begin_transaction():
        context.run_migrations()


def versoes(*caminhos: str) -> Sequence[str]:
    return caminhos
