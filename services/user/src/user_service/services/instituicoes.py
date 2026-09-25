"""A administração que cada instituição faz de si: cursos e matrículas."""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from integra_shared.cnpj import CnpjInvalido
from integra_shared.cnpj import validar as validar_cnpj
from integra_shared.cpf import CpfInvalido
from integra_shared.cpf import validar as validar_cpf
from integra_shared.errors import AppError
from user_service.models import (
    Curso,
    Formacao,
    Matricula,
    TipoConta,
    Universidade,
    Usuario,
    Vinculo,
)
from user_service.schemas import CriarInstituicaoIn
from user_service.services import vinculos


async def criar_conta(sessao: AsyncSession, dados: CriarInstituicaoIn) -> Usuario:
    """Cria a conta institucional e, sendo faculdade, resolve a universidade.

    **A conta nasce pendente** (`ativada_em` nulo): ela entra e edita o perfil,
    mas não publica nem matricula. CNPJ é dado público — está no cadastro aberto
    da Receita — então o número identifica a organização e não prova que quem
    digitou a representa. Sem este estado, consultar o CNPJ de uma faculdade
    bastaria para distribuir formações "verificadas" no nome dela, e o selo
    deixaria de significar algo.

    Para `faculdade`, o CNPJ decide entre reivindicar e criar:

        CNPJ casa com universidade sem conta  ->  reivindica a linha existente
        CNPJ casa com universidade já tomada  ->  409
        CNPJ desconhecido                     ->  cria universidade nova

    Reivindicar, e não criar, é o que evita duas FATEC RP na busca — com os alunos
    que já seguiam presos na que não publica.
    """
    from user_service.services import perfis

    try:
        cnpj = validar_cnpj(dados.cnpj)
    except CnpjInvalido as erro:
        raise AppError(
            code="validation_error",
            message="Verifique os campos destacados",
            status_code=422,
            fields={"cnpj": [str(erro)]},
        ) from erro

    if await perfis.username_em_uso(sessao, dados.username, exceto=None):
        raise AppError(code="username_ja_existe", message="Username já existe", status_code=409)
    if await perfis.email_em_uso(sessao, dados.email):
        raise AppError(code="email_ja_cadastrado", message="Email já cadastrado", status_code=409)
    if await _cnpj_em_uso(sessao, cnpj):
        raise AppError(code="cnpj_ja_cadastrado", message="CNPJ já cadastrado", status_code=409)

    conta = Usuario(
        id=dados.id,
        nome_completo=dados.nome.strip(),
        email=dados.email.lower(),
        username=dados.username.lower(),
        cnpj=cnpj,
        cpf=None,
        telefone=dados.telefone,
        tipo=dados.tipo,
        ativada_em=None,
    )
    sessao.add(conta)
    await sessao.flush()

    if dados.tipo == TipoConta.FACULDADE:
        await _resolver_universidade(sessao, conta, cnpj, dados.sigla)

    await sessao.refresh(conta)
    return conta


async def _resolver_universidade(
    sessao: AsyncSession, conta: Usuario, cnpj: str, sigla: str | None
) -> Universidade:
    existente = (
        await sessao.execute(select(Universidade).where(Universidade.cnpj == cnpj))
    ).scalar_one_or_none()

    if existente is not None:
        if existente.conta_id is not None:
            raise AppError(
                code="universidade_ja_administrada",
                message="Esta instituição já tem uma conta cadastrada",
                status_code=409,
            )
        existente.conta_id = conta.id
        await sessao.flush()
        return existente

    nova = Universidade(
        nome=conta.nome_completo,
        # Sem sigla informada, as iniciais das palavras servem de rótulo curto até
        # a instituição editar o perfil — melhor que repetir o nome inteiro nos
        # lugares onde só cabe uma sigla.
        sigla=(sigla or _iniciais(conta.nome_completo))[:20],
        cnpj=cnpj,
        conta_id=conta.id,
    )
    sessao.add(nova)
    await sessao.flush()
    return nova


