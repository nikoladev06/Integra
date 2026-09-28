"""Dependências das rotas do academic-service."""

from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from academic_service import usuarios
from academic_service.database import fabrica_de_sessao
from academic_service.usuarios import UniversidadeDaConta
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado, exigir_tipo, usuario_atual


async def obter_sessao() -> AsyncIterator[AsyncSession]:
    """Uma sessão por requisição, com a transação fechada aqui.

    Commit no fim do caminho feliz, rollback em qualquer exceção. Deixar isso a
    cargo de cada rota é como metade delas acaba esquecendo o rollback.
    """
    async with fabrica_de_sessao() as sessao:
        try:
            yield sessao
            await sessao.commit()
        except Exception:
            await sessao.rollback()
            raise


async def obter_instituicao_ativa(
    conta: Annotated[UsuarioAutenticado, Depends(exigir_tipo("faculdade"))],
) -> UniversidadeDaConta:
    """A instituição da conta autora, **e** a prova de que ela pode agir.

    Uma dependência, e não um `if` no começo de cada rota de escrita: uma rota nova
    que esqueça o `if` fica aberta, e uma que esqueça a dependência não recebe a
    universidade — sem a qual não tem como publicar. O erro barato é o que não
    compila; o caro é o que publica.

    Duas coisas acontecem aqui, na ordem:

      1. `exigir_tipo("faculdade")` recusa aluno e empresa pelo **token**, sem I/O;
      2. a consulta ao user-service recusa a conta institucional **pendente**.

    A segunda é a que não pode vir do token: no JWT, uma conta desativada seguiria
    publicando por até 15 minutos — o tempo de vida do access token. Autorização
    para escrita privilegiada não fica em cache.
    """
    instituicao = await usuarios.universidade_da_conta(conta.id)

    if not instituicao.conta_ativa:
        raise AppError(
            code="conta_pendente",
            message="Sua instituição ainda está em análise. Você será avisado quando for ativada.",
            status_code=403,
        )
    return instituicao


SessaoDep = Annotated[AsyncSession, Depends(obter_sessao)]
UsuarioDep = Annotated[UsuarioAutenticado, Depends(usuario_atual)]

# Toda rota de escrita de post usa esta. O tipo que ela devolve é o que a rota
# precisa para publicar, então não há como usá-la só "de enfeite" e esquecer o que
# ela garante.
InstituicaoDep = Annotated[UniversidadeDaConta, Depends(obter_instituicao_ativa)]
