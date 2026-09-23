"""Login, renovação, logout e troca de senha."""

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import httpx
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from auth_service.models import Credencial, RefreshToken
from auth_service.schemas import ParDeTokensOut
from auth_service.security import (
    conferir_senha,
    gerar_refresh_token,
    hash_do_refresh,
    hashear_senha,
    precisa_rehash,
)
from auth_service.settings import settings
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAutenticado, criar_access_token


def _credencial_invalida() -> AppError:
    # Mensagem única para e-mail inexistente e senha errada. Distinguir os dois
    # entrega ao atacante uma sonda de quais e-mails existem na base.
    return AppError(
        code="credenciais_invalidas",
        message="E-mail ou senha incorretos",
        status_code=401,
    )


def _sessao_invalida() -> AppError:
    return AppError(
        code="nao_autenticado",
        message="Sessão expirada. Faça login novamente.",
        status_code=401,
    )


async def entrar(sessao: AsyncSession, email: str, senha: str) -> ParDeTokensOut:
    credencial = await _por_email(sessao, email)

    if credencial is None or not conferir_senha(senha, credencial.senha_hash):
        # `conferir_senha` roda mesmo com credencial ausente? Não — e isso deixa
        # uma diferença de tempo entre e-mail inexistente e senha errada. Para o
        # escopo atual é aceitável; fechá-la exigiria hashear uma senha falsa a
        # cada tentativa de e-mail inexistente.
        raise _credencial_invalida()

    if precisa_rehash(credencial.senha_hash):
        # Atualiza o custo do hash de forma incremental, sem migração em massa.
        credencial.senha_hash = hashear_senha(senha)

    return await _emitir_par(sessao, credencial.id, familia_id=uuid4())


async def renovar(sessao: AsyncSession, token: str) -> ParDeTokensOut:
    guardado = await _por_hash(sessao, hash_do_refresh(token))

    if guardado is None:
        raise _sessao_invalida()

    if not guardado.utilizavel:
        # Token já usado, revogado ou expirado. Se já foi usado, é reapresentação
        # — o sinal clássico de vazamento — e a família inteira cai junto: manter
        # a sessão viva depois disso é manter o atacante dentro.
        await _revogar_familia(sessao, guardado.familia_id)
        # COMMIT ANTES DE LEVANTAR. A dependência de sessão faz rollback em
        # qualquer exceção, então a revogação seria desfeita pelo próprio
        # tratamento do erro — o atacante levaria 401 e continuaria com a
        # sessão viva. Esta é a única escrita do serviço que precisa sobreviver
        # a uma falha, e por isso é a única que faz commit à mão.
        await sessao.commit()
        raise _sessao_invalida()

    guardado.usado_em = datetime.now(UTC)
    return await _emitir_par(sessao, guardado.credencial_id, familia_id=guardado.familia_id)


async def sair(sessao: AsyncSession, token: str) -> None:
    """Revoga a sessão. Idempotente: token já inválido não é erro."""
    guardado = await _por_hash(sessao, hash_do_refresh(token))
    if guardado is not None:
        await _revogar_familia(sessao, guardado.familia_id)


async def trocar_senha(
    sessao: AsyncSession,
    credencial_id: UUID,
    senha_atual: str,
    nova_senha: str,
    confirmacao: str,
) -> None:
    from auth_service.validadores import validar_confirmacao, validar_senha

    credencial = await sessao.get(Credencial, credencial_id)
    if credencial is None:
        raise _sessao_invalida()

    if not conferir_senha(senha_atual, credencial.senha_hash):
        raise AppError(
            code="senha_atual_incorreta",
            message="Senha atual está incorreta",
            status_code=401,
        )

    erros: dict[str, list[str]] = {}
    if erro := validar_senha(nova_senha):
        erros["novaSenha"] = [erro]
    if erro := validar_confirmacao(nova_senha, confirmacao):
        erros["confirmacao"] = [erro]
    if conferir_senha(nova_senha, credencial.senha_hash):
        erros["novaSenha"] = ["A nova senha deve ser diferente da atual"]
    if erros:
        raise AppError(
            code="validation_error",
            message="Verifique os campos destacados",
            status_code=422,
            fields=erros,
        )

    credencial.senha_hash = hashear_senha(nova_senha)
    credencial.senha_alterada_em = datetime.now(UTC)

    # Trocar a senha revoga TODAS as sessões, inclusive a que fez a troca. Se a
    # senha mudou porque vazou, deixar as sessões antigas vivas anularia a troca.
    await sessao.execute(
        update(RefreshToken)
        .where(
            RefreshToken.credencial_id == credencial_id,
            RefreshToken.revogado_em.is_(None),
        )
        .values(revogado_em=datetime.now(UTC))
    )


