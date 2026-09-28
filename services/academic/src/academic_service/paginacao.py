"""Cursor de paginação: opaco para o cliente, keyset para o banco.

`OFFSET` não serve num feed. Entre a primeira e a segunda página alguém publica,
todo mundo anda uma posição, e o item que estava na borda aparece duas vezes —
enquanto outro nunca aparece. O bug é intermitente e depende de quem publicou no
meio, que é o pior tipo de bug de listagem.

O keyset compara contra a **última linha lida** (`criado_em`, `id`), então uma
publicação nova não mexe no que já foi paginado. O `id` entra como desempate
porque duas publicações no mesmo instante são possíveis — e sem desempate a
comparação pularia uma delas.

O cursor sai em base64url para ser **opaco de fato**: um cursor legível convida a
ser construído à mão, e aí a forma interna vira parte do contrato. Não é
criptografia e não protege nada — o que ele carrega é a data e o id de um post que
o leitor acabou de receber.
"""

from base64 import urlsafe_b64decode, urlsafe_b64encode
from datetime import datetime
from uuid import UUID

from integra_shared.errors import AppError

LIMITE_MAXIMO = 50
LIMITE_PADRAO = 20


def codificar(criado_em: datetime, id_: UUID) -> str:
    bruto = f"{criado_em.isoformat()}|{id_}".encode()
    return urlsafe_b64encode(bruto).decode().rstrip("=")


def decodificar(cursor: str) -> tuple[datetime, UUID]:
    """Devolve (data, id) ou levanta 422.

    Cursor inválido é erro do cliente, não 500: acontece quando alguém edita a
    query string à mão, e a resposta útil é dizer qual campo está errado.
    """
    try:
        # O padding foi removido na codificação para o cursor não carregar `=`
        # em query string; aqui ele volta, porque o decodificador exige múltiplo de 4.
        preenchido = cursor + "=" * (-len(cursor) % 4)
        texto = urlsafe_b64decode(preenchido.encode()).decode()
        data, id_ = texto.split("|", 1)
        return datetime.fromisoformat(data), UUID(id_)
    except (ValueError, UnicodeDecodeError) as erro:
        raise AppError(
            code="validation_error",
            message="Verifique os campos destacados",
            status_code=422,
            fields={"cursor": ["Cursor inválido. Recarregue a lista."]},
        ) from erro


def limite_valido(limit: int) -> int:
    """Grampeia o limite pedido.

    O FastAPI já valida a faixa pelo `Query(le=...)`; isto é a segunda linha, para
    as chamadas internas (testes, e as rotas que compõem listas) não conseguirem
    pedir dez mil posts por engano.
    """
    return max(1, min(limit, LIMITE_MAXIMO))
