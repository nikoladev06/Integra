"""O grafo de seguidores.

Mora no user-service, e não nos serviços de feed, porque quem segue quem é
atributo do usuário — e os dois feeds consultam a mesma lista.

**Seguir não concede acesso a conteúdo restrito.** Quem segue uma instituição
sem ter vínculo passa a ver apenas os posts `publico`; `institucional` e `curso`
continuam exigindo afiliação. Este módulo só registra a intenção; quem aplica a
regra é o academic-service, na consulta. Está dito aqui porque é a primeira
coisa que alguém lendo "seguir" vai assumir errado.
"""

from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from integra_shared.errors import AppError
from user_service.models import (
    SeguindoUniversidade,
    SeguindoUsuario,
    TipoConta,
    Universidade,
    Usuario,
)
from user_service.schemas import UniversidadeSeguidaOut
from user_service.services import perfis


async def listar_universidades(
    sessao: AsyncSession, usuario_id: UUID
) -> list[UniversidadeSeguidaOut]:
    """Seguidas explicitamente, mais a própria.

    A universidade da afiliação entra sempre, mesmo sem registro na tabela: ela
    não é opcional, e deixá-la de fora faria o escopo "geral" do feed excluir
    justamente a instituição do aluno.
    """
    usuario = await perfis.obter(sessao, usuario_id)

    resultado = await sessao.execute(
        select(Universidade, SeguindoUniversidade.seguida_em)
        .join(
            SeguindoUniversidade,
            SeguindoUniversidade.universidade_id == Universidade.id,
        )
        .where(SeguindoUniversidade.usuario_id == usuario_id)
        .order_by(Universidade.sigla)
    )

    saida: list[UniversidadeSeguidaOut] = []
    vistas: set[UUID] = set()

    if usuario.universidade is not None:
        vistas.add(usuario.universidade.id)
        saida.append(
            UniversidadeSeguidaOut.model_validate(
                {
                    "id": usuario.universidade.id,
                    "nome": usuario.universidade.nome,
                    "sigla": usuario.universidade.sigla,
                    "propria": True,
                    "seguida_em": None,
                }
            )
        )

    for universidade, seguida_em in resultado:
        if universidade.id in vistas:
            continue
        saida.append(
            UniversidadeSeguidaOut.model_validate(
                {
                    "id": universidade.id,
                    "nome": universidade.nome,
                    "sigla": universidade.sigla,
                    "propria": False,
                    "seguida_em": seguida_em,
                }
            )
        )

    return saida


async def seguir_universidade(
    sessao: AsyncSession, usuario_id: UUID, universidade_id: UUID
) -> None:
    if await sessao.get(Universidade, universidade_id) is None:
        raise AppError(
            code="nao_encontrado",
            message="Universidade não encontrada",
            status_code=404,
        )

    # `ON CONFLICT DO NOTHING` em vez de consultar antes de inserir: idempotente
    # sem condição de corrida entre a checagem e a escrita.
    await sessao.execute(
        insert(SeguindoUniversidade)
        .values(usuario_id=usuario_id, universidade_id=universidade_id)
        .on_conflict_do_nothing()
    )


async def deixar_de_seguir_universidade(
    sessao: AsyncSession, usuario_id: UUID, universidade_id: UUID
) -> None:
    usuario = await perfis.obter(sessao, usuario_id)

    if usuario.universidade_id == universidade_id:
        # O vínculo não é escolha de feed: sair dele seria perder os comunicados
        # que a instituição dirige ao aluno.
        raise AppError(
            code="universidade_propria",
            message="Você não pode deixar de seguir sua própria universidade",
            status_code=409,
        )

    await sessao.execute(
        delete(SeguindoUniversidade).where(
            SeguindoUniversidade.usuario_id == usuario_id,
            SeguindoUniversidade.universidade_id == universidade_id,
        )
    )


async def listar_usuarios(
    sessao: AsyncSession, usuario_id: UUID, tipo: TipoConta | None = None
) -> list[Usuario]:
    consulta = (
        select(Usuario)
        .join(SeguindoUsuario, SeguindoUsuario.seguido_id == Usuario.id)
        .where(SeguindoUsuario.seguidor_id == usuario_id)
        .order_by(Usuario.nome_completo)
    )
    if tipo:
        consulta = consulta.where(Usuario.tipo == tipo)

    return list((await sessao.execute(consulta)).unique().scalars())


async def seguir_usuario(sessao: AsyncSession, seguidor_id: UUID, seguido_id: UUID) -> None:
    if seguidor_id == seguido_id:
        raise AppError(
            code="seguir_a_si_mesmo",
            message="Você não pode seguir a si mesmo",
            status_code=409,
        )

    await perfis.obter(sessao, seguido_id)

    await sessao.execute(
        insert(SeguindoUsuario)
        .values(seguidor_id=seguidor_id, seguido_id=seguido_id)
        .on_conflict_do_nothing()
    )


async def deixar_de_seguir_usuario(
    sessao: AsyncSession, seguidor_id: UUID, seguido_id: UUID
) -> None:
    await sessao.execute(
        delete(SeguindoUsuario).where(
            SeguindoUsuario.seguidor_id == seguidor_id,
            SeguindoUsuario.seguido_id == seguido_id,
        )
    )
