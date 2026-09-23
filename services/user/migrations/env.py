"""Alembic do user-service. A lógica vive em integra_shared.migrations."""

from integra_shared.migrations import executar_migracoes
from user_service.models import Base
from user_service.settings import settings

assert settings.database_url, "INTEGRA_DATABASE_URL é obrigatória para migrar"
executar_migracoes(Base.metadata, schema="user", dsn=settings.database_url)
