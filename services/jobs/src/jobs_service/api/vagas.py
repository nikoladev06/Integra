"""Rotas de vaga: listagem com filtros, detalhe, publicação e edição."""

from uuid import UUID

from fastapi import APIRouter, Query

from integra_shared.paginacao import LIMITE_MAXIMO, LIMITE_PADRAO
from jobs_service import apresentacao
from jobs_service.api.deps import EmpresaDep, SessaoDep, UsuarioDep
from jobs_service.models import EstadoDaVaga, Modalidade, TipoDeVaga
from jobs_service.schemas import EditarVagaIn, PaginaDeVagas, PublicarVagaIn, VagaOut
from jobs_service.services import vagas

router = APIRouter(prefix="/jobs", tags=["vagas"])


@router.get("/vagas", response_model=PaginaDeVagas)
async def listar(
    sessao: SessaoDep,
    usuario: UsuarioDep,
    empresaId: UUID | None = None,
    tipo: TipoDeVaga | None = None,
    modalidade: Modalidade | None = None,
    estado: EstadoDaVaga = EstadoDaVaga.ABERTA,
    limit: int = Query(default=LIMITE_PADRAO, ge=1, le=LIMITE_MAXIMO),
    cursor: str | None = None,
) -> PaginaDeVagas:
    """A área de vagas, e a aba de vagas do perfil de uma empresa (`empresaId`).

    Abertas por padrão. `estado=fechada` existe para a empresa ver o que publicou e
    encerrou — e não é filtro de autorização: qualquer conta pode pedir as fechadas de
    qualquer empresa, porque uma vaga fechada não é conteúdo restrito, só conteúdo
    velho.

    `candidaturaEnviada` vem preenchido em cada item, para o botão da lista já nascer no
    estado certo. Sem ele a tela mostraria "candidatar-se" em vagas a que o aluno já se
    candidatou, e descobriria o contrário só no toque.
    """
    linhas, proximo = await vagas.listar(
        sessao,
        usuario,
        limit,
        cursor,
        empresa_id=empresaId,
        tipo=tipo,
        modalidade=modalidade,
        estado=estado,
    )
    return PaginaDeVagas(
        itens=await apresentacao.montar_vagas(linhas, usuario),
        proximo_cursor=proximo,
    )


@router.post("/vagas", response_model=VagaOut, status_code=201)
async def publicar(dados: PublicarVagaIn, sessao: SessaoDep, empresa: EmpresaDep) -> VagaOut:
    """Publica em nome da conta autenticada.

    `EmpresaDep` é o portão: conta `empresa` e ativada. `empresaId` **não** é campo do
    corpo — se fosse, uma empresa publicaria vaga no nome de outra.

    `local` é obrigatório fora de `remoto` e recusado em `remoto`. Recusar em vez de
    ignorar é o ponto: aceito em silêncio numa vaga remota, ele pareceria uma restrição
    geográfica que não existe, e o candidato descartaria a vaga por causa dela.
    """
    vaga = await vagas.publicar(sessao, empresa.id, dados)
    return await apresentacao.montar_vaga((vaga, 0, False), empresa)


@router.get("/vagas/{vagaId}", response_model=VagaOut)
async def detalhe(vagaId: UUID, sessao: SessaoDep, usuario: UsuarioDep) -> VagaOut:
    """Legível por qualquer conta autenticada, **inclusive fechada**.

    Esconder a fechada faria "minhas candidaturas" apontar para 404 — o aluno perderia
    o acesso à vaga a que se candidatou no instante em que a empresa encerra o processo.
    """
    linha = await vagas.obter(sessao, vagaId, usuario)
    return await apresentacao.montar_vaga(linha, usuario)


@router.patch("/vagas/{vagaId}", response_model=VagaOut)
async def editar(
    vagaId: UUID,
    dados: EditarVagaIn,
    sessao: SessaoDep,
    empresa: EmpresaDep,
) -> VagaOut:
    """Edita ou encerra uma vaga da própria empresa.

    **Encerrar é `estado: fechada`**, e não um `DELETE`: as candidaturas recebidas
    continuam existindo, e os dois lados continuam vendo o histórico. Reabrir não
    recria candidatura nenhuma, porque nenhuma saiu.
    """
    vaga = await vagas.editar(sessao, vagaId, empresa, dados)
    linha = await vagas.obter(sessao, vaga.id, empresa)
    return await apresentacao.montar_vaga(linha, empresa)
