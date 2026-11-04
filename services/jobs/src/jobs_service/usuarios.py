"""O que o jobs-service pergunta ao user-service.

Três coisas, e nada mais:

1. **A ativação da conta que publica.** Uma por publicação. Vem do banco, não de um
   claim — no JWT, uma empresa desativada seguiria publicando por até 15 minutos.
2. **Nome, arroba e foto** de empresas e candidatos, em lote, para montar os cards.
3. **Quem o leitor segue.** Uma por página da área de vagas. É curadoria, não
   permissão: a lista errada faz a área mostrar vaga a mais ou a menos, e não há
   conteúdo restrito para escapar — vaga é legível por qualquer conta autenticada.

Não passa por aqui **nada sobre o candidato além do resumo**. É a decisão registrada
no contrato: a empresa vê de quem se candidatou o mesmo que qualquer card mostra, e
abre o perfil público no app se quiser o resto. A candidatura não pode virar um canal
para CPF e telefone, e a garantia é o tipo de saída não ter os campos.
"""

from uuid import UUID

from pydantic import BaseModel, Field

from integra_shared import interno
from integra_shared.interno import ResumoDePerfil
from jobs_service.settings import settings


class Ativacao(BaseModel):
    """Se a conta pode publicar, e o tipo dela."""

    ativa: bool
    tipo: str


class _EscopoDoFeed(BaseModel):
    """A resposta de `escopo-do-feed`, da qual este serviço usa **uma** metade.

    `universidades` é o ramo de recomendação do feed de posts, e não tem equivalente
    aqui: vaga é de empresa, e empresa não tem vínculo com universidade nenhuma. O
    campo é ignorado em vez de a rota interna ser duplicada numa versão enxuta — uma
    segunda definição de "quem o leitor segue" é como as duas divergiriam.
    """

    seguidos: list[UUID] = Field(default_factory=list)

    model_config = {"populate_by_name": True}


async def _pedir(caminho: str, params: dict | None = None) -> object:
    return await interno.pedir(settings.user_service_url, settings.servico_token, caminho, params)


async def ativacao(usuario_id: UUID) -> Ativacao:
    """Se esta conta pode publicar vaga. Consultado no banco, a cada publicação."""
    return Ativacao.model_validate(await _pedir(f"/users/interno/{usuario_id}/ativacao"))


async def seguidos(usuario_id: UUID) -> list[UUID]:
    """As contas que este leitor segue. A área de vagas lista só as delas."""
    dados = await _pedir(f"/users/interno/{usuario_id}/escopo-do-feed")
    return _EscopoDoFeed.model_validate(dados).seguidos


async def resumos(ids: set[UUID]) -> dict[UUID, ResumoDePerfil]:
    """Cabeçalhos de card — empresas e candidatos —, em lote, indexados por id.

    Um lote só para os dois papéis: uma página de candidaturas referencia empresas e
    pessoas, e a rota interna do user-service não distingue — são todas contas.
    Separar em duas chamadas dobraria as idas de rede para filtrar por um tipo que a
    resposta não usa.
    """
    return await interno.resumos_de_perfis(settings.user_service_url, settings.servico_token, ids)
