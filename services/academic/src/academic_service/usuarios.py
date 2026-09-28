"""O que o academic-service pergunta ao user-service, e o que ele não pergunta.

## O que NÃO passa por aqui: o vínculo

O vínculo ativo viaja no **token**, nos claims `vinculoUniversidadeId` e
`vinculoCursoId`. É o desenho descrito em `integra_shared.security`: o preço é que
entrar ou sair de um vínculo só vale no token seguinte — no máximo 15 minutos — e
o ganho é que resolver visibilidade não custa uma ida ao user-service por
requisição.

A consequência boa aparece na falha: `escopo=minha` é atendido **inteiramente a
partir do token**. Com o user-service fora do ar, o feed da própria instituição
continua respondendo.

## O que passa: três coisas que o user-service é dono

1. **A lista de universidades do escopo `geral`** — vínculo + seguidas. Decide
   QUAIS instituições entram no feed, nunca O QUE se vê dentro delas. Se esta
   lista viesse errada, o feed mostraria instituições a mais ou a menos; nenhum
   post restrito escaparia por ela, porque o alcance é decidido pela cláusula de
   visibilidade, com o vínculo do token.
2. **A universidade da conta que publica**, com os cursos e o estado de ativação.
3. **Nome, sigla e foto** de universidades e autores, para montar os cards.

O item 3 é uma chamada por página de feed, em lote. A alternativa era copiar nome
e sigla para dentro de cada post na publicação — e era o erro do protótipo, que
gravava `nomeCompleto` dentro do post e via o nome envelhecer ali: trocar o nome
não alcançava o que já estava publicado.

## Falha

Nenhuma resposta parcial silenciosa. Sem o user-service, `geral` responde 503 com
mensagem de "tente novamente" em vez de um feed que parece completo e não está —
um feed que esconde metade das instituições sem dizer nada é pior que um erro,
porque o usuário conclui que não há nada publicado.
"""

from uuid import UUID

import httpx
from pydantic import BaseModel, Field

from academic_service.settings import settings
from integra_shared.errors import AppError

_TEMPO_LIMITE = httpx.Timeout(10.0)


class Curso(BaseModel):
    id: UUID
    nome: str


class ResumoDeUniversidade(BaseModel):
    """O cabeçalho do card: quem publicou, com os cursos dela.

    Os cursos vêm aqui porque a etiqueta de um post restrito precisa do **nome** do
    curso, e não só do id. Não é desperdício tão grande quanto parece: um post
    restrito a curso só é visível a quem tem vínculo naquele curso, então o nome a
    exibir é sempre de um curso desta mesma universidade.
    """

    id: UUID
    nome: str
    sigla: str
    foto_url: str | None = Field(default=None, alias="fotoUrl")
    cursos: list[Curso] = Field(default_factory=list)

    model_config = {"populate_by_name": True}

    def curso(self, curso_id: UUID | None) -> Curso | None:
        if curso_id is None:
            return None
        return next((c for c in self.cursos if c.id == curso_id), None)

    def tem_curso(self, curso_id: UUID) -> bool:
        """Se o curso é desta instituição.

        Existe como método para a rota não comparar listas à mão — e para o nome
        dizer o que a checagem significa: um post restrito a curso de outra
        faculdade não é "não encontrado", é campo errado.
        """
        return any(c.id == curso_id for c in self.cursos)


class UniversidadeDaConta(ResumoDeUniversidade):
    """O resumo mais a única coisa que só a publicação precisa: se a conta age.

    `conta_ativa` vem do banco do user-service, não de um claim: uma conta
    desativada com token válido seguiria publicando por até 15 minutos.
    """

    conta_ativa: bool = Field(alias="contaAtiva")


class ResumoDeAutor(BaseModel):
    """Quem comentou: nome, arroba e foto, e nada além."""

    id: UUID
    nome_completo: str = Field(alias="nomeCompleto")
    username: str
    foto_url: str | None = Field(default=None, alias="fotoUrl")

    model_config = {"populate_by_name": True}


