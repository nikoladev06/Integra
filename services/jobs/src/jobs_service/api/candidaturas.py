"""Rotas de candidatura.

A ordem de registro neste módulo **importa**: `/jobs/candidaturas/me` tem que vir
antes de `/jobs/candidaturas/{candidaturaId}`. Os dois caminhos têm três segmentos,
então a parametrizada capturaria "me" como identificador e o FastAPI responderia 422 ao
validar o UUID — sem nunca chegar à rota certa. É o mesmo cuidado que
`/users/interno/resumos` exigiu no user-service.
"""

from uuid import UUID

from fastapi import APIRouter, Query, Response

from integra_shared.paginacao import LIMITE_MAXIMO, LIMITE_PADRAO
from jobs_service import apresentacao
from jobs_service.api.deps import AlunoDep, SessaoDep, UsuarioDep
from jobs_service.schemas import (
    CandidaturaOut,
    EditarCandidaturaIn,
    PaginaDeCandidaturas,
)
from jobs_service.services import candidaturas

router = APIRouter(prefix="/jobs", tags=["candidaturas"])


@router.get("/vagas/{vagaId}/candidaturas", response_model=PaginaDeCandidaturas)
async def da_vaga(
    vagaId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
    limit: int = Query(default=LIMITE_PADRAO, ge=1, le=LIMITE_MAXIMO),
    cursor: str | None = None,
) -> PaginaDeCandidaturas:
    """As candidaturas recebidas. Só a empresa autora da vaga.

    Qualquer outra conta recebe **404**, e não 403: um 403 confirmaria que existe uma
    vaga com aquele id e que ela tem candidatos.

    Sem `EmpresaDep`: o portão aqui é ser a autora **daquela vaga**, que é mais estreito
    que ser uma empresa ativa — e é o que `services.candidaturas.listar_da_vaga`
    confere. Exigir `EmpresaDep` também recusaria a empresa que ficou pendente depois de
    publicar, e ela não perde o direito de ver quem se candidatou ao que já está no ar.

    **Listar não marca como visualizada.** A transição é um `PATCH` explícito: um `GET`
    que muda estado é disparado pelo pre-fetch de qualquer cliente sem ninguém ter
    aberto nada.
    """
    linhas, proximo = await candidaturas.listar_da_vaga(sessao, vagaId, usuario, limit, cursor)
    return PaginaDeCandidaturas(
        itens=await apresentacao.montar_candidaturas(linhas, usuario),
        proximo_cursor=proximo,
    )


@router.post(
    "/vagas/{vagaId}/candidaturas",
    response_model=CandidaturaOut,
    status_code=201,
    # O contrato declara 200 além do 201 — a candidatura que já existia. Sem isto o
    # OpenAPI gerado teria só o 201, e a guarda de deriva compara caminhos, não
    # respostas: o cliente Flutter é que descobriria a diferença.
    responses={200: {"description": "Já havia candidatura — devolve a existente"}},
)
async def candidatar(
    vagaId: UUID,
    resposta: Response,
    sessao: SessaoDep,
    aluno: AlunoDep,
) -> CandidaturaOut:
    """Candidata o aluno autenticado. Idempotente.

    201 quando cria, 200 quando já existia — e a diferença não é cosmética: a tela
    mostra "candidatura enviada" no primeiro caso e nada no segundo, porque avisar duas
    vezes faz o usuário achar que se candidatou duas vezes.

    Vaga fechada recusa com 409 e código próprio. Quem **já** se candidatou continua
    recebendo a própria candidatura mesmo depois de a vaga fechar: recusar aí faria a
    tela dele perder o item ao recarregar.
    """
    candidatura, criada = await candidaturas.candidatar(sessao, vagaId, aluno)
    if not criada:
        resposta.status_code = 200

    total = await candidaturas.total_da_vaga(sessao, candidatura.vaga_id)
    return await apresentacao.montar_candidatura((candidatura, total), aluno)


@router.get("/candidaturas/me", response_model=PaginaDeCandidaturas)
async def minhas(
    sessao: SessaoDep,
    usuario: UsuarioDep,
    limit: int = Query(default=LIMITE_PADRAO, ge=1, le=LIMITE_MAXIMO),
    cursor: str | None = None,
) -> PaginaDeCandidaturas:
    """A aba do aluno. Cada item traz a vaga inteira, e não só o id.

    Sem `AlunoDep`: uma conta `empresa` que chame isto recebe lista vazia, que é a
    verdade — ela não se candidatou a nada. Um 403 aqui seria dizer "você não pode
    perguntar" sobre uma pergunta cuja resposta é "nada".
    """
    linhas, proximo = await candidaturas.listar_do_candidato(sessao, usuario, limit, cursor)
    return PaginaDeCandidaturas(
        itens=await apresentacao.montar_candidaturas(linhas, usuario),
        proximo_cursor=proximo,
    )


@router.patch("/candidaturas/{candidaturaId}", response_model=CandidaturaOut)
async def marcar_visualizada(
    candidaturaId: UUID,
    dados: EditarCandidaturaIn,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> CandidaturaOut:
    """Marca como visualizada. Só a empresa autora da vaga.

    O corpo é validado pelo **tipo**: `estado` é `Literal["visualizada"]`, então qualquer
    outro valor é recusado pelo Pydantic com o campo nomeado, antes de a rota rodar. Não
    há o que ler dele aqui — o estado de destino é único, e um `if` comparando com a
    única opção possível seria código que nunca toma o outro ramo.

    Sem `EmpresaDep`, pelo mesmo motivo de `da_vaga`: o portão é ser autora **daquela
    vaga**, que é mais estreito que ser uma empresa ativa. Uma empresa que ficou pendente
    depois de publicar não perde o direito de acompanhar quem se candidatou ao que já
    está no ar.

    Marcar de novo é idempotente e **não** move `visualizadaEm`: a data é a da primeira
    vez, que é o que o aluno lê como "foi vista".
    """
    candidatura = await candidaturas.marcar_visualizada(sessao, candidaturaId, usuario)
    total = await candidaturas.total_da_vaga(sessao, candidatura.vaga_id)
    return await apresentacao.montar_candidatura((candidatura, total), usuario)
