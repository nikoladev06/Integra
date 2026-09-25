"""As regras de validação do cadastro, do lado do servidor.

**São as mesmas de `app/lib/features/auth/domain/auth_validators.dart`**, com as
mensagens idênticas. O cliente valida para dar retorno imediato; aqui é a
validação que vale. Duas listas de mensagens divergem na primeira mudança, então
qualquer alteração aqui precisa acontecer lá também — e vice-versa.

Vieram do protótipo, onde estavam presas a `BuildContext` dentro do
`cadastrar_controller.dart`.
"""

import re

from integra_shared.cpf import e_valido as cpf_e_valido

SENHA_COMPRIMENTO_MINIMO = 6

# O protótipo tinha duas expressões diferentes para e-mail: uma permissiva no
# cadastro e esta, estrita, no login. Um e-mail aceito no cadastro e recusado no
# login é um usuário sem acesso, então a estrita vale nos dois.
_FORMATO_EMAIL = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
_FORMATO_USERNAME = re.compile(r"^[a-zA-Z0-9_]+$")
_FORMATO_TELEFONE = re.compile(r"^\(?\d{2}\)?[\s-]?\d{4,5}-?\d{4}$")


def validar_email(email: str | None) -> str | None:
    valor = (email or "").strip()
    if not valor:
        return "E-mail não pode ficar em branco"
    if not _FORMATO_EMAIL.match(valor):
        return "Insira um e-mail válido (ex: usuario@exemplo.com)"
    return None


def validar_senha(senha: str | None) -> str | None:
    valor = senha or ""
    if not valor:
        return "Senha não pode ficar em branco"
    if len(valor) < SENHA_COMPRIMENTO_MINIMO:
        return f"Senha deve ter no mínimo {SENHA_COMPRIMENTO_MINIMO} caracteres"
    return None


def validar_confirmacao(senha: str | None, confirmacao: str | None) -> str | None:
    if senha != confirmacao:
        return "As senhas não correspondem"
    return None


def validar_nome_completo(nome: str | None) -> str | None:
    valor = (nome or "").strip()
    if not valor or len(re.split(r"\s+", valor)) < 2:
        return "Nome completo deve ter pelo menos 2 nomes"
    return None


def validar_username(username: str | None) -> str | None:
    valor = (username or "").strip()
    if len(valor) < 3:
        return "Username deve ter pelo menos 3 caracteres"
    if not _FORMATO_USERNAME.match(valor):
        return "Username pode conter apenas letras, números e underscore"
    return None


def validar_telefone(telefone: str | None) -> str | None:
    valor = (telefone or "").strip()
    if not valor or not _FORMATO_TELEFONE.match(valor):
        return "Telefone inválido. Use o formato (XX)XXXXX-XXXX ou XXXXXXXXXXX"
    return None


def validar_cpf(cpf: str | None) -> str | None:
    """Confere os dígitos verificadores.

    Recusa número digitado errado — **não** verifica identidade nem diz que a
    pessoa existe. Vale porque um CPF impossível cadastrado numa matrícula nunca
    casaria com conta alguma, e o erro apareceria meses depois como "o vínculo
    não funciona", sem pista de onde veio.
    """
    valor = (cpf or "").strip()
    if not valor:
        return "CPF não pode ficar em branco"
    if not cpf_e_valido(valor):
        return "CPF inválido"
    return None


def erros_do_cadastro(
    *,
    nome_completo: str,
    email: str,
    username: str,
    senha: str,
    telefone: str,
    cpf: str,
) -> dict[str, list[str]]:
    """Todos os erros de uma vez, no formato `fields` do contrato.

    Devolver o conjunto completo, e não o primeiro erro, é o que permite ao
    formulário destacar todos os campos numa passada só.
    """
    candidatos = {
        "nomeCompleto": validar_nome_completo(nome_completo),
        "email": validar_email(email),
        "username": validar_username(username),
        "senha": validar_senha(senha),
        "telefone": validar_telefone(telefone),
        "cpf": validar_cpf(cpf),
    }
    return {campo: [erro] for campo, erro in candidatos.items() if erro}
