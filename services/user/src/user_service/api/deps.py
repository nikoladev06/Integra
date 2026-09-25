"""Dependências compartilhadas pelas rotas."""

from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado, exigir_tipo, usuario_atual
from user_service.database import fabrica_de_sessao
from user_service.settings import settings


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


async def exigir_token_de_servico(
    x_servico_token: Annotated[str | None, Header()] = None,
) -> None:
    """Protege as rotas internas, chamadas por outro serviço e não por usuários.

    O Traefik roteia `/users/*` publicamente, então a rota interna de criação de
    perfil está exposta na mesma porta das demais. Sem este cabeçalho, qualquer
    um poderia criar perfis sem passar pelo cadastro.

    É um segredo compartilhado, não um JWT: quem chama é um serviço, não um
    usuário, e não há sessão a representar.
    """
    esperado = settings.servico_token
    if not x_servico_token or not _comparar_em_tempo_constante(x_servico_token, esperado):
        raise AppError(
            code="nao_autenticado",
            message="Rota interna",
            status_code=401,
        )


def _comparar_em_tempo_constante(a: str, b: str) -> bool:
    # `secrets.compare_digest` em vez de `==`: comparação que sai no primeiro
    # byte diferente vaza o prefixo correto pelo tempo de resposta.
    from secrets import compare_digest

    return compare_digest(a, b)


SessaoDep = Annotated[AsyncSession, Depends(obter_sessao)]
UsuarioDep = Annotated[UsuarioAutenticado, Depends(usuario_atual)]

# Administrar cursos e matrículas exige conta institucional. A checagem é uma
# dependência, não um `if` na rota: uma rota nova que esqueça o `if` fica aberta,
# e uma que esqueça a dependência nem compila o tipo que ela devolve.
FaculdadeDep = Annotated[UsuarioAutenticado, Depends(exigir_tipo("faculdade"))]


async def exigir_faculdade_ativa(
    sessao: Annotated[AsyncSession, Depends(obter_sessao)],
    usuario: Annotated[UsuarioAutenticado, Depends(exigir_tipo("faculdade"))],
) -> UsuarioAutenticado:
    """Conta `faculdade` **e** ativada. É o portão dos poderes institucionais.

    A checagem consulta o BANCO, não um claim do token. Foi uma escolha: pôr o
    estado de ativação no JWT seria mais rápido, mas uma conta desativada seguiria
    publicando e matriculando por até 15 minutos — o tempo de vida do access
    token. Autorização para escrita privilegiada não deve ficar em cache.

    O custo é uma consulta por chave primária, em rotas raras (publicar,
    matricular), não no caminho de leitura.
    """
    from user_service.models import Usuario

    conta = await sessao.get(Usuario, usuario.id)
    if conta is None or not conta.ativa:
        raise AppError(
            code="conta_pendente",
            message="Sua instituição ainda está em análise. Você será avisado quando for ativada.",
            status_code=403,
        )
    return usuario


# Usada onde a conta precisa poder AGIR pela instituição. `FaculdadeDep` continua
# servindo para leitura do que é dela — ver os próprios cursos, por exemplo.
FaculdadeAtivaDep = Annotated[UsuarioAutenticado, Depends(exigir_faculdade_ativa)]

TokenDeServico = Depends(exigir_token_de_servico)
