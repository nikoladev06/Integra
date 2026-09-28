"""Publicar, listar, ler e editar vagas.

Duas decisões atravessam o arquivo:

**Leitura é aberta; escrita é da empresa autora.** Qualquer conta autenticada lê
qualquer vaga, inclusive fechada — quem se candidatou precisa poder abrir a vaga que
aparece em "minhas candidaturas". O que a empresa autora tem de exclusivo é editar,
encerrar, e ver quem se candidatou.

**"Não é sua" responde 404, não 403.** Um 403 confirmaria que existe uma vaga com
aquele id publicada por outra empresa — e, na rota de candidaturas, que ela tem
candidatos. Mesma disciplina das duas recusas do "inserir CPF" no user-service.
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import Select, and_, func, literal, select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

from integra_shared import paginacao
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado
from jobs_service.models import (
    Candidatura,
    EstadoDaVaga,
    Modalidade,
    TipoDeVaga,
    Vaga,
)
from jobs_service.schemas import EditarVagaIn, PublicarVagaIn

# Uma linha da listagem: a vaga, o total de candidaturas, e se ESTE leitor já se
# candidatou. Os dois últimos dependem de quem lê, e por isso vivem na consulta.
LinhaDeVaga = tuple[Vaga, int, bool]


def nao_encontrada() -> AppError:
    """Vaga inexistente — ou de outra empresa, nas rotas que exigem ser a autora."""
    return AppError(code="nao_encontrado", message="Vaga não encontrada", status_code=404)


def _campo_invalido(campo: str, mensagem: str) -> AppError:
    """422 nomeando o campo, para o formulário destacar a linha certa.

    O Pydantic não dá conta destas: elas cruzam dois campos (`modalidade` e `local`)
    ou dependem do que já está gravado na vaga.
    """
    return AppError(
        code="validation_error",
        message="Verifique os campos destacados",
        status_code=422,
        fields={campo: [mensagem]},
    )


def _conferir_local(modalidade: Modalidade, local: str | None) -> None:
    """A invariante do local, na publicação e na edição.

    Uma função, porque as duas rotas precisam da mesma checagem — e porque o
    `CheckConstraint` do banco recusaria a linha de qualquer jeito: melhor um 422 com
    o campo nomeado do que o Postgres devolvendo 500.

    Recusar o `local` sobrando, em vez de ignorá-lo, é o ponto: aceito em silêncio
    numa vaga remota, ele pareceria uma restrição geográfica que não existe — e o
    candidato descartaria a vaga por causa dela.
    """
    if modalidade == Modalidade.REMOTO:
        if local is not None:
            raise _campo_invalido("local", "Vaga remota não leva local")
        return
    if local is None:
        raise _campo_invalido("local", "Informe a cidade da vaga")


async def publicar(
    sessao: AsyncSession,
    empresa_id: UUID,
    dados: PublicarVagaIn,
) -> Vaga:
    """Publica em nome da conta autenticada. `empresa_id` não é campo do corpo."""
    _conferir_local(dados.modalidade, dados.local_limpo)

    vaga = Vaga(
        empresa_id=empresa_id,
        titulo=dados.titulo.strip(),
        descricao=dados.descricao.strip(),
        tipo=dados.tipo,
        modalidade=dados.modalidade,
        local=dados.local_limpo,
    )
    sessao.add(vaga)
    await sessao.flush()
    await sessao.refresh(vaga)
    return vaga


async def editar(
    sessao: AsyncSession,
    vaga_id: UUID,
    usuario: UsuarioAutenticado,
    dados: EditarVagaIn,
) -> Vaga:
    """Edita ou encerra uma vaga da própria empresa.

    As invariantes da publicação continuam valendo, e a edição não pode produzir um
    estado que a publicação recusaria:

    - passar a `remoto` **limpa** o local, em vez de deixar um endereço órfão;
    - sair de `remoto` exige um local, informado agora ou já presente na vaga.

    Encerrar é `estado: fechada`, e reabrir é `estado: aberta` — reabrir não recria
    candidatura nenhuma, porque nenhuma saiu.
    """
    if dados.vazio:
        raise _campo_invalido("_", "Informe ao menos um campo para alterar")

    vaga = await _obter_da_empresa(sessao, vaga_id, usuario)

    modalidade = dados.modalidade or vaga.modalidade

    if modalidade == Modalidade.REMOTO:
        # Passar a remoto limpa a restrição, em vez de deixar uma órfã no registro.
        local = None
    else:
        # O que falta pode estar na vaga gravada: sair de `remoto` sem informar
        # `local` é válido se a vaga já tinha um.
        local = dados.local_limpo if dados.local_limpo is not None else vaga.local

    _conferir_local(modalidade, local)

    if dados.titulo is not None:
        vaga.titulo = dados.titulo.strip()
    if dados.descricao is not None:
        vaga.descricao = dados.descricao.strip()
    if dados.tipo is not None:
        vaga.tipo = dados.tipo
    if dados.estado is not None:
        vaga.estado = dados.estado
    vaga.modalidade = modalidade
    vaga.local = local
    vaga.editado_em = datetime.now(UTC)

    await sessao.flush()
    await sessao.refresh(vaga)
    return vaga


async def _obter_da_empresa(
    sessao: AsyncSession, vaga_id: UUID, usuario: UsuarioAutenticado
) -> Vaga:
    """A vaga, se existir e se for desta conta. Caso contrário, 404."""
    vaga = await sessao.get(Vaga, vaga_id)
    if vaga is None or vaga.empresa_id != usuario.id:
        raise nao_encontrada()
    return vaga


async def obter_da_empresa(
    sessao: AsyncSession, vaga_id: UUID, usuario: UsuarioAutenticado
) -> Vaga:
    """O portão da lista de candidaturas recebidas.

    Exposta com nome público porque a rota de candidaturas precisa do mesmo portão, e
    duplicá-lo lá seria a forma de a próxima rota esquecer a metade "e é sua".
    """
    return await _obter_da_empresa(sessao, vaga_id, usuario)


# ─────────────────────────────  leitura  ─────────────────────────────


def _consulta_de_leitura(usuario: UsuarioAutenticado) -> Select:
    """Vaga + o total de candidaturas + se este leitor já se candidatou.

    `candidatou` é uma subconsulta correlacionada e não um `JOIN`: com o `JOIN`, uma
    vaga com 30 candidatos viria 30 vezes, e o total sairia contando as duplicatas.

    Para quem não é `aluno` a subconsulta ainda roda e devolve `false` — a rota é que
    converte para nulo na saída, porque "não se aplica" é diferente de "não". Emitir
    a consulta condicionalmente por tipo de conta faria a coluna existir ou não
    dependendo de quem chama, e o `.first()` do chamador mudaria de forma.
    """
    candidaturas = (
        select(func.count())
        .select_from(Candidatura)
        .where(Candidatura.vaga_id == Vaga.id)
        .scalar_subquery()
    )
    candidatou = (
        select(literal(1))
        .where(and_(Candidatura.vaga_id == Vaga.id, Candidatura.candidato_id == usuario.id))
        .exists()
    )

    return select(Vaga, candidaturas, candidatou).order_by(Vaga.criado_em.desc(), Vaga.id.desc())


async def obter(sessao: AsyncSession, vaga_id: UUID, usuario: UsuarioAutenticado) -> LinhaDeVaga:
    """Uma vaga por id. Legível por qualquer conta autenticada, **inclusive fechada**.

    Esconder a fechada faria "minhas candidaturas" apontar para 404 — o aluno perderia
    o acesso à vaga a que se candidatou no instante em que a empresa encerra o
    processo.
    """
    linha = (await sessao.execute(_consulta_de_leitura(usuario).where(Vaga.id == vaga_id))).first()
    if linha is None:
        raise nao_encontrada()
    return (linha[0], linha[1], linha[2])


async def listar(
    sessao: AsyncSession,
    usuario: UsuarioAutenticado,
    limite: int,
    cursor: str | None,
    *,
    empresa_id: UUID | None = None,
    tipo: TipoDeVaga | None = None,
    modalidade: Modalidade | None = None,
    estado: EstadoDaVaga = EstadoDaVaga.ABERTA,
) -> tuple[list[LinhaDeVaga], str | None]:
    """Uma página de vagas, da mais recente para a mais antiga.

    `estado` tem default `aberta` no **serviço**, e não só no schema da rota: uma
    chamada interna que esqueça o parâmetro lista as abertas, e não as fechadas junto.
    Uma listagem que mistura as duas é pior que uma lista curta — o aluno se candidata
    e recebe 409.
    """
    consulta = _consulta_de_leitura(usuario).where(Vaga.estado == estado)

    if empresa_id is not None:
        consulta = consulta.where(Vaga.empresa_id == empresa_id)
    if tipo is not None:
        consulta = consulta.where(Vaga.tipo == tipo)
    if modalidade is not None:
        consulta = consulta.where(Vaga.modalidade == modalidade)

    limite = paginacao.limite_valido(limite)

    if cursor:
        data, id_ = paginacao.decodificar(cursor)
        consulta = consulta.where(tuple_(Vaga.criado_em, Vaga.id) < tuple_(data, id_))

    resultado = (await sessao.execute(consulta.limit(limite + 1))).all()

    tem_mais = len(resultado) > limite
    linhas: list[LinhaDeVaga] = [
        (linha[0], linha[1], linha[2]) for linha in resultado[:limite]
    ]
    proximo = None
    if tem_mais and linhas:
        ultima = linhas[-1][0]
        proximo = paginacao.codificar(ultima.criado_em, ultima.id)

    return linhas, proximo
