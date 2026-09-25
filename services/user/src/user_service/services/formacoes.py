"""O currículo declarado.

Sem nenhuma verificação, por decisão de produto: como no LinkedIn, dá para
declarar uma faculdade onde nunca se estudou. **Não concede acesso a nada** — o
que concede é o vínculo, e só ele.
"""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from integra_shared.errors import AppError
from user_service.models import Formacao
from user_service.services import perfis


async def listar(sessao: AsyncSession, usuario_id: UUID) -> list[Formacao]:
    resultado = await sessao.execute(
        select(Formacao)
        .where(Formacao.usuario_id == usuario_id)
        .order_by(Formacao.criado_em.desc())
    )
    return list(resultado.unique().scalars())


async def declarar(
    sessao: AsyncSession, usuario_id: UUID, universidade_id: UUID, curso_id: UUID
) -> Formacao:
    await perfis.obter(sessao, usuario_id)
    await perfis.garantir_par_valido(sessao, universidade_id, curso_id)

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
        raise AppError(
            code="formacao_duplicada",
            message="Esta formação já consta no seu perfil",
            status_code=409,
        )

    formacao = Formacao(
        usuario_id=usuario_id,
        universidade_id=universidade_id,
        curso_id=curso_id,
        verificada_em=None,
    )
    sessao.add(formacao)
    await sessao.flush()
    await sessao.refresh(formacao)
    return formacao


async def remover(sessao: AsyncSession, usuario_id: UUID, formacao_id: UUID) -> None:
    """Remove apenas formações **não verificadas**.

    Uma verificada responde 409: o selo é afirmação da instituição, não do
    usuário, e deixá-lo apagável pelo perfil transformaria "verificado" em algo
    que o próprio interessado controla. Para sair do vínculo existe
    `vinculos.encerrar`, que é outra coisa — e que preserva o selo.
    """
    formacao = (
        await sessao.execute(
            select(Formacao).where(Formacao.id == formacao_id, Formacao.usuario_id == usuario_id)
        )
    ).scalar_one_or_none()

    if formacao is None:
        raise AppError(
            code="nao_encontrado",
            message="Formação não encontrada no seu perfil",
            status_code=404,
        )

    if formacao.verificada:
        raise AppError(
            code="formacao_verificada",
            message="Formações verificadas pela instituição não podem ser removidas",
            status_code=409,
        )

    await sessao.delete(formacao)
    await sessao.flush()