def _indisponivel() -> AppError:
    """Mensagem única para timeout, conexão recusada e 5xx do user-service.

    Para quem está na tela a ação é a mesma — tentar de novo —, e distinguir os
    casos só serviria a quem estivesse mapeando a topologia interna.
    """
    return AppError(
        code="dependencia_indisponivel",
        message="Não foi possível carregar os dados agora. Tente novamente em instantes.",
        status_code=503,
    )


async def _pedir(caminho: str, params: dict | None = None) -> object:
    """Uma chamada interna ao user-service, com o segredo de serviço no cabeçalho.

    Cada chamada abre e fecha o próprio cliente, como no auth-service. Um cliente
    global economizaria o handshake, mas guardaria um pool preso ao event loop em
    que nasceu — a mesma classe de problema que fez o conftest criar um engine por
    teste.
    """
    try:
        async with httpx.AsyncClient(
            base_url=settings.user_service_url, timeout=_TEMPO_LIMITE
        ) as cliente:
            resposta = await cliente.get(
                caminho,
                params=params,
                headers={"X-Servico-Token": settings.servico_token},
            )
    except httpx.HTTPError as erro:
        raise _indisponivel() from erro

    if resposta.status_code == 200:
        return resposta.json()

    # 403 com `sem_instituicao` é caso de negócio, não de infraestrutura: é a
    # conta `faculdade` que não administra universidade nenhuma. Repassar o código
    # do user-service mantém a mensagem exata em vez de traduzi-la para um 503
    # que mandaria o usuário "tentar de novo" num erro que não passa com o tempo.
    try:
        corpo = resposta.json()
    except ValueError:
        corpo = {}

    if resposta.status_code in (403, 404):
        raise AppError(
            code=corpo.get("code", "permissao_negada"),
            message=corpo.get("message", "Sua conta não tem permissão para esta ação"),
            status_code=resposta.status_code,
        )

    raise _indisponivel()


async def universidade_da_conta(conta_id: UUID) -> UniversidadeDaConta:
    """A instituição que esta conta `faculdade` administra, com cursos e ativação."""
    dados = await _pedir(f"/universidades/interno/de-conta/{conta_id}")
    return UniversidadeDaConta.model_validate(dados)


async def universidades_do_escopo(usuario_id: UUID) -> list[UUID]:
    """Vínculo + seguidas. O conjunto de instituições do escopo `geral`.

    Vazio é estado normal: é o de quem acabou de entrar e ainda não seguiu nem
    informou CPF em nenhuma instituição. A tela mostra o convite, não um erro.
    """
    dados = await _pedir(f"/users/interno/{usuario_id}/seguindo/universidades")
    return [UUID(str(i)) for i in dados]  # type: ignore[union-attr]


async def resumos_de_universidades(ids: set[UUID]) -> dict[UUID, ResumoDeUniversidade]:
    """Cabeçalhos de card, em lote, indexados por id.

    Devolve dicionário porque quem chama precisa casar cada post com a sua
    instituição, e um `for` aninhado sobre lista faria isso em O(n²) por página.
    """
    if not ids:
        return {}
    dados = await _pedir("/universidades/interno/resumos", {"ids": [str(i) for i in ids]})
    resumos = [ResumoDeUniversidade.model_validate(d) for d in dados]  # type: ignore[union-attr]
    return {r.id: r for r in resumos}


async def resumos_de_autores(ids: set[UUID]) -> dict[UUID, ResumoDeAutor]:
    """Autores de comentário, em lote, indexados por id."""
    if not ids:
        return {}
    dados = await _pedir("/users/interno/resumos", {"ids": [str(i) for i in ids]})
    resumos = [ResumoDeAutor.model_validate(d) for d in dados]  # type: ignore[union-attr]
    return {r.id: r for r in resumos}
