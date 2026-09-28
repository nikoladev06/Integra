"""Configuração do feed-service."""

from pydantic import Field

from integra_shared.config import Settings as SettingsBase


class Settings(SettingsBase):
    servico_token: str = Field(
        min_length=32,
        description="Segredo compartilhado com o user-service para as rotas internas. "
        "Distinto do JWT: quem chama é um serviço, não um usuário.",
    )

    user_service_url: str = Field(
        default="http://user:8000",
        description="Nome do serviço na rede do compose, não o gateway: a chamada "
        "interna vai direto, sem dar a volta pela borda.",
    )


settings = Settings()  # type: ignore[call-arg]
