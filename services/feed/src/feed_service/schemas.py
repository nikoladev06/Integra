"""Schemas de entrada e saída do feed-service.

Espelham `contracts/feed.openapi.yaml` v1.0.0. Os nomes saem em camelCase porque é
o que o contrato declara e o que o cliente Flutter lê; internamente o Python segue
em snake_case.

Três coisas que **não** existem como campo de entrada, e a ausência é a garantia:

- **`autorId`** — é a conta autenticada. Se fosse campo, uma conta publicaria no
  nome de outra.
- **`autorTipo`** e **`autorUniversidadeId`** — saem do token e do user-service na
  publicação. Aceitá-los do cliente deixaria qualquer um se declarar empresa para
  aparecer no `escopo=empresas`, ou se declarar aluno de uma universidade para
  entrar no feed recomendado dela.
- **`curtidoPorMim`** e os totais — calculados por leitor e por consulta.
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from feed_service.models import (
    LIMITE_DA_URL,
    LIMITE_DO_COMENTARIO,
    LIMITE_DO_POST,
    TipoDeAutor,
)


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


class AutorDePostOut(_Saida):
    """Quem publicou: nome, arroba, foto e tipo.

    Nome e foto são resolvidos **na leitura**, em lote, contra o user-service. O
    `tipo` não: ele é coluna do post, porque é o que o escopo filtra na consulta
    paginada — resolvê-lo depois faria uma página de 20 vir com 3 itens e o cursor
    mentir sobre onde parou.
    """

    id: UUID
    nome_completo: str
    username: str
    foto_url: str | None = None
    tipo: TipoDeAutor


class AutorDeComentarioOut(_Saida):
    """Quem comentou: nome, arroba e foto. **Sem `tipo`.**

    Idêntico ao do academic-service, e a ausência do tipo é deliberada: nenhum escopo
    filtra comentário, então o tipo do autor não é coluna de `comentarios` — e um
    campo no schema de saída que o serviço não tem como preencher corretamente é
    pior que um campo ausente. Reusar `AutorDePostOut` aqui obrigaria a inventar um
    valor.
    """

    id: UUID
    nome_completo: str
    username: str
    foto_url: str | None = None


class PostOut(_Saida):
    id: UUID
    autor: AutorDePostOut
    conteudo: str
    imagem_url: str | None = None

    # Preenchida somente nas respostas do feed. Fora dele ninguém fez a pergunta
    # "por que estou vendo isto?", e responder custaria uma ida ao user-service por
    # post aberto só para descobrir se o leitor segue o autor.
    origem: str | None = None

    total_de_curtidas: int = 0
    total_de_comentarios: int = 0

    # Estado por leitor, não do registro.
    curtido_por_mim: bool = False

    # Se o leitor é o autor. Evita a tela inferir permissão comparando ids — e
    # inferir errado num caso que o servidor recusaria.
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
    proximo_cursor: str | None = None


class PaginaDeComentarios(_Saida):
    itens: list[ComentarioOut]
    proximo_cursor: str | None = None


class UploadUrlOut(_Saida):
    upload_url: str
    imagem_url: str
    expira_em: datetime


# ──────────────────────────────  entrada  ──────────────────────────────


class PublicarPostIn(_Entrada):
    """`POST /feed/posts`."""

    conteudo: str = Field(min_length=1, max_length=LIMITE_DO_POST)
    imagem_url: str | None = Field(default=None, max_length=LIMITE_DA_URL)

    @property
    def conteudo_limpo(self) -> str:
        return self.conteudo.strip()


class EditarPostIn(_Entrada):
    """`PATCH /feed/posts/{id}`. Campos omitidos ficam inalterados.

    Ao contrário do academic-service, `imagemUrl: null` aqui **é** um valor com
    significado: remove a imagem. Lá o nulo de `cursoId` era ambíguo e o contrato
    resolvia pela `visibilidade`; aqui não há um segundo campo de onde deduzir a
    intenção, então o nulo explícito é a única forma de dizer "tire a imagem".

    Distinguir "omitido" de "nulo" exige `model_fields_set`, e é por isso que
    `vazio` e `remove_imagem` existem como propriedades em vez de a rota comparar
    com `None` — a comparação daria o mesmo resultado nos dois casos.
    """

    conteudo: str | None = Field(default=None, min_length=1, max_length=LIMITE_DO_POST)
    imagem_url: str | None = Field(default=None, max_length=LIMITE_DA_URL)

    @property
    def vazio(self) -> bool:
        """Corpo sem nenhum campo mencionado. Recusado em `services.posts.editar`.

        Um `PATCH` que não muda nada marcaria `editadoEm` sem edição nenhuma, e a
        tela passaria a exibir "editado" num post intacto.
        """
        return not {"conteudo", "imagem_url", "imagemUrl"} & self.model_fields_set

    @property
    def mencionou_imagem(self) -> bool:
        return bool({"imagem_url", "imagemUrl"} & self.model_fields_set)


class ComentarIn(_Entrada):
    conteudo: str = Field(min_length=1, max_length=LIMITE_DO_COMENTARIO)

    @property
    def conteudo_limpo(self) -> str:
        return self.conteudo.strip()


class UploadUrlIn(_Entrada):
    """`POST /feed/posts/imagem/upload-url`. Mesmo corpo do avatar.

    O tamanho é declarado **antes** do envio porque ele entra na assinatura: o
    storage recusa um `PUT` cujo `content-length` não seja exatamente este. Sem
    isso, "tamanhoBytes" seria uma declaração de boa vontade.
    """

    content_type: str
    tamanho_bytes: int = Field(gt=0)