def _iniciais(nome: str) -> str:
    partes = [p for p in nome.split() if len(p) > 2]
    return "".join(p[0] for p in partes).upper() or nome[:8].upper()


async def ativar(sessao: AsyncSession, email: str) -> Usuario:
    """Libera os poderes de uma conta institucional pendente."""
    conta = (
        await sessao.execute(select(Usuario).where(Usuario.email == email.lower()))
    ).scalar_one_or_none()
    if conta is None:
        raise AppError(
            code="nao_encontrado",
            message=f"Sem conta com e-mail {email}",
            status_code=404,
        )
    if conta.tipo == TipoConta.ALUNO:
        raise AppError(
            code="conta_de_aluno",
            message="Contas de aluno já nascem ativas",
            status_code=409,
        )

    conta.ativada_em = datetime.now(UTC)
    await sessao.flush()
    return conta


async def _cnpj_em_uso(sessao: AsyncSession, cnpj: str) -> bool:
    total = (
        await sessao.execute(select(func.count()).select_from(Usuario).where(Usuario.cnpj == cnpj))
    ).scalar_one()
    return bool(total)


async def universidade_da_conta(sessao: AsyncSession, conta_id: UUID) -> Universidade:
    """A instituição que esta conta `faculdade` administra.

    O tipo da conta já foi conferido pela dependência de autorização. O que falta
    é o elo: uma conta `faculdade` sem universidade associada não tem o que
    administrar, e receber 403 aqui é mais honesto que um 500 adiante.
    """
    universidade = (
        await sessao.execute(select(Universidade).where(Universidade.conta_id == conta_id))
    ).scalar_one_or_none()

    if universidade is None:
        raise AppError(
            code="sem_instituicao",
            message="Esta conta não administra nenhuma instituição",
            status_code=403,
        )
    return universidade


# ──────────────────────────────  cursos  ──────────────────────────────


async def listar_cursos(sessao: AsyncSession, universidade_id: UUID) -> list[Curso]:
    resultado = await sessao.execute(
        select(Curso).where(Curso.universidade_id == universidade_id).order_by(Curso.nome)
    )
    return list(resultado.scalars())


async def criar_curso(sessao: AsyncSession, universidade_id: UUID, nome: str) -> Curso:
    nome = nome.strip()
    existente = (
        await sessao.execute(
            select(Curso).where(
                Curso.universidade_id == universidade_id,
                func.lower(Curso.nome) == nome.lower(),
            )
        )
    ).scalar_one_or_none()

    if existente is not None:
        raise AppError(
            code="curso_duplicado",
            message="Já existe um curso com este nome na instituição",
            status_code=409,
        )

    curso = Curso(universidade_id=universidade_id, nome=nome)
    sessao.add(curso)
    await sessao.flush()
    await sessao.refresh(curso)
    return curso


async def remover_curso(sessao: AsyncSession, universidade_id: UUID, curso_id: UUID) -> None:
    """Recusa se o curso estiver em uso.

    Apagar em cascata aqui removeria formação declarada de gente que não tem
    relação com a decisão administrativa da instituição — e formação verificada,
    que é justamente o que deve sobreviver a mudanças do lado da faculdade.
    """
    curso = (
        await sessao.execute(
            select(Curso).where(Curso.id == curso_id, Curso.universidade_id == universidade_id)
        )
    ).scalar_one_or_none()

    if curso is None:
        raise AppError(
            code="nao_encontrado",
            message="Curso não encontrado nesta instituição",
            status_code=404,
        )

    for modelo, rotulo in (
        (Matricula, "matrículas"),
        (Vinculo, "vínculos"),
        (Formacao, "formações"),
    ):
        total = (
            await sessao.execute(
                select(func.count()).select_from(modelo).where(modelo.curso_id == curso_id)
            )
        ).scalar_one()
        if total:
            raise AppError(
                code="curso_em_uso",
                message=f"Este curso tem {total} {rotulo} e não pode ser removido",
                status_code=409,
            )

    await sessao.delete(curso)
    await sessao.flush()


