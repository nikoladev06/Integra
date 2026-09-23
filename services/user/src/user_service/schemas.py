"""Schemas de entrada e saída do user-service.

Espelham `contracts/user.openapi.yaml`. Os nomes de campo saem em camelCase
porque é o que o contrato declara e o que o cliente Flutter lê; internamente o
Python continua em snake_case.
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from user_service.models import TipoConta


def _para_camel(nome: str) -> str:
    primeira, *resto = nome.split("_")
    return primeira + "".join(p.capitalize() for p in resto)


class _Saida(BaseModel):
    model_config = ConfigDict(
        alias_generator=_para_camel,
        populate_by_name=True,
        from_attributes=True,
    )


class UniversidadeOut(_Saida):
    id: UUID
    nome: str
    sigla: str


class CursoOut(_Saida):
    id: UUID
    nome: str


class UniversidadeSeguidaOut(UniversidadeOut):
    propria: bool
    seguida_em: datetime | None = None


class AfiliacaoOut(_Saida):
    universidade: UniversidadeOut
    curso: CursoOut


class PerfilPublicoOut(_Saida):
    id: UUID
    nome_completo: str
    username: str
    tipo: TipoConta
    afiliacao: AfiliacaoOut
    foto_url: str | None = None
    bio: str | None = None
    criado_em: datetime

    @model_validator(mode="before")
    @classmethod
    def _montar_afiliacao(cls, dados: object) -> object:
        """Monta o objeto `afiliacao` a partir do modelo ORM.

        A tabela guarda `universidade` e `curso` como colunas soltas — o vínculo
        é um-para-um e uma tabela `afiliacoes` não se pagaria. O contrato, por
        outro lado, expõe os dois aninhados, porque é um conceito só do ponto de
        vista de quem consome. Esta é a costura entre as duas formas, num lugar
        só: sem ela, cada rota montaria o dicionário à mão e uma delas
        esqueceria.
        """
        if isinstance(dados, dict):
            return dados
        if getattr(dados, "afiliacao", None) is not None:
            return dados

        universidade = getattr(dados, "universidade", None)
        curso = getattr(dados, "curso", None)
        if universidade is None or curso is None:
            # Contas `faculdade` e `empresa` podem existir sem vínculo, mas o
            # contrato declara `afiliacao` obrigatória. Falhar aqui com uma
            # mensagem clara é melhor que um ValidationError do Pydantic sobre
            # um campo que não existe no modelo.
            raise ValueError(
                f"usuário {getattr(dados, 'id', '?')} está sem afiliação, e o "
                "contrato exige universidade e curso no perfil"
            )

        return {
            "id": dados.id,
            "nome_completo": dados.nome_completo,
            "username": dados.username,
            "tipo": dados.tipo,
            "afiliacao": {"universidade": universidade, "curso": curso},
            "foto_url": dados.foto_url,
            "bio": dados.bio,
            "criado_em": dados.criado_em,
            "email": getattr(dados, "email", None),
            "telefone": getattr(dados, "telefone", None),
            "alterado_em": getattr(dados, "alterado_em", None),
        }


class PerfilOut(PerfilPublicoOut):
    """O próprio perfil, com os dados de contato que o público omite."""

    email: str
    telefone: str | None = None
    alterado_em: datetime | None = None


class PaginaDePerfis(_Saida):
    itens: list[PerfilPublicoOut]
    proximo_cursor: str | None = None


class AtualizarPerfilIn(BaseModel):
    """`PATCH /users/me`. Campos ausentes ficam inalterados."""

    model_config = ConfigDict(alias_generator=_para_camel, populate_by_name=True)

    nome_completo: str | None = None
    username: str | None = Field(default=None, min_length=3, pattern=r"^[a-zA-Z0-9_]+$")
    telefone: str | None = Field(default=None, pattern=r"^\(?\d{2}\)?[\s-]?\d{4,5}-?\d{4}$")
    bio: str | None = Field(default=None, max_length=280)
    foto_url: str | None = None
    universidade_id: UUID | None = None
    curso_id: UUID | None = None

    @field_validator("username")
    @classmethod
    def _minusculo(cls, v: str | None) -> str | None:
        return v.lower() if v else v


class CriarUsuarioIn(BaseModel):
    """Rota interna, chamada pelo auth-service durante o cadastro.

    Não é pública: o `id` vem de fora porque quem o gera é o auth-service, que
    precisa dele para gravar a credencial correspondente.
    """

    model_config = ConfigDict(alias_generator=_para_camel, populate_by_name=True)

    id: UUID
    nome_completo: str
    email: str
    username: str
    telefone: str | None = None
    universidade_id: UUID
    curso_id: UUID
    tipo: TipoConta = TipoConta.ALUNO
