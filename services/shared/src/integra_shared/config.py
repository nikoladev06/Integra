"""Configuração comum, lida do ambiente.

Nenhum segredo tem valor padrão utilizável: `jwt_secret` é obrigatório e o serviço
se recusa a subir sem ele. Um default de desenvolvimento aqui é como segredo de
produção vaza — basta alguém não definir a variável e o deploy sobe assinando
tokens com uma chave que está no repositório.
"""

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="INTEGRA_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    ambiente: Literal["local", "producao"] = "local"
    versao: str = "0.1.0"

    jwt_secret: str = Field(
        min_length=32,
        description="Segredo HS256. Compartilhado entre os serviços, que validam "
        "a assinatura sem chamar o auth-service.",
    )
    jwt_algoritmo: str = "HS256"
    access_token_ttl_segundos: int = Field(default=900, gt=0)
    refresh_token_ttl_dias: int = Field(default=30, gt=0)

    database_url: str | None = Field(
        default=None,
        description="DSN do PostgreSQL. Ausente na Sprint 1, quando ainda não há "
        "modelo: o health reporta o banco como 'nao_configurado' em vez de falhar.",
    )


@lru_cache
def obter_settings() -> Settings:
    """Instância única por processo. O cache também deixa o override em teste barato."""
    return Settings()  # type: ignore[call-arg]