# ────────────────────────────  matrículas  ────────────────────────────


async def listar_matriculas(
    sessao: AsyncSession,
    universidade_id: UUID,
    *,
    curso_id: UUID | None = None,
    situacao: str = "todas",
) -> list[tuple[Matricula, Usuario | None]]:
    """Matrículas com o dono, quando já reivindicada.

    O `LEFT JOIN` é por CPF, não por chave estrangeira: a matrícula pode ter sido
    cadastrada antes de a conta existir, e é justamente esse o caso "pendente".
    """
    consulta = (
        select(Matricula, Usuario)
        .outerjoin(Usuario, Usuario.cpf == Matricula.cpf)
        .where(Matricula.universidade_id == universidade_id)
        .order_by(Matricula.criado_em.desc())
    )
    if curso_id:
        consulta = consulta.where(Matricula.curso_id == curso_id)

    linhas = [(m, u) for m, u in (await sessao.execute(consulta)).unique()]

    if situacao == "pendentes":
        return [(m, u) for m, u in linhas if u is None]
    if situacao == "vinculadas":
        return [(m, u) for m, u in linhas if u is not None]
    return linhas


async def criar_matricula(
    sessao: AsyncSession, universidade_id: UUID, cpf: str, curso_id: UUID
) -> Matricula:
    """Cadastra um aluno por CPF. **Pode acontecer antes de a conta existir.**"""
    try:
        digitos = validar_cpf(cpf)
    except CpfInvalido as erro:
        # Validado aqui também, e não só no cadastro do aluno: um CPF impossível
        # na lista nunca casaria com conta alguma, e o erro apareceria meses
        # depois como "o vínculo não funciona", sem pista de onde veio.
        raise AppError(
            code="validation_error",
            message="Verifique os campos destacados",
            status_code=422,
            fields={"cpf": [str(erro)]},
        ) from erro

    curso = (
        await sessao.execute(
            select(Curso).where(Curso.id == curso_id, Curso.universidade_id == universidade_id)
        )
    ).scalar_one_or_none()
    if curso is None:
        raise AppError(
            code="validation_error",
            message="Verifique os campos destacados",
            status_code=422,
            fields={"cursoId": ["Este curso não pertence à sua instituição"]},
        )

    existente = (
        await sessao.execute(
            select(Matricula).where(
                Matricula.universidade_id == universidade_id, Matricula.cpf == digitos
            )
        )
    ).scalar_one_or_none()
    if existente is not None:
        raise AppError(
            code="matricula_duplicada",
            message="Este CPF já está cadastrado na sua instituição",
            status_code=409,
        )

    matricula = Matricula(universidade_id=universidade_id, cpf=digitos, curso_id=curso_id)
    sessao.add(matricula)
    await sessao.flush()
    await sessao.refresh(matricula)
    return matricula


async def remover_matricula(
    sessao: AsyncSession, universidade_id: UUID, matricula_id: UUID
) -> None:
    """Remove a matrícula **e encerra o vínculo ativo**, se houver.

    O aluno volta a ver apenas os posts públicos. **A formação continua
    verificada:** o caso comum é ele ter se formado ou trancado, e ele realmente
    estudou lá.
    """
    matricula = (
        await sessao.execute(
            select(Matricula).where(
                Matricula.id == matricula_id,
                Matricula.universidade_id == universidade_id,
            )
        )
    ).scalar_one_or_none()

    if matricula is None:
        raise AppError(
            code="nao_encontrado",
            message="Matrícula não encontrada nesta instituição",
            status_code=404,
        )

    await vinculos.encerrar_por_instituicao(sessao, universidade_id, matricula.cpf)
    await sessao.delete(matricula)
    await sessao.flush()
