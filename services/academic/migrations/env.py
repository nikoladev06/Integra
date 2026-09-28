"""Alembic do academic-service. A lógica vive em integra_shared.migrations."""

from academic_service.models import Base
from academic_service.settings import settings
from integra_shared.migrations import executar_migracoes

assert settings.database_url, "INTEGRA_DATABASE_URL é obrigatória para migrar"
executar_migracoes(Base.metadata, schema="academic", dsn=settings.database_url)
