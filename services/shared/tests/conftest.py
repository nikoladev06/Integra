import os

# Definido antes de qualquer import de integra_shared: Settings valida na
# construção e um segredo ausente derruba a coleta dos testes.
os.environ.setdefault("INTEGRA_JWT_SECRET", "segredo-de-teste-com-32-caracteres-ok")
os.environ.setdefault("INTEGRA_AMBIENTE", "local")

import pytest

from integra_shared.config import obter_settings


@pytest.fixture
def settings():
    obter_settings.cache_clear()
    return obter_settings()
