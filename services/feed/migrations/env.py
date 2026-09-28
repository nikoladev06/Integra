"""Alembic do feed-service. A lógica vive em integra_shared.migrations."""

from feed_service.models import Base
from feed_service.settings import settings
from integra_shared.migrations import executar_migracoes

assert settings.database_url, "INTEGRA_DATABASE_URL é obrigatória para migrar"
executar_migracoes(Base.metadata, schema="feed", dsn=settings.database_url)
