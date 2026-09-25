"""Emissão e validação de JWT, e a dependência de autenticação.

Esta é a peça que o plano chama de "dependência FastAPI compartilhada": o Traefik
roteia, isto autentica. Cada serviço valida a assinatura localmente com o segredo
compartilhado, sem chamada de rede ao auth-service — é o que permite derrubar o
auth-service sem derrubar a leitura de perfil.

## O que viaja no token, e por quê

O access token carrega o **vínculo ativo** — a instituição que confirmou o aluno —
para o academic-service resolver visibilidade sem consultar o user-service a cada
post. O preço é conhecido e aceito: sair ou entrar num vínculo só passa a valer
no token seguinte, em no máximo `access_token_ttl_segundos`.

**Formação declarada não viaja no token.** Ela é cosmética, o próprio usuário a
digita sem verificação nenhuma, e o que não decide autorização não precisa estar
em toda requisição. Um serviço que lesse formação como se fosse vínculo
concederia acesso pelo que o usuário digitou sozinho.

Os claims se chamam `vinculoUniversidadeId` e `vinculoCursoId`. Até a v1 eram
`universidadeId`/`cursoId` e significavam a afiliação declarada no cadastro —
nomes iguais com semântica trocada seriam a forma mais fácil de reintroduzir
exatamente aquele furo.
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

    # O vínculo ativo, quando existe. **Nulo é o estado normal** de toda conta
    # recém-criada: quem não informou o CPF em nenhuma instituição não tem
    # vínculo, e vê apenas posts públicos.
    vinculo_universidade_id: UUID | None = None
    vinculo_curso_id: UUID | None = None

    @property
    def tem_vinculo(self) -> bool:
        return self.vinculo_universidade_id is not None

    def tem_vinculo_com(self, universidade_id: UUID) -> bool:
        """Se o usuário pode ver o conteúdo interno desta instituição.

        Existe como método para nenhuma consulta precisar montar a comparação à
        mão — e para o nome dizer o que a checagem significa.
        """
        return self.vinculo_universidade_id == universidade_id


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
        "vinculoUniversidadeId": (
            str(usuario.vinculo_universidade_id) if usuario.vinculo_universidade_id else None
        ),
        "vinculoCursoId": (str(usuario.vinculo_curso_id) if usuario.vinculo_curso_id else None),
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

    universidade = payload.get("vinculoUniversidadeId")
    curso = payload.get("vinculoCursoId")
    try:
        return UsuarioAutenticado(
            id=UUID(payload["sub"]),
            tipo=payload["tipo"],
            vinculo_universidade_id=UUID(universidade) if universidade else None,
            vinculo_curso_id=UUID(curso) if curso else None,
        )
    except (KeyError, ValueError) as exc:
        # Assinatura válida mas conteúdo fora do formato: token emitido por uma
        # versão anterior do serviço — inclusive os da v1, que traziam
        # `universidadeId` em vez de `vinculoUniversidadeId`. Tratar como não
        # autenticado força o refresh, e é o que impede um token v1 de ser lido
        # com a semântica nova.
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

    Publicar post institucional exige `faculdade`; publicar vaga exige `empresa`;
    administrar cursos e matrículas exige `faculdade`.
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
SomenteFaculdade = Annotated[UsuarioAutenticado, Depends(exigir_tipo("faculdade"))]
