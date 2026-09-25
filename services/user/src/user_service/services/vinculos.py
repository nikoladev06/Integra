"""O vínculo institucional: criar, encerrar, e o que ele concede.

**É o único mecanismo que concede visibilidade de posts `institucional` e
`curso`.** Formação declarada não concede. Formação verificada antiga não
concede. Seguir não concede. Se alguma consulta em qualquer serviço passar a
conceder acesso por outra coisa, é aqui que a regra deveria ter sido lida.
"""

from datetime import UTC, datetime
from secrets import compare_digest
from uuid import UUID

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from integra_shared.cpf import normalizar as normalizar_cpf
from integra_shared.errors import AppError
from user_service.models import Formacao, Matricula, Universidade, Usuario, Vinculo
from user_service.services import perfis


def _recusado(status: int) -> AppError:
    """Mesma mensagem para CPF que não é da conta e para CPF fora da lista.

    O status difere (403 e 404) porque os dois casos são distintos para quem
    depura, mas o texto é único: o usuário não deve ficar sabendo, por diferença
    de mensagem, se um CPF consta na lista de uma instituição.

    Vale notar por que os status distintos **não** são uma sonda: só o CPF da
    própria conta chega ao segundo passo, então o 404 revela apenas se o CPF do
    próprio requerente está cadastrado ali — informação que ele tem direito de
    saber sobre si.
    """
    return AppError(
        code="vinculo_recusado",
        message="Não encontramos esse CPF na lista desta instituição",
        status_code=status,
    )


async def obter(sessao: AsyncSession, usuario_id: UUID) -> Vinculo | None:
    return await sessao.get(Vinculo, usuario_id)


async def criar(
    sessao: AsyncSession,
    usuario_id: UUID,
    universidade_id: UUID,
    cpf_informado: str,
) -> Vinculo:
    """O fluxo por trás de "inserir CPF" no menu do perfil da faculdade.

    Duas conferências, **nesta ordem**:

      1. o CPF enviado é o da própria conta
      2. esse CPF consta nas matrículas desta universidade

    A primeira é o que impede a escalada. O CPF não é segredo no Brasil — circula
    em vazamentos e cadastros de todo tipo — então conferir apenas contra a lista
    da faculdade transformaria o CPF em senha de acesso aos comunicados internos
    dela. Com a conferência contra a conta, quem souber o CPF de outra pessoa
    para no primeiro passo.
    """
    usuario = await perfis.obter(sessao, usuario_id)
    digitos = normalizar_cpf(cpf_informado)

    # `compare_digest` em vez de `==`: comparação que sai no primeiro byte
    # diferente vaza o prefixo pelo tempo de resposta. Cenário real, ainda que
    # estreito — alguém com a sessão roubada e sem saber o CPF da vítima.
    if not usuario.cpf or not compare_digest(digitos, usuario.cpf):
        raise _recusado(403)

    if await sessao.get(Universidade, universidade_id) is None:
        raise AppError(
            code="nao_encontrado",
            message="Universidade não encontrada",
            status_code=404,
        )

    matricula = (
        await sessao.execute(
            select(Matricula).where(
                Matricula.universidade_id == universidade_id,
                Matricula.cpf == digitos,
            )
        )
    ).scalar_one_or_none()

    if matricula is None:
        raise _recusado(404)

    agora = datetime.now(UTC)

    # Encerra o vínculo anterior. Um por vez, e quem troca de faculdade não
    # precisa que a instituição antiga o remova primeiro.
    await sessao.execute(delete(Vinculo).where(Vinculo.usuario_id == usuario_id))

    vinculo = Vinculo(
        usuario_id=usuario_id,
        universidade_id=universidade_id,
        curso_id=matricula.curso_id,
        criado_em=agora,
    )
    sessao.add(vinculo)

    await _marcar_formacao_verificada(
        sessao, usuario_id, universidade_id, matricula.curso_id, agora
    )

    await sessao.flush()
    await sessao.refresh(vinculo)
    return vinculo


async def encerrar(sessao: AsyncSession, usuario_id: UUID) -> None:
    """O aluno sai quando quiser, sem depender da instituição.

    Idempotente. **A formação segue verificada** — encerrar o vínculo não desfaz
    o fato de ter estudado lá, e reinserir o CPF recria o vínculo se a matrícula
    ainda existir.
    """
    await sessao.execute(delete(Vinculo).where(Vinculo.usuario_id == usuario_id))


async def encerrar_por_instituicao(sessao: AsyncSession, universidade_id: UUID, cpf: str) -> None:
    """Chamado quando a faculdade remove a matrícula.

    Encerra o vínculo do dono daquele CPF com esta instituição, e **mantém a
    formação verificada**: o caso comum é o aluno ter se formado ou trancado, e
    ele realmente estudou lá.

    Só remove o vínculo se ele for com *esta* universidade. Se o aluno já migrou
    para outra, a matrícula antiga sendo apagada não deve derrubar o vínculo novo.
    """
    digitos = normalizar_cpf(cpf)
    dono = (
        await sessao.execute(select(Usuario.id).where(Usuario.cpf == digitos))
    ).scalar_one_or_none()

    if dono is None:
        return

    await sessao.execute(
        delete(Vinculo).where(
            Vinculo.usuario_id == dono,
            Vinculo.universidade_id == universidade_id,
        )
    )


async def total_de_alunos(sessao: AsyncSession, universidade_id: UUID) -> int:
    consulta = (
        select(func.count()).select_from(Vinculo).where(Vinculo.universidade_id == universidade_id)
    )
    return int((await sessao.execute(consulta)).scalar_one())


async def _marcar_formacao_verificada(
    sessao: AsyncSession,
    usuario_id: UUID,
    universidade_id: UUID,
    curso_id: UUID,
    quando: datetime,
) -> None:
    """Marca a formação como verificada, criando-a se o aluno não a declarou.

    **Não apaga nem desmarca as anteriores.** Quem trocou de faculdade fica com
    duas formações verificadas, porque estudou nas duas — apagar a primeira
    reescreveria o passado.
    """
    existente = (
        await sessao.execute(
            select(Formacao).where(
                Formacao.usuario_id == usuario_id,
                Formacao.universidade_id == universidade_id,
                Formacao.curso_id == curso_id,
            )
        )
    ).scalar_one_or_none()

    if existente is not None:
        # Já declarada pelo próprio aluno, ou verificada num vínculo anterior com
        # a mesma instituição e curso. Nos dois casos, só (re)estampa o selo.
        existente.verificada_em = quando
        return

    sessao.add(
        Formacao(
            usuario_id=usuario_id,
            universidade_id=universidade_id,
            curso_id=curso_id,
            verificada_em=quando,
        )
    )
