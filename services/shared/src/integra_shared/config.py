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

    # ─────────────────  Object Storage (Sprint 5) — compatível com S3  ─────────────────
    #
    # Nulo por padrão, e o serviço sobe sem ele: só as rotas de upload respondem
    # 503, e o resto da API funciona. É o que permite rodar local sem MinIO — e é o
    # oposto do que um bucket de exemplo no default faria, que é emitir URLs que
    # falham no `PUT` e fazer o cliente culpar o próprio arquivo.

    storage_endpoint: str | None = Field(
        default=None,
        description="O endpoint que o CLIENTE alcança (http://localhost:9000 local, "
        "o do Object Storage em produção) — não o nome na rede interna. Assinar é "
        "computação local, então o serviço nunca precisa alcançar este host; quem "
        "precisa é o celular, que não resolve `minio`.",
    )
    storage_bucket: str = "integra"
    storage_access_key: str | None = None
    storage_secret_key: str | None = None
    storage_regiao: str = Field(
        default="us-east-1",
        description="Exigida pela assinatura SigV4 mesmo onde não significa nada. "
        "O MinIO aceita qualquer valor, desde que o mesmo dos dois lados.",
    )
    upload_ttl_segundos: int = Field(
        default=300,
        gt=0,
        description="Validade da URL de upload. Curta de propósito: ela autoriza "
        "escrever num caminho do bucket, e o cliente a usa em segundos.",
    )

    @property
    def storage_configurado(self) -> bool:
        """Se há o suficiente para assinar. Endpoint sem chave não assina nada."""
        return all((self.storage_endpoint, self.storage_access_key, self.storage_secret_key))


@lru_cache
def obter_settings() -> Settings:
    """Instância única por processo. O cache também deixa o override em teste barato."""
    return Settings()  # type: ignore[call-arg]
