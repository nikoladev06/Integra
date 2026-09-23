"""Configuração do user-service."""

from pydantic import Field

from integra_shared.config import Settings as SettingsBase


class Settings(SettingsBase):
    servico_token: str = Field(
        min_length=32,
        description="Segredo compartilhado entre auth-service e user-service para "
        "as rotas internas. Distinto do JWT: quem chama é um serviço, não um "
        "usuário, e não há sessão a representar.",
    )


settings = Settings()  # type: ignore[call-arg]
