"""Schemas do auth-service, espelhando `contracts/auth.openapi.yaml`."""

from uuid import UUID

from pydantic import BaseModel, ConfigDict


def _para_camel(nome: str) -> str:
    primeira, *resto = nome.split("_")
    return primeira + "".join(p.capitalize() for p in resto)


class _Base(BaseModel):
    model_config = ConfigDict(alias_generator=_para_camel, populate_by_name=True)


class CadastroIn(_Base):
    nome_completo: str
    email: str
    username: str
    senha: str
    telefone: str
    universidade_id: UUID
    curso_id: UUID


class CadastroOut(_Base):
    user_id: UUID


class LoginIn(_Base):
    email: str
    senha: str


class RefreshIn(_Base):
    refresh_token: str


class TrocarSenhaIn(_Base):
    senha_atual: str
    nova_senha: str
    confirmacao: str


class ParDeTokensOut(_Base):
    access_token: str
    refresh_token: str
    expires_in: int
    token_type: str = "Bearer"
