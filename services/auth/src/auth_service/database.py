"""Engine e fábrica de sessão do auth-service."""

from auth_service.settings import settings
from integra_shared.db import criar_engine, criar_fabrica_de_sessao

if settings.database_url is None:
    raise RuntimeError(
        "INTEGRA_DATABASE_URL é obrigatória a partir da Sprint 3 — o auth-service "
        "não tem onde guardar credencial sem banco."
    )

engine = criar_engine(settings.database_url)
fabrica_de_sessao = criar_fabrica_de_sessao(engine)
