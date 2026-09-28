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

    # Não há contagem de alunos aqui. Ela existiu até a v2.1 e saiu por decisão de
    # produto: quantos alunos uma faculdade tem no Integra é informação dela. Saiu
    # do **schema**, e não só da tela — o campo que o cliente não exibe continua
    # legível para quem ler a resposta.


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


# ───────────────────  rotas internas (serviço a serviço)  ───────────────────
#
# Fora do OpenAPI público: não são parte do contrato que o cliente Flutter
# consome, e o guarda de deriva as ignora pelo mesmo motivo. Existem porque o
# `academic-service` precisa de três coisas que o user-service é dono, e
# copiá-las para o schema dele seria denormalizar entre serviços — o erro que o
# protótipo cometeu ao gravar `nomeCompleto` dentro de cada post.


class ResumoDeUniversidadeOut(_Saida):
    """O cabeçalho de um card de post: quem publicou.

    Resolvido na LEITURA, em lote por página de feed, e não copiado para dentro
    do post na publicação. O custo é uma chamada por página; o ganho é que
    renomear uma instituição alcança o que já está publicado.
    """

    id: UUID
    nome: str
    sigla: str
    foto_url: str | None = None

    # Os cursos vêm junto, e não numa segunda chamada, por um motivo que o
    # academic-service expõe: um post restrito a curso só é visível a quem tem
    # vínculo naquele curso, então o nome que ele precisa exibir é sempre de um
    # curso desta universidade. Pedir a lista à parte seria uma ida a mais ao
    # banco para montar uma etiqueta. A lista já é pública em
    # `GET /universidades/{id}/cursos` — não há nada aqui que o catálogo não diga.
    cursos: list[CursoOut] = Field(default_factory=list)


class UniversidadeDaContaOut(ResumoDeUniversidadeOut):
    """O que o `academic-service` precisa saber para deixar alguém publicar.

    Acrescenta ao resumo a única coisa que só a publicação precisa: se a conta
    está ativada. A universidade do autor (que **não** é campo do corpo do post,
    senão uma faculdade publicaria no nome de outra) e os cursos válidos para
    restringir um post já vêm do resumo.

    `conta_ativa` sai do BANCO, não de um claim do token. É a mesma razão de
    `exigir_faculdade_ativa`: no JWT, uma conta desativada seguiria publicando
    por até 15 minutos.
    """

    conta_ativa: bool


class ResumoDePerfilOut(_Saida):
    """Quem comentou: nome, arroba e foto, e nada além.

    `PerfilPublicoOut` traria formações e vínculo para um card de comentário que
    não os mostra — e faria o serviço de posts depender do formato de perfil
    completo para renderizar uma linha de texto.
    """

    id: UUID
    nome_completo: str
    username: str
    foto_url: str | None = None


class AvatarUploadUrlIn(_Entrada):
    """`POST /users/me/avatar/upload-url`.

    O tamanho é declarado **antes** do envio porque ele entra na assinatura: o storage
    recusa um `PUT` cujo `content-length` não seja exatamente este. Sem isso,
    "tamanhoBytes" seria uma declaração de boa vontade, e nada impediria 500 MB numa URL
    pedida para 2 KB.

    As faixas não estão repetidas aqui: `integra_shared.armazenamento` valida o tipo e o
    tamanho e levanta 422 nomeando o campo. Duas escritas do mesmo limite divergiriam, e
    quem chama o módulo compartilhado de outro serviço não herdaria esta cópia.
    """

    content_type: str
    tamanho_bytes: int


class AvatarUploadUrlOut(_Saida):
    """Onde enviar, o que gravar depois, e até quando a URL vale.

    O cliente faz `PUT` do arquivo em `uploadUrl` e depois grava `fotoUrl` via
    `PATCH /users/me`. **Bytes de imagem nunca atravessam este serviço** — receber o
    multipart e repassar faria cada upload ocupar um worker do uvicorn pelo tempo da
    conexão do celular, e o serviço de perfil ficaria indisponível por causa de fotos.
    """

    upload_url: str
    foto_url: str
    expira_em: datetime


class EscopoDoFeedOut(_Saida):
    """As duas listas que decidem o feed profissional. Rota interna, Sprint 5.

    `universidades` é vínculo + seguidas + a administrada — o mesmo conjunto do
    escopo `geral` do feed acadêmico, e o que torna um autor **recomendado**.
    `seguidos` são as contas que o leitor segue, pessoas e empresas.

    Ids crus, sem nome nem foto: o feed-service vai usá-los num `IN`, e resolve os
    cabeçalhos depois — em lote, só para quem sobrar na página.
    """

    universidades: list[UUID]
    seguidos: list[UUID]


class AtivacaoOut(_Saida):
    """Se a conta pode agir, e o tipo dela. Rota interna, Sprint 5.

    Existe para os outros serviços **não** chamarem `GET /users/interno/{userId}`,
    que devolve CPF e CNPJ. Um serviço de posts não tem o que fazer com CPF, e um
    tipo de saída que o carrega é um vazamento esperando uma rota nova.
    """

    ativa: bool
    tipo: TipoConta
