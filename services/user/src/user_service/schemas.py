"""Schemas de entrada e saída do user-service.

Espelham `contracts/user.openapi.yaml` v2. Os nomes saem em camelCase porque é o
que o contrato declara e o que o cliente Flutter lê; internamente o Python segue
em snake_case.

Diferente da v1, nenhum schema precisa montar objeto aninhado à mão: os nomes de
atributo do ORM (`formacoes`, `vinculo`, `universidade`, `curso`) já batem com os
do contrato, então `from_attributes` dá conta. A v1 precisava de um
`model_validator` porque expunha um `afiliacao` que não existia no modelo.
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
        serialize_by_alias=True,
    )


class _Entrada(BaseModel):
    model_config = ConfigDict(alias_generator=_para_camel, populate_by_name=True)


# ───────────────────────────  instituições  ───────────────────────────


class UniversidadeOut(_Saida):
    id: UUID
    nome: str
    sigla: str

    # Vem da propriedade `Universidade.tem_conta`. O CNPJ NÃO sai daqui: é dado
    # de identificação da organização e não tem por que circular na busca.
    tem_conta: bool = False


class CursoOut(_Saida):
    id: UUID
    nome: str


class UniversidadeSeguidaOut(UniversidadeOut):
    propria: bool
    seguida_em: datetime | None = None


class PerfilDeUniversidadeOut(_Saida):
    """A tela que o aluno alcança pela busca."""

    id: UUID
    nome: str
    sigla: str
    bio: str | None = None
    foto_url: str | None = None

    # Decide se o menu do perfil oferece "inserir CPF" ou "encerrar vínculo".
    tem_vinculo: bool
    seguindo: bool

    # Agregado, sem expor quem: quantos têm vínculo ativo.
    total_de_alunos: int


# ────────────────────────  formação e vínculo  ────────────────────────


class FormacaoOut(_Saida):
    """Uma linha do currículo.

    `verificada_em` não nulo é o selo. O cliente mostra **apenas o selo**, sem
    rótulo nas não verificadas — a ausência já comunica o suficiente.
    """

    id: UUID
    universidade: UniversidadeOut
    curso: CursoOut
    verificada_em: datetime | None = None
    criado_em: datetime


class VinculoOut(_Saida):
    """O laço ativo. No máximo um por usuário, e o único que concede acesso."""

    universidade: UniversidadeOut
    curso: CursoOut
    criado_em: datetime


class DeclararFormacaoIn(_Entrada):
    universidade_id: UUID
    curso_id: UUID


class CriarVinculoIn(_Entrada):
    cpf: str


# ──────────────────────────────  perfil  ──────────────────────────────


class PerfilPublicoOut(_Saida):
    id: UUID
    nome_completo: str
    username: str
    tipo: TipoConta
    formacoes: list[FormacaoOut] = Field(default_factory=list)
    vinculo: VinculoOut | None = None
    foto_url: str | None = None
    bio: str | None = None
    criado_em: datetime


class PerfilOut(PerfilPublicoOut):
    """O próprio perfil. **`cpf` e `cnpj` aparecem somente aqui.**"""

    email: str
    cpf: str | None = None
    cnpj: str | None = None
    telefone: str | None = None
    alterado_em: datetime | None = None

    # Nulo em conta institucional pendente: ela entra, edita o perfil e vê a
    # própria página, mas não publica nem matricula. A tela usa isto para mostrar
    # o aviso de "aguardando ativação".
    ativada_em: datetime | None = None


class PaginaDePerfis(_Saida):
    itens: list[PerfilPublicoOut]
    proximo_cursor: str | None = None


class AtualizarPerfilIn(_Entrada):
    """`PATCH /users/me`. Campos ausentes ficam inalterados.

    Não inclui `email` nem `cpf`: o e-mail é credencial e pertence ao
    auth-service; o CPF é a chave que liga a conta às matrículas, e deixá-lo
    editável permitiria assumir a matrícula de outra pessoa.
    """

    nome_completo: str | None = None
    username: str | None = Field(default=None, min_length=3, pattern=r"^[a-zA-Z0-9_]+$")
    telefone: str | None = Field(default=None, pattern=r"^\(?\d{2}\)?[\s-]?\d{4,5}-?\d{4}$")
    bio: str | None = Field(default=None, max_length=280)
    foto_url: str | None = None

    @field_validator("username")
    @classmethod
    def _minusculo(cls, v: str | None) -> str | None:
        return v.lower() if v else v


class CriarInstituicaoIn(_Entrada):
    """Rota interna, chamada pelo auth-service no cadastro de faculdade/empresa.

    `sigla` só é usada quando o CNPJ não corresponde a nenhuma universidade
    conhecida e uma nova precisa ser criada.
    """

    id: UUID
    tipo: TipoConta
    nome: str
    cnpj: str
    email: str
    username: str
    telefone: str | None = None
    sigla: str | None = None

    @field_validator("tipo")
    @classmethod
    def _so_institucional(cls, v: TipoConta) -> TipoConta:
        if v == TipoConta.ALUNO:
            raise ValueError("esta rota cria apenas contas faculdade ou empresa")
        return v


class CriarUsuarioIn(_Entrada):
    """Rota interna, chamada pelo auth-service durante o cadastro.

    O `id` vem de fora porque quem o gera é o auth-service, que precisa dele para
    gravar a credencial correspondente.

    `universidade_id`/`curso_id` são opcionais e, quando vêm, criam uma formação
    **declarada** — nunca um vínculo.
    """

    id: UUID
    nome_completo: str
    email: str
    username: str
    cpf: str
    telefone: str | None = None
    tipo: TipoConta = TipoConta.ALUNO

    universidade_id: UUID | None = None
    curso_id: UUID | None = None

    @model_validator(mode="after")
    def _formacao_completa_ou_ausente(self) -> "CriarUsuarioIn":
        if (self.universidade_id is None) != (self.curso_id is None):
            raise ValueError("informe universidade e curso juntos, ou nenhum dos dois")
        return self


# ─────────────────────────────  matrícula  ─────────────────────────────


class MatriculaOut(_Saida):
    """Um aluno na lista da instituição.

    `cpf` é devolvido **só à instituição que o cadastrou** — foi ela que o
    digitou. Nunca sai em resposta pública nem para outra instituição.
    """

    id: UUID
    cpf: str
    curso: CursoOut
    vinculada: bool
    usuario: PerfilPublicoOut | None = None
    criado_em: datetime


class CriarMatriculaIn(_Entrada):
    cpf: str
    curso_id: UUID


class CriarCursoIn(_Entrada):
    nome: str = Field(min_length=2, max_length=200)


# ──────────────────────────────  busca  ──────────────────────────────


class ResultadoDeBuscaOut(_Saida):
    """Grupos sempre presentes, possivelmente vazios.

    Devolver as três chaves mesmo vazias evita o cliente ter que distinguir
    "não achei" de "não pedi este tipo" — a ausência de chave seria ambígua.
    """

    universidades: list[UniversidadeOut] = Field(default_factory=list)
    empresas: list[PerfilPublicoOut] = Field(default_factory=list)
    pessoas: list[PerfilPublicoOut] = Field(default_factory=list)
