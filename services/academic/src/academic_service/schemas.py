"""Schemas de entrada e saída do academic-service.

Espelham `contracts/academic.openapi.yaml` v1.0.0. Os nomes saem em camelCase
porque é o que o contrato declara e o que o cliente Flutter lê; internamente o
Python segue em snake_case.

Duas coisas que **não** existem como campo de entrada, e a ausência é a garantia:

- **`universidadeId`** na publicação. A universidade do post é a da conta autora,
  lida do user-service. Se fosse campo, uma faculdade publicaria no nome de outra
  — e a checagem que impede isso teria que ser lembrada em toda rota nova.
- **`curtidoPorMim`** e **`totalDeCurtidas`** como colunas. São calculados por
  leitor e por consulta. O protótipo guardava `isLiked` dentro do post, e a
  curtida de uma pessoa aparecia para todas.
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from academic_service.models import LIMITE_DO_COMENTARIO, LIMITE_DO_POST, Visibilidade


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


# ──────────────────────────────  saída  ──────────────────────────────


class InstituicaoDoPostOut(_Saida):
    """Quem publicou, resolvido na leitura a partir de `universidade_id`."""

    id: UUID
    nome: str
    sigla: str
    foto_url: str | None = None


class CursoOut(_Saida):
    id: UUID
    nome: str


class AutorDeComentarioOut(_Saida):
    id: UUID
    nome_completo: str
    username: str
    foto_url: str | None = None


class PostOut(_Saida):
    id: UUID
    instituicao: InstituicaoDoPostOut
    visibilidade: Visibilidade

    # Presente **somente** em `visibilidade == curso`. A tela mostra como etiqueta
    # ao lado do alcance: o aluno precisa saber que aquilo não é público.
    curso: CursoOut | None = None

    conteudo: str
    total_de_curtidas: int = 0
    total_de_comentarios: int = 0

    # Estado por leitor, não do registro.
    curtido_por_mim: bool = False

    # Se o leitor é a conta autora. Evita a tela inferir permissão comparando ids
    # — e inferir errado num caso que o servidor recusaria.
    pode_editar: bool = False

    criado_em: datetime
    editado_em: datetime | None = None


class ComentarioOut(_Saida):
    id: UUID
    post_id: UUID
    autor: AutorDeComentarioOut
    conteudo: str
    pode_remover: bool = False
    criado_em: datetime


class PaginaDePosts(_Saida):
    itens: list[PostOut]

    # Opaco: codifica data e id do último item, não um deslocamento. Com `OFFSET`,
    # um post publicado entre duas páginas repetiria um item na segunda.
    proximo_cursor: str | None = None


class PaginaDeComentarios(_Saida):
    itens: list[ComentarioOut]
    proximo_cursor: str | None = None


# ──────────────────────────────  entrada  ──────────────────────────────


class PublicarPostIn(_Entrada):
    """`POST /academic/posts`.

    `visibilidade` é obrigatória e **sem default**: o formulário pré-seleciona
    `institucional`, mas o serviço não adivinha. Um default aqui faria uma chamada
    malformada publicar com alcance que ninguém escolheu.
    """

    conteudo: str = Field(min_length=1, max_length=LIMITE_DO_POST)
    visibilidade: Visibilidade
    curso_id: UUID | None = None

    # A coerência entre `visibilidade` e `curso_id` **não** é validada aqui, e a
    # razão é o formato do erro. Um `model_validator` levanta `ValueError`, que o
    # FastAPI reporta com `loc = ("body",)` — sem coluna —, e o tradutor de
    # `integra_shared.errors` transforma isso em `fields: {"_": [...]}`. O
    # formulário do app não tem onde pintar essa mensagem.
    #
    # É a divisão que `errors.py` já descreve: o Pydantic cobre o **formato**
    # (tipo, tamanho, obrigatoriedade) e a regra de negócio mora no serviço, que
    # levanta `AppError` nomeando o campo a destacar. Ver `services.posts`.

    @property
    def conteudo_limpo(self) -> str:
        return self.conteudo.strip()


class EditarPostIn(_Entrada):
    """`PATCH /academic/posts/{id}`. Campos omitidos ficam inalterados.

    Ao contrário de [PublicarPostIn], a coerência entre `visibilidade` e `curso_id`
    **não** pode ser validada aqui: o valor que falta pode estar no post gravado —
    passar a `visibilidade: curso` sem informar `cursoId` é válido se o post já
    tinha um. A checagem mora em `services.posts.editar`, que conhece as duas
    metades.

    `universidadeId` e `autorId` não existem no corpo, e é a ausência que garante
    que uma edição não mova o post para outra instituição.
    """

    conteudo: str | None = Field(default=None, min_length=1, max_length=LIMITE_DO_POST)
    visibilidade: Visibilidade | None = None
    curso_id: UUID | None = None

    # `curso_id: None` é ambíguo num PATCH — "não mencionei" ou "quero limpar"? O
    # contrato resolve pela visibilidade: sair de `curso` limpa o campo, entrar
    # nele exige um valor. Assim nenhum cliente precisa mandar `null` explícito, e
    # não há diferença de comportamento entre omitir e mandar nulo.

    @property
    def vazio(self) -> bool:
        """Corpo sem nenhum campo. Recusado em `services.posts.editar`.

        Um `PATCH` que não muda nada marcaria `editadoEm` sem edição nenhuma, e a
        tela passaria a exibir "editado" num post intacto.
        """
        return self.conteudo is None and self.visibilidade is None and self.curso_id is None


class ComentarIn(_Entrada):
    conteudo: str = Field(min_length=1, max_length=LIMITE_DO_COMENTARIO)

    @property
    def conteudo_limpo(self) -> str:
        return self.conteudo.strip()
