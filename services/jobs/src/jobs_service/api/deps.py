"""Dependências das rotas do jobs-service."""

from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado, exigir_tipo, usuario_atual
from jobs_service import usuarios
from jobs_service.database import fabrica_de_sessao


async def obter_sessao() -> AsyncIterator[AsyncSession]:
    """Uma sessão por requisição, com a transação fechada aqui."""
    async with fabrica_de_sessao() as sessao:
        try:
            yield sessao
            await sessao.commit()
        except Exception:
            await sessao.rollback()
            raise


async def obter_empresa_ativa(
    conta: Annotated[UsuarioAutenticado, Depends(exigir_tipo("empresa"))],
) -> UsuarioAutenticado:
    """A conta autora de vaga, **e** a prova de que ela pode agir.

    Uma dependência, e não um `if` no começo de cada rota de escrita: uma rota nova que
    esqueça o `if` fica aberta. Duas coisas acontecem aqui, na ordem:

      1. `exigir_tipo("empresa")` recusa aluno e faculdade pelo **token**, sem I/O;
      2. a consulta ao user-service recusa a conta institucional **pendente**.

    A segunda não pode vir do token: no JWT, uma conta desativada seguiria publicando
    por até 15 minutos. Autorização para escrita privilegiada não fica em cache.

    Devolve a própria conta, e não um booleano, para a rota usar `conta.id` como
    `empresa_id` — assim a vaga é publicada em nome de quem a dependência aprovou, e
    não de um id que a rota leu de outro lugar.
    """
    estado = await usuarios.ativacao(conta.id)
    if not estado.ativa:
        raise AppError(
            code="conta_pendente",
            message="Sua conta ainda está em análise. Você será avisado quando for ativada.",
            status_code=403,
        )
    return conta


SessaoDep = Annotated[AsyncSession, Depends(obter_sessao)]
UsuarioDep = Annotated[UsuarioAutenticado, Depends(usuario_atual)]

# Publicar e editar vaga.
EmpresaDep = Annotated[UsuarioAutenticado, Depends(obter_empresa_ativa)]

# Candidatar-se. Sem checagem de ativação: conta `aluno` nasce ativada — autocadastro
# de pessoa não passa por aprovação —, então a consulta ao user-service não teria o que
# recusar e custaria uma ida de rede por candidatura.
AlunoDep = Annotated[UsuarioAutenticado, Depends(exigir_tipo("aluno"))]
