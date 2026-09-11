"""Emissão e validação de JWT, e a dependência de autenticação.

Esta é a peça que o plano chama de "dependência FastAPI compartilhada": o Traefik
roteia, isto autentica. Cada serviço valida a assinatura localmente com o segredo
compartilhado, sem chamada de rede ao auth-service — é o que permite derrubar o
auth-service sem derrubar a leitura dos outros.

O access token carrega a afiliação (`universidadeId`, `cursoId`) para que o
academic-service resolva visibilidade sem consultar o user-service a cada post.
O preço é conhecido e aceito: trocar de curso só passa a valer no próximo token,
em no máximo `access_token_ttl_segundos`.
"""

from datetime import UTC, datetime, timedelta
from typing import Annotated, Literal
from uuid import UUID

import jwt
from fastapi import Depends, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel

from integra_shared.config import Settings, obter_settings
from integra_shared.errors import AppError

TipoConta = Literal["aluno", "faculdade", "empresa"]

_esquema = HTTPBearer(auto_error=False)


class UsuarioAutenticado(BaseModel):
    """Identidade extraída do token. Nunca vem do corpo da requisição."""

    id: UUID
    tipo: TipoConta
    universidade_id: UUID | None = None
    curso_id: UUID | None = None


def _nao_autenticado(mensagem: str = "Sessão expirada. Faça login novamente.") -> AppError:
    # Mensagem única para token ausente, malformado, expirado ou de assinatura
    # inválida: para o usuário a ação é sempre a mesma, e distinguir os casos só
    # ajudaria quem estiver sondando a API.
    return AppError(
        code="nao_autenticado",
        message=mensagem,
        status_code=status.HTTP_401_UNAUTHORIZED,
    )


def criar_access_token(usuario: UsuarioAutenticado, settings: Settings | None = None) -> str:
    settings = settings or obter_settings()
    agora = datetime.now(UTC)
    payload = {
        "sub": str(usuario.id),
        "tipo": usuario.tipo,
        "universidadeId": str(usuario.universidade_id) if usuario.universidade_id else None,
        "cursoId": str(usuario.curso_id) if usuario.curso_id else None,
        "iat": agora,
        "exp": agora + timedelta(seconds=settings.access_token_ttl_segundos),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algoritmo)


def decodificar_access_token(token: str, settings: Settings | None = None) -> UsuarioAutenticado:
    settings = settings or obter_settings()
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            # Lista explícita: aceitar o algoritmo declarado no header do token é a
            # confusão de algoritmo clássica, em que "alg": "none" passa direto.
            algorithms=[settings.jwt_algoritmo],
        )
    except jwt.PyJWTError as exc:
        raise _nao_autenticado() from exc

    universidade = payload.get("universidadeId")
    curso = payload.get("cursoId")
    try:
        return UsuarioAutenticado(
            id=UUID(payload["sub"]),
            tipo=payload["tipo"],
            universidade_id=UUID(universidade) if universidade else None,
            curso_id=UUID(curso) if curso else None,
        )
    except (KeyError, ValueError) as exc:
        # Assinatura válida mas conteúdo fora do formato: token emitido por uma
        # versão anterior do serviço. Tratar como não autenticado força o refresh.
        raise _nao_autenticado() from exc


async def usuario_atual(
    credenciais: Annotated[HTTPAuthorizationCredentials | None, Depends(_esquema)],
) -> UsuarioAutenticado:
    """Dependência para rotas autenticadas: `usuario: UsuarioAtual`."""
    if credenciais is None or not credenciais.credentials:
        raise _nao_autenticado("Autenticação necessária")
    return decodificar_access_token(credenciais.credentials)


def exigir_tipo(*tipos: TipoConta):
    """Dependência de autorização por tipo de conta.

    Usada na Sprint 4 em diante: publicar post institucional exige `faculdade`,
    publicar vaga exige `empresa`.
    """

    async def _verificar(
        usuario: Annotated[UsuarioAutenticado, Depends(usuario_atual)],
    ) -> UsuarioAutenticado:
        if usuario.tipo not in tipos:
            raise AppError(
                code="permissao_negada",
                message="Sua conta não tem permissão para esta ação",
                status_code=status.HTTP_403_FORBIDDEN,
            )
        return usuario

    return _verificar


UsuarioAtual = Annotated[UsuarioAutenticado, Depends(usuario_atual)]
