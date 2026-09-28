"""O que o jobs-service pergunta ao user-service.

Duas coisas, e nada mais:

1. **A ativação da conta que publica.** Uma por publicação. Vem do banco, não de um
   claim — no JWT, uma empresa desativada seguiria publicando por até 15 minutos.
2. **Nome, arroba e foto** de empresas e candidatos, em lote, para montar os cards.

Não passa por aqui **nada sobre o candidato além do resumo**. É a decisão registrada
no contrato: a empresa vê de quem se candidatou o mesmo que qualquer card mostra, e
abre o perfil público no app se quiser o resto. A candidatura não pode virar um canal
para CPF e telefone, e a garantia é o tipo de saída não ter os campos.
"""

from uuid import UUID

from pydantic import BaseModel

from integra_shared import interno
from integra_shared.interno import ResumoDePerfil
from jobs_service.settings import settings


class Ativacao(BaseModel):
    """Se a conta pode publicar, e o tipo dela."""

    ativa: bool
    tipo: str


async def _pedir(caminho: str, params: dict | None = None) -> object:
    return await interno.pedir(settings.user_service_url, settings.servico_token, caminho, params)


async def ativacao(usuario_id: UUID) -> Ativacao:
    """Se esta conta pode publicar vaga. Consultado no banco, a cada publicação."""
    return Ativacao.model_validate(await _pedir(f"/users/interno/{usuario_id}/ativacao"))


async def resumos(ids: set[UUID]) -> dict[UUID, ResumoDePerfil]:
    """Cabeçalhos de card — empresas e candidatos —, em lote, indexados por id.

    Um lote só para os dois papéis: uma página de candidaturas referencia empresas e
    pessoas, e a rota interna do user-service não distingue — são todas contas.
    Separar em duas chamadas dobraria as idas de rede para filtrar por um tipo que a
    resposta não usa.
    """
    return await interno.resumos_de_perfis(settings.user_service_url, settings.servico_token, ids)
