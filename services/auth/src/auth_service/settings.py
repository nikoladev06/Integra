"""Configuração do auth-service."""

from pydantic import Field

from integra_shared.config import Settings as SettingsBase


class Settings(SettingsBase):
    servico_token: str = Field(
        min_length=32,
        description="Segredo compartilhado com o user-service para as rotas internas.",
    )
    user_service_url: str = Field(
        default="http://user:8000",
        description="Endereço interno do user-service. Dentro da rede do compose o "
        "nome do serviço resolve pelo DNS do Docker; não passa pelo Traefik.",
    )


settings = Settings()  # type: ignore[call-arg]
