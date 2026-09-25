"""Schemas do auth-service, espelhando `contracts/auth.openapi.yaml`."""

from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, model_validator


def _para_camel(nome: str) -> str:
    primeira, *resto = nome.split("_")
    return primeira + "".join(p.capitalize() for p in resto)


class _Base(BaseModel):
    model_config = ConfigDict(alias_generator=_para_camel, populate_by_name=True)


class CadastroIn(_Base):
    """Corpo de `POST /auth/register`.

    `universidade_id` e `curso_id` são **opcionais** desde a v2: declarar formação
    é cosmético e não concede acesso a nada. Quem os informa ganha uma linha no
    currículo, não um vínculo — o vínculo nasce no user-service, quando o aluno
    informa o CPF no perfil da instituição.
    """

    nome_completo: str
    email: str
    username: str
    senha: str
    telefone: str
    cpf: str

    universidade_id: UUID | None = None
    curso_id: UUID | None = None

    @model_validator(mode="after")
    def _formacao_completa_ou_ausente(self) -> "CadastroIn":
        """Os dois campos de formação vêm juntos, ou nenhum vem.

        A tela encadeia os combobox — escolher a universidade habilita o de
        cursos — então só um dos dois indica requisição malformada. Aceitar
        universidade sem curso criaria meia formação, que nenhuma tela sabe
        exibir.
        """
        if (self.universidade_id is None) != (self.curso_id is None):
            raise ValueError("informe universidade e curso juntos, ou nenhum dos dois")
        return self


class CadastroInstituicaoIn(_Base):
    """Corpo de `POST /auth/register/instituicao`.

    Uma rota, duas telas: o cliente tem um formulário para faculdade e outro para
    empresa, e os dois postam aqui com `tipo` diferente. Um só corpo evita duas
    rotas quase idênticas divergindo com o tempo.

    Não tem CPF nem formação: organização não estuda em lugar nenhum, e o CPF é
    de pessoa. A conta nasce **pendente** — ver `services/registro.cadastrar_instituicao`.
    """

    tipo: Literal["faculdade", "empresa"]
    nome: str
    cnpj: str
    email: str
    username: str
    senha: str
    telefone: str

    # Só usada quando o CNPJ não corresponde a nenhuma universidade conhecida e
    # uma nova precisa ser criada.
    sigla: str | None = None


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
