"""Busca unificada do cabeçalho.

Uma consulta, resultados **agrupados por tipo** — quem digita "fatec" não deveria
escolher aba antes de saber se achou.

Os grupos vêm em consultas separadas de propósito, em vez de um `UNION`:
universidades e usuários são tabelas diferentes, com colunas diferentes, e forçar
um formato comum no SQL só para juntar tornaria a consulta ilegível e impediria
cada lado de usar o índice que lhe serve.
"""

from sqlalchemy.ext.asyncio import AsyncSession

from user_service.models import TipoConta, Universidade, Usuario
from user_service.services import perfis

TIPOS_VALIDOS = frozenset({"universidades", "empresas", "pessoas"})


async def buscar(
    sessao: AsyncSession,
    termo: str,
    *,
    tipos: frozenset[str] | None = None,
    limite_por_tipo: int = 5,
) -> dict[str, list[Universidade] | list[Usuario]]:
    """Devolve sempre as três chaves, ainda que vazias.

    Omitir um grupo faria o cliente ter que distinguir "não achei" de "não pedi
    este tipo", e a ausência de chave é ambígua para as duas coisas.
    """
    pedidos = tipos or TIPOS_VALIDOS
    resultado: dict[str, list] = {"universidades": [], "empresas": [], "pessoas": []}

    if len(termo.strip()) < perfis.TERMO_MINIMO_DE_BUSCA:
        return resultado

    if "universidades" in pedidos:
        resultado["universidades"] = await perfis.listar_universidades(
            sessao, termo, limite=limite_por_tipo
        )

    if "empresas" in pedidos:
        resultado["empresas"] = await perfis.buscar_pessoas(
            sessao, termo, tipos=(TipoConta.EMPRESA,), limite=limite_por_tipo
        )

    if "pessoas" in pedidos:
        # `faculdade` não entra aqui: a conta institucional aparece no grupo de
        # universidades, e listá-la também em "Pessoas" mostraria a mesma
        # instituição duas vezes com nomes diferentes.
        resultado["pessoas"] = await perfis.buscar_pessoas(
            sessao, termo, tipos=(TipoConta.ALUNO,), limite=limite_por_tipo
        )

    return resultado
