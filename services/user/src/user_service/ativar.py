"""Ativa uma conta institucional pendente.

Contas de faculdade e empresa se cadastram sozinhas pelo app — não há operador no
caminho do cadastro. Mas nascem **pendentes**: entram, editam o perfil, e não
publicam nem matriculam até passarem por aqui.

    uv run --project .. python -m user_service.ativar sec@fatec.br

O motivo é o selo de verificado. CNPJ é dado público, está no cadastro aberto da
Receita, então qualquer um consulta o de uma faculdade e se cadastra como ela. Sem
este passo, bastaria isso para distribuir formações "verificadas" no nome dela — e
o selo, que é a peça central do modelo, deixaria de significar algo.

Não é rota HTTP de propósito: ativar concede o poder de publicar como a
instituição e de vincular alunos. Exigir acesso ao servidor é uma barreira que
nenhuma falha de autorização contorna.

**Limitação conhecida:** ainda é manual, e não escala além de um punhado de
instituições. O caminho previsto é o modelo tipo Meta Business — a organização
cadastrada uma vez, com várias pessoas autorizadas a operá-la — e o schema já
está preparado: `Universidade.conta_id` vira uma tabela de associação com papéis,
sem remodelar nada.
"""

import asyncio
import sys

from integra_shared.errors import AppError
from user_service.database import engine, fabrica_de_sessao
from user_service.services import instituicoes


async def _principal() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2

    email = sys.argv[1]
    async with fabrica_de_sessao() as sessao:
        try:
            conta = await instituicoes.ativar(sessao, email)
        except AppError as erro:
            print(f"erro: {erro.message}")
            await engine.dispose()
            return 1
        await sessao.commit()
        print(
            f"ok: {conta.email} ({conta.tipo.value}) ativada em {conta.ativada_em:%d/%m/%Y %H:%M}"
        )

    await engine.dispose()
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(_principal()))
