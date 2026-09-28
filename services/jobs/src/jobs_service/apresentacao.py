"""Montagem das respostas: junta o banco com o que está no user-service.

Fora de `services/` de propósito, como nos outros dois serviços: `services/` fala só
com o banco e é testável com uma sessão; isto fala HTTP.

Duas coisas específicas deste serviço:

**`candidaturaEnviada` é nula para quem não é `aluno`.** A consulta devolve `false`
para todo mundo — ela não sabe o tipo da conta —, e a conversão para nulo acontece
aqui. `false` numa vaga vista pela própria empresa a faria parecer elegível a se
candidatar.

**Uma página de candidaturas resolve dois papéis num lote.** Cada item referencia uma
empresa (dona da vaga) e um candidato, e a rota interna do user-service não distingue:
são todas contas. Os dois conjuntos de ids entram na mesma chamada.
"""


from integra_shared.interno import ResumoDePerfil
from integra_shared.security import UsuarioAutenticado
from jobs_service import usuarios
from jobs_service.schemas import (
    CandidatoResumoOut,
    CandidaturaOut,
    EmpresaDaVagaOut,
    VagaOut,
)
from jobs_service.services.candidaturas import LinhaDeCandidatura
from jobs_service.services.candidaturas import (
    nao_encontrada as candidatura_nao_encontrada,
)
from jobs_service.services.vagas import LinhaDeVaga, nao_encontrada


def _montar_vaga(
    linha: LinhaDeVaga,
    usuario: UsuarioAutenticado,
    empresa: ResumoDePerfil,
) -> VagaOut:
    vaga, total, candidatou = linha
    return VagaOut(
        id=vaga.id,
        empresa=EmpresaDaVagaOut(
            id=empresa.id,
            nome=empresa.nome_completo,
            username=empresa.username,
            foto_url=empresa.foto_url,
        ),
        titulo=vaga.titulo,
        descricao=vaga.descricao,
        tipo=vaga.tipo,
        modalidade=vaga.modalidade,
        local=vaga.local,
        estado=vaga.estado,
        total_de_candidaturas=total,
        # Nulo para quem não é aluno — ver a nota no módulo.
        candidatura_enviada=candidatou if usuario.tipo == "aluno" else None,
        pode_editar=vaga.empresa_id == usuario.id,
        criado_em=vaga.criado_em,
        editado_em=vaga.editado_em,
    )


async def montar_vagas(linhas: list[LinhaDeVaga], usuario: UsuarioAutenticado) -> list[VagaOut]:
    """Converte linhas em `VagaOut`, resolvendo as empresas em lote.

    Uma vaga cuja empresa não resolve fica **fora** da resposta, em vez de derrubá-la:
    sem FK entre schemas, a linha órfã é um estado possível, e um 500 por conta apagada
    do outro lado seria uma listagem inteira perdida por causa de um registro.
    """
    if not linhas:
        return []

    empresas = await usuarios.resumos({vaga.empresa_id for vaga, *_ in linhas})

    saida: list[VagaOut] = []
    for linha in linhas:
        empresa = empresas.get(linha[0].empresa_id)
        if empresa is None:
            continue
        saida.append(_montar_vaga(linha, usuario, empresa))
    return saida


async def montar_vaga(linha: LinhaDeVaga, usuario: UsuarioAutenticado) -> VagaOut:
    """Uma vaga só. Levanta 404 se a empresa não resolver.

    Diferente da listagem: aqui o cliente pediu **esta** vaga, e um 404 por conta
    apagada é mais honesto que devolver a vaga sem cabeçalho.
    """
    montadas = await montar_vagas([linha], usuario)
    if not montadas:
        raise nao_encontrada()
    return montadas[0]


async def montar_candidaturas(
    linhas: list[LinhaDeCandidatura],
    usuario: UsuarioAutenticado,
) -> list[CandidaturaOut]:
    """Converte candidaturas, resolvendo empresas e candidatos **no mesmo lote**.

    O total de candidaturas da vaga vem na linha, calculado pela consulta: um número
    que a resposta declara e não é verdade é pior que um número ausente, e o campo é
    obrigatório no contrato.

    `candidaturaEnviada` da vaga aninhada sai `True` quando o leitor é o candidato
    daquela linha, que é a resposta certa e sai de graça — na lista do aluno é sempre
    ele, e na lista da empresa o campo é nulo porque ela não é `aluno`.
    """
    if not linhas:
        return []

    ids = {c.candidato_id for c, _ in linhas} | {c.vaga.empresa_id for c, _ in linhas}
    perfis = await usuarios.resumos(ids)

    saida: list[CandidaturaOut] = []
    for candidatura, total in linhas:
        empresa = perfis.get(candidatura.vaga.empresa_id)
        candidato = perfis.get(candidatura.candidato_id)
        if empresa is None or candidato is None:
            continue

        saida.append(
            CandidaturaOut(
                id=candidatura.id,
                vaga=_montar_vaga(
                    (candidatura.vaga, total, candidatura.candidato_id == usuario.id),
                    usuario,
                    empresa,
                ),
                candidato=CandidatoResumoOut(
                    id=candidato.id,
                    nome_completo=candidato.nome_completo,
                    username=candidato.username,
                    foto_url=candidato.foto_url,
                ),
                estado=candidatura.estado,
                criado_em=candidatura.criado_em,
                visualizada_em=candidatura.visualizada_em,
            )
        )

    return saida


async def montar_candidatura(
    linha: LinhaDeCandidatura, usuario: UsuarioAutenticado
) -> CandidaturaOut:
    """Uma candidatura só. Levanta 404 se um dos dois perfis não resolver."""
    montadas = await montar_candidaturas([linha], usuario)
    if not montadas:
        raise candidatura_nao_encontrada()
    return montadas[0]