async def _emitir_par(
    sessao: AsyncSession, credencial_id: UUID, *, familia_id: UUID
) -> ParDeTokensOut:
    perfil = await _buscar_perfil(credencial_id)

    access = criar_access_token(
        UsuarioAutenticado(
            id=credencial_id,
            tipo=perfil["tipo"],
            universidade_id=perfil["universidade_id"],
            curso_id=perfil["curso_id"],
        ),
        settings,
    )

    bruto = gerar_refresh_token()
    sessao.add(
        RefreshToken(
            credencial_id=credencial_id,
            token_hash=hash_do_refresh(bruto),
            familia_id=familia_id,
            expira_em=datetime.now(UTC) + timedelta(days=settings.refresh_token_ttl_dias),
        )
    )
    await sessao.flush()

    return ParDeTokensOut(
        access_token=access,
        refresh_token=bruto,
        expires_in=settings.access_token_ttl_segundos,
    )


async def _buscar_perfil(usuario_id: UUID) -> dict:
    """Busca tipo e afiliação no user-service, para gravar no access token.

    A afiliação viaja no token para o academic-service resolver visibilidade sem
    consultar o user-service a cada post. O preço, conhecido e aceito: trocar de
    curso só vale no token seguinte.
    """
    async with httpx.AsyncClient(
        base_url=settings.user_service_url, timeout=httpx.Timeout(10.0)
    ) as cliente:
        resposta = await cliente.get(
            f"/users/interno/{usuario_id}",
            headers={"X-Servico-Token": settings.servico_token},
        )

    if resposta.status_code != 200:
        # Credencial sem perfil: é a janela de inconsistência do cadastro. O
        # login falha de forma visível em vez de emitir um token sem afiliação,
        # que quebraria o feed acadêmico de um jeito muito mais difícil de achar.
        raise AppError(
            code="perfil_indisponivel",
            message="Não foi possível carregar seu perfil. Tente novamente.",
            status_code=503,
        )

    corpo = resposta.json()
    afiliacao = corpo.get("afiliacao") or {}
    return {
        "tipo": corpo.get("tipo", "aluno"),
        "universidade_id": _uuid_ou_none(afiliacao.get("universidade", {}).get("id")),
        "curso_id": _uuid_ou_none(afiliacao.get("curso", {}).get("id")),
    }


def _uuid_ou_none(valor: str | None) -> UUID | None:
    return UUID(valor) if valor else None


async def _por_email(sessao: AsyncSession, email: str) -> Credencial | None:
    from sqlalchemy import func

    resultado = await sessao.execute(
        select(Credencial).where(func.lower(Credencial.email) == email.strip().lower())
    )
    return resultado.scalar_one_or_none()


async def _por_hash(sessao: AsyncSession, token_hash: str) -> RefreshToken | None:
    resultado = await sessao.execute(
        select(RefreshToken).where(RefreshToken.token_hash == token_hash)
    )
    return resultado.scalar_one_or_none()


async def _revogar_familia(sessao: AsyncSession, familia_id: UUID) -> None:
    await sessao.execute(
        update(RefreshToken)
        .where(RefreshToken.familia_id == familia_id, RefreshToken.revogado_em.is_(None))
        .values(revogado_em=datetime.now(UTC))
    )
