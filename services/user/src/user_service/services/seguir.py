"""O grafo de seguidores.

Mora no user-service, e não nos serviços de feed, porque quem segue quem é
atributo do usuário — e os dois feeds consultam a mesma lista.

**Seguir não concede acesso a conteúdo restrito.** Quem segue uma instituição sem
ter vínculo passa a ver apenas os posts `publico`; `institucional` e `curso`
continuam exigindo vínculo ativo. Este módulo só registra interesse; quem aplica
a regra é o academic-service, na consulta. Está dito aqui porque é a primeira
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
from user_service.services import perfis, vinculos


async def listar_universidades(
    sessao: AsyncSession, usuario_id: UUID
) -> list[UniversidadeSeguidaOut]:
    """Seguidas explicitamente, mais a do vínculo ativo.

    A universidade do vínculo entra sempre, mesmo sem registro nesta tabela: ela
    não é opcional enquanto o vínculo existir, e deixá-la de fora faria o escopo
    "geral" do feed excluir justamente a instituição do aluno.

    **Uma conta sem vínculo pode ter esta lista vazia** — é o estado normal de
    quem acabou de se cadastrar, não um erro.
    """
    vinculo = await vinculos.obter(sessao, usuario_id)

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

    if vinculo is not None:
        vistas.add(vinculo.universidade.id)
        saida.append(
            UniversidadeSeguidaOut(
                id=vinculo.universidade.id,
                nome=vinculo.universidade.nome,
                sigla=vinculo.universidade.sigla,
                propria=True,
                seguida_em=None,
            )
        )

    for universidade, seguida_em in resultado:
        if universidade.id in vistas:
            continue
        saida.append(
            UniversidadeSeguidaOut(
                id=universidade.id,
                nome=universidade.nome,
                sigla=universidade.sigla,
                propria=False,
                seguida_em=seguida_em,
            )
        )

    return saida


async def segue_universidade(sessao: AsyncSession, usuario_id: UUID, universidade_id: UUID) -> bool:
    linha = await sessao.get(SeguindoUniversidade, (usuario_id, universidade_id))
    return linha is not None


async def seguir_universidade(
    sessao: AsyncSession, usuario_id: UUID, universidade_id: UUID
) -> None:
    await perfis.obter_universidade(sessao, universidade_id)

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
    vinculo = await vinculos.obter(sessao, usuario_id)

    if vinculo is not None and vinculo.universidade_id == universidade_id:
        # Enquanto o vínculo existe, a instituição não sai do feed: sair dela
        # seria perder os comunicados que ela dirige ao aluno. O caminho é
        # encerrar o vínculo, que é uma decisão diferente e mais consciente.
        raise AppError(
            code="universidade_do_vinculo",
            message="Encerre o vínculo antes de deixar de seguir esta instituição",
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
