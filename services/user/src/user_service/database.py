"""Engine e fábrica de sessão do user-service.

Singleton preguiçoso: o engine é criado na importação do módulo, mas nenhuma
conexão abre até a primeira consulta.
"""

from integra_shared.db import criar_engine, criar_fabrica_de_sessao
from user_service.settings import settings

if settings.database_url is None:
    raise RuntimeError(
        "INTEGRA_DATABASE_URL é obrigatória a partir da Sprint 3 — o user-service "
        "não tem mais o que responder sem banco."
    )

engine = criar_engine(settings.database_url)
fabrica_de_sessao = criar_fabrica_de_sessao(engine)
