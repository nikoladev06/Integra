"""Alembic do jobs-service. A lógica vive em integra_shared.migrations."""

from integra_shared.migrations import executar_migracoes
from jobs_service.models import Base
from jobs_service.settings import settings

assert settings.database_url, "INTEGRA_DATABASE_URL é obrigatória para migrar"
executar_migracoes(Base.metadata, schema="jobs", dsn=settings.database_url)
