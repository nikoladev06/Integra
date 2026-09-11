"""Peças comuns aos microsserviços Integra."""

from integra_shared.app import criar_app
from integra_shared.config import Settings, obter_settings
from integra_shared.errors import AppError, ErrorResponse
from integra_shared.security import (
    UsuarioAtual,
    UsuarioAutenticado,
    criar_access_token,
    decodificar_access_token,
    exigir_tipo,
)

__all__ = [
    "AppError",
    "ErrorResponse",
    "Settings",
    "UsuarioAtual",
    "UsuarioAutenticado",
    "criar_access_token",
    "criar_app",
    "decodificar_access_token",
    "exigir_tipo",
    "obter_settings",
]
