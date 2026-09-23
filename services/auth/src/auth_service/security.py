"""Hash de senha e geração de refresh token.

**Argon2id**, não bcrypt. O bcrypt trunca silenciosamente em 72 bytes, o que
obriga a limitar o comprimento da senha antes de hashear e a lembrar disso em
todo lugar que hasheia. O Argon2 não tem esse limite, então o problema deixa de
existir em vez de ser contornado.
"""

import hashlib
import secrets

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerifyMismatchError

# Parâmetros padrão da biblioteca, que seguem as recomendações atuais do OWASP.
# Eles ficam gravados dentro de cada hash, então aumentá-los depois não invalida
# as senhas já cadastradas.
_hasher = PasswordHasher()


def hashear_senha(senha: str) -> str:
    return _hasher.hash(senha)


def conferir_senha(senha: str, hash_guardado: str) -> bool:
    try:
        _hasher.verify(hash_guardado, senha)
    except (VerifyMismatchError, InvalidHashError):
        return False
    return True


def precisa_rehash(hash_guardado: str) -> bool:
    """`True` quando o hash foi gerado com custo menor que o atual.

    Permite atualizar o custo de forma incremental: quem entra tem a senha
    re-hasheada com os parâmetros novos, sem migração em massa nem reset.
    """
    try:
        return _hasher.check_needs_rehash(hash_guardado)
    except InvalidHashError:
        return False


def gerar_refresh_token() -> str:
    """Token opaco de 256 bits. Não é JWT: só o auth-service precisa lê-lo."""
    return secrets.token_urlsafe(32)


def hash_do_refresh(token: str) -> str:
    """SHA-256 do token, que é o que vai para o banco.

    Diferente da senha, aqui não cabe Argon2: o token já é aleatório de 256 bits,
    então não há o que proteger contra força bruta, e a verificação acontece a
    cada renovação — um hash caro viraria custo por requisição sem ganho.
    """
    return hashlib.sha256(token.encode()).hexdigest()
