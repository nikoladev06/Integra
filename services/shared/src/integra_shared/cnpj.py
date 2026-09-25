"""Normalização e validação de CNPJ.

O análogo institucional do CPF, e pelos mesmos motivos: dois serviços precisam da
mesma regra — o auth-service valida no cadastro da instituição, e o user-service
usa o CNPJ para decidir qual universidade a conta reivindica.

O que esta validação faz e o que **não** faz: confere os dígitos verificadores, o
que recusa número digitado errado. Ela **não** prova que quem digitou representa
aquela empresa — CNPJ é dado público, está no cadastro aberto da Receita. É por
isso que a conta institucional nasce pendente: o número identifica a organização,
não a pessoa que a está cadastrando.
"""

import re

COMPRIMENTO = 14

_NAO_DIGITO = re.compile(r"\D")

# Pesos do primeiro dígito verificador. O segundo usa a mesma sequência com um 6
# à frente, porque tem um algarismo a mais para ponderar.
_PESOS_1 = (5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2)
_PESOS_2 = (6, *_PESOS_1)


class CnpjInvalido(ValueError):
    """CNPJ que não passa na validação estrutural."""


def normalizar(cnpj: str) -> str:
    """Devolve apenas os dígitos. Não valida."""
    return _NAO_DIGITO.sub("", cnpj or "")


def e_valido(cnpj: str) -> bool:
    try:
        validar(cnpj)
    except CnpjInvalido:
        return False
    return True


def validar(cnpj: str) -> str:
    """Normaliza e valida, devolvendo os 14 dígitos."""
    digitos = normalizar(cnpj)

    if len(digitos) != COMPRIMENTO:
        raise CnpjInvalido("CNPJ inválido")

    # Sequências de um só dígito passam na conta dos verificadores por
    # coincidência aritmética, e são a entrada de teste que todo mundo digita.
    if digitos == digitos[0] * COMPRIMENTO:
        raise CnpjInvalido("CNPJ inválido")

    if _digito_verificador(digitos[:12], _PESOS_1) != int(digitos[12]):
        raise CnpjInvalido("CNPJ inválido")
    if _digito_verificador(digitos[:13], _PESOS_2) != int(digitos[13]):
        raise CnpjInvalido("CNPJ inválido")

    return digitos


def _digito_verificador(digitos: str, pesos: tuple[int, ...]) -> int:
    """Soma ponderada módulo 11. Resto menor que 2 resulta em dígito 0."""
    soma = sum(int(d) * p for d, p in zip(digitos, pesos, strict=True))
    resto = soma % 11
    return 0 if resto < 2 else 11 - resto


def formatar(cnpj: str) -> str:
    """`12345678000199` → `12.345.678/0001-99`. Exibição, nunca armazenamento."""
    d = normalizar(cnpj)
    if len(d) != COMPRIMENTO:
        return cnpj
    return f"{d[:2]}.{d[2:5]}.{d[5:8]}/{d[8:12]}-{d[12:]}"


def gerar_valido(semente: int) -> str:
    """CNPJ estruturalmente válido e determinístico, **para testes e seed**.

    O mesmo `semente` dá sempre o mesmo CNPJ, então um teste que falha pode ser
    reproduzido. Os 4 dígitos de filial ficam em `0001`, como a matriz.
    """
    base = f"{semente % 100_000_000:08d}0001"
    if base == base[0] * 12:
        # Quebra a sequência trocando um dígito, em vez de pular a semente:
        # pular pode cair noutra sequência repetida. Foi um teste de propriedade
        # que achou esse caso no equivalente do CPF.
        base = base[:11] + ("1" if base[0] != "1" else "2")

    d1 = _digito_verificador(base, _PESOS_1)
    d2 = _digito_verificador(base + str(d1), _PESOS_2)
    return f"{base}{d1}{d2}"
