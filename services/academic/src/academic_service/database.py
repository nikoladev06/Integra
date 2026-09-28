"""Engine e fábrica de sessão do academic-service.

Singleton preguiçoso: o engine nasce na importação do módulo, mas nenhuma conexão
abre até a primeira consulta.
"""

from academic_service.settings import settings
from integra_shared.db import criar_engine, criar_fabrica_de_sessao

if settings.database_url is None:
    raise RuntimeError(
        "INTEGRA_DATABASE_URL é obrigatória: o academic-service guarda posts, "
        "curtidas e comentários, e não tem o que responder sem banco."
    )

engine = criar_engine(settings.database_url)
fabrica_de_sessao = criar_fabrica_de_sessao(engine)
