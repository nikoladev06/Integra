"""Rotas de vaga: listagem com filtros, detalhe, publicação e edição."""

from uuid import UUID

from fastapi import APIRouter, Query, Response

from integra_shared.paginacao import LIMITE_MAXIMO, LIMITE_PADRAO
from jobs_service import apresentacao, usuarios
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

    Abertas por padrão. **`estado=fechada` é da empresa autora**: pedir as fechadas de
    outra conta responde 403. Uma vaga encerrada não é conteúdo restrito, mas é
    histórico de quem a publicou — no perfil da empresa, para aluno e faculdade, ela
    só mostraria becos, e quem encerra é quem decide se mantém o registro à vista.

    Sem `empresaId`, a lista é a **área de vagas**: só das empresas que o leitor segue.
    Não seguindo nenhuma que tenha vaga, ela cai nas recomendadas — todas —, igual ao
    feed de posts de quem ainda não segue ninguém.

    `candidaturaEnviada` vem preenchido em cada item, para o botão da lista já nascer no
    estado certo. Sem ele a tela mostraria "candidatar-se" em vagas a que o aluno já se
    candidatou, e descobriria o contrário só no toque.
    """
    # Só na área de vagas: a aba do perfil de uma empresa pergunta "o que esta empresa
    # publicou", e seguir ou não não muda a resposta.
    seguidas = None
    if empresaId is None:
        # O próprio leitor entra sempre, como no ramo "seguindo" do feed: uma empresa
        # não precisa seguir a si mesma para ver as vagas que publicou.
        seguidas = [*await usuarios.seguidos(usuario.id), usuario.id]

    linhas, proximo = await vagas.listar(
        sessao,
        usuario,
        limit,
        cursor,
        empresa_id=empresaId,
        seguidas=seguidas,
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


@router.delete("/vagas/{vagaId}", status_code=204)
async def remover(vagaId: UUID, sessao: SessaoDep, empresa: EmpresaDep) -> Response:
    """Apaga uma vaga **encerrada** da própria empresa. As candidaturas vão junto.

    A exceção estreita à regra do `PATCH`: enquanto a vaga está aberta, apagar
    responde 409 — há processo em curso e gente esperando resposta, e encerrar existe
    para isso. Depois de encerrada, o registro é da empresa que o publicou.
    """
    await vagas.remover(sessao, vagaId, empresa)
    return Response(status_code=204)
