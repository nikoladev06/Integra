"""Dependências das rotas do feed-service."""

from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from feed_service import usuarios
from feed_service.database import fabrica_de_sessao
from feed_service.models import TipoDeAutor
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado, usuario_atual


async def obter_sessao() -> AsyncIterator[AsyncSession]:
    """Uma sessão por requisição, com a transação fechada aqui.

    Commit no fim do caminho feliz, rollback em qualquer exceção. Deixar isso a cargo
    de cada rota é como metade delas acaba esquecendo o rollback.
    """
    async with fabrica_de_sessao() as sessao:
        try:
            yield sessao
            await sessao.commit()
        except Exception:
            await sessao.rollback()
            raise


async def obter_autor_habilitado(
    usuario: Annotated[UsuarioAutenticado, Depends(usuario_atual)],
) -> TipoDeAutor:
    """Quem pode publicar, e **como o post fica marcado**.

    Uma dependência, e não um `if` no começo de cada rota de escrita: uma rota nova
    que esqueça o `if` fica aberta; uma que esqueça a dependência não recebe o
    `TipoDeAutor` — sem o qual não tem como gravar o post. O erro barato é o que não
    compila; o caro é o que publica.

    Duas recusas, e elas são diferentes:

      1. **conta `faculdade`** — não publica aqui, nunca. Comunicado de instituição é
         o pilar acadêmico, e uma faculdade no feed profissional diria a mesma coisa
         duas vezes em dois lugares. Recusada pelo token, sem I/O.
      2. **conta institucional pendente** — recusada depois da consulta ao
         user-service. Não pode vir do token: no JWT, uma conta desativada seguiria
         publicando por até 15 minutos.

    O tipo devolvido vem do **banco**, e não do claim. A diferença é pequena — tipo de
    conta não se edita —, mas a chamada já está sendo feita para conferir a ativação,
    e usar o valor autoritativo não custa nada.
    """
    estado = await usuarios.ativacao(usuario.id)

    if estado.tipo == "faculdade":
        raise AppError(
            code="permissao_negada",
            message="Contas de instituição publicam no pilar Acadêmico, não no Profissional",
            status_code=403,
        )

    if not estado.ativa:
        raise AppError(
            code="conta_pendente",
            message="Sua conta ainda está em análise. Você será avisado quando for ativada.",
            status_code=403,
        )

    return TipoDeAutor(estado.tipo)


SessaoDep = Annotated[AsyncSession, Depends(obter_sessao)]
UsuarioDep = Annotated[UsuarioAutenticado, Depends(usuario_atual)]

# Toda rota que cria post usa esta. O tipo que ela devolve é o que a rota precisa
# para publicar, então não há como usá-la "de enfeite" e esquecer o que ela garante.
AutorDep = Annotated[TipoDeAutor, Depends(obter_autor_habilitado)]
