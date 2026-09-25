"""Normalização e validação de CPF.

Mora no pacote compartilhado porque **dois serviços precisam da mesma regra**: o
auth-service valida no cadastro e o user-service valida no cadastro de matrícula
pela faculdade. Duas implementações divergiriam, e a divergência apareceria como
uma matrícula que nunca casa com conta nenhuma — sem erro em lugar algum.

O que esta validação faz e o que **não** faz: ela confere os dígitos
verificadores, o que recusa número digitado errado. Ela **não** verifica
identidade, não consulta a Receita e não diz que a pessoa existe. Um CPF
matematicamente válido pode não pertencer a ninguém.
"""

import re

COMPRIMENTO = 11

_NAO_DIGITO = re.compile(r"\D")


class CpfInvalido(ValueError):
    """CPF que não passa na validação estrutural."""


def normalizar(cpf: str) -> str:
    """Devolve apenas os dígitos. Não valida."""
    return _NAO_DIGITO.sub("", cpf or "")


def e_valido(cpf: str) -> bool:
    try:
        validar(cpf)
    except CpfInvalido:
        return False
    return True


def validar(cpf: str) -> str:
    """Normaliza e valida, devolvendo os 11 dígitos.

    Levanta [CpfInvalido] com a mensagem que o cliente exibe — a mesma string em
    todos os casos, porque para quem digitou a ação é sempre "confira o número".
    """
    digitos = normalizar(cpf)

    if len(digitos) != COMPRIMENTO:
        raise CpfInvalido("CPF inválido")

    # Sequências de um só dígito (00000000000, 11111111111, ...) passam na conta
    # dos verificadores por coincidência aritmética, e são a entrada de teste que
    # todo mundo digita. Recusar explicitamente é o único jeito.
    if digitos == digitos[0] * COMPRIMENTO:
        raise CpfInvalido("CPF inválido")

    if _digito_verificador(digitos, ate=9) != int(digitos[9]):
        raise CpfInvalido("CPF inválido")
    if _digito_verificador(digitos, ate=10) != int(digitos[10]):
        raise CpfInvalido("CPF inválido")

    return digitos


def _digito_verificador(digitos: str, *, ate: int) -> int:
    """Calcula o dígito verificador dos primeiros `ate` algarismos.

    Soma ponderada com pesos decrescentes a partir de `ate + 1`, módulo 11. Resto
    0 ou 1 resulta em dígito 0 — daí o `% 10` no fim, em vez de um `if`.
    """
    peso_inicial = ate + 1
    soma = sum(int(digitos[i]) * (peso_inicial - i) for i in range(ate))
    return (soma * 10) % 11 % 10


def formatar(cpf: str) -> str:
    """`12345678900` → `123.456.789-00`. Para exibição, nunca para armazenamento."""
    d = normalizar(cpf)
    if len(d) != COMPRIMENTO:
        return cpf
    return f"{d[:3]}.{d[3:6]}.{d[6:9]}-{d[9:]}"


def gerar_valido(semente: int) -> str:
    """CPF estruturalmente válido e determinístico, **para testes e seed**.

    Não é aleatório de propósito: o mesmo `semente` dá sempre o mesmo CPF, então
    um teste que falha pode ser reproduzido. Não usar em produção — não existe
    razão legítima para o sistema inventar um CPF.
    """
    base = f"{semente % 1_000_000_000:09d}"
    if base == base[0] * 9:
        # Quebra a sequência trocando o último dígito, em vez de pular a semente.
        # Pular pode cair noutra sequência repetida: 999999999 + 1, módulo 1e9,
        # dá 000000000. Foi um teste de propriedade que achou esse caso — nenhum
        # exemplo escolhido à mão passaria por ele.
        base = base[:8] + ("1" if base[0] != "1" else "2")

    d1 = _digito_verificador(base + "00", ate=9)
    d2 = _digito_verificador(base + str(d1) + "0", ate=10)
    return f"{base}{d1}{d2}"
