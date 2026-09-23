"""Cadastro — a operação que atravessa dois serviços.

Criar uma conta significa gravar uma credencial aqui **e** um perfil no
user-service. São dois bancos, então não existe transação que cubra os dois.

O desenho escolhido, e o que ele custa:

  1. valida tudo o que dá para validar localmente
  2. grava a credencial (gerando o id que os dois lados vão usar)
  3. chama o user-service para criar o perfil
  4. se o passo 3 falhar, **apaga a credencial** — a compensação

A janela de inconsistência é entre 2 e 4: se o processo morrer exatamente ali,
sobra uma credencial órfã. Ela não deixa ninguém entrar, porque o login carrega
o perfil, e o próximo cadastro com o mesmo e-mail encontra o conflito e falha de
forma visível em vez de silenciosa. É o custo aceito em troca de não introduzir
fila nem saga num projeto deste tamanho — e a alternativa de um banco só entre os
serviços custaria mais no longo prazo.
"""

from uuid import UUID, uuid4

import httpx
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth_service.models import Credencial
from auth_service.schemas import CadastroIn
from auth_service.security import hashear_senha
from auth_service.settings import settings
from auth_service.validadores import erros_do_cadastro
from integra_shared.errors import AppError


async def cadastrar(sessao: AsyncSession, dados: CadastroIn) -> UUID:
    erros = erros_do_cadastro(
        nome_completo=dados.nome_completo,
        email=dados.email,
        username=dados.username,
        senha=dados.senha,
        telefone=dados.telefone,
    )
    if erros:
        raise AppError(
            code="validation_error",
            message="Verifique os campos destacados",
            status_code=422,
            fields=erros,
        )

    email = dados.email.strip().lower()
    if await _email_em_uso(sessao, email):
        raise AppError(
            code="email_ja_cadastrado",
            message="Email já cadastrado",
            status_code=409,
        )

    # O id nasce aqui e viaja para o user-service: os dois lados passam a falar
    # do mesmo usuário sem tabela de correspondência.
    usuario_id = uuid4()

    credencial = Credencial(
        id=usuario_id,
        email=email,
        senha_hash=hashear_senha(dados.senha),
    )
    sessao.add(credencial)
    await sessao.flush()

    try:
        await _criar_perfil(usuario_id, dados, email)
    except AppError:
        await _compensar(sessao, usuario_id)
        raise
    except Exception as erro:
        await _compensar(sessao, usuario_id)
        raise AppError(
            code="cadastro_indisponivel",
            message="Não foi possível concluir o cadastro. Tente novamente em instantes.",
            status_code=503,
        ) from erro

    return usuario_id


async def _criar_perfil(usuario_id: UUID, dados: CadastroIn, email: str) -> None:
    corpo = {
        "id": str(usuario_id),
        "nomeCompleto": dados.nome_completo.strip(),
        "email": email,
        "username": dados.username.strip().lower(),
        "telefone": dados.telefone.strip(),
        "universidadeId": str(dados.universidade_id),
        "cursoId": str(dados.curso_id),
    }

    async with httpx.AsyncClient(
        base_url=settings.user_service_url,
        timeout=httpx.Timeout(10.0),
    ) as cliente:
        resposta = await cliente.post(
            "/users/interno",
            json=corpo,
            headers={"X-Servico-Token": settings.servico_token},
        )

    if resposta.status_code == 201:
        return

    # Repassa o erro do user-service com o código dele. Username duplicado e
    # curso que não pertence à universidade só são detectáveis lá, e traduzi-los
    # para uma mensagem genérica aqui esconderia do usuário qual campo corrigir.
    try:
        corpo_erro = resposta.json()
    except ValueError:
        corpo_erro = {}

    raise AppError(
        code=corpo_erro.get("code", "cadastro_recusado"),
        message=corpo_erro.get("message", "Não foi possível concluir o cadastro"),
        status_code=resposta.status_code if resposta.status_code in (409, 422) else 502,
        fields=corpo_erro.get("fields"),
    )


async def _compensar(sessao: AsyncSession, usuario_id: UUID) -> None:
    """Desfaz a credencial quando o perfil não pôde ser criado."""
    await sessao.execute(delete(Credencial).where(Credencial.id == usuario_id))
    await sessao.flush()


async def _email_em_uso(sessao: AsyncSession, email: str) -> bool:
    consulta = (
        select(func.count()).select_from(Credencial).where(func.lower(Credencial.email) == email)
    )
    return bool((await sessao.execute(consulta)).scalar_one())
