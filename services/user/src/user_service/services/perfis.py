"""Regras de perfil e vínculo institucional.

A lógica mora aqui, não nas rotas: as rotas só traduzem HTTP. Isso mantém as
regras testáveis sem subir o FastAPI e impede que a mesma checagem seja escrita
de dois jeitos em rotas diferentes.
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from integra_shared.errors import AppError
from user_service.models import Curso, Universidade, Usuario
from user_service.schemas import AtualizarPerfilIn, CriarUsuarioIn

TERMO_MINIMO_DE_BUSCA = 2


def _nao_encontrado(mensagem: str) -> AppError:
    return AppError(code="nao_encontrado", message=mensagem, status_code=404)


async def obter(sessao: AsyncSession, usuario_id: UUID) -> Usuario:
    usuario = await sessao.get(Usuario, usuario_id)
    if usuario is None:
        raise _nao_encontrado("Usuário não encontrado")
    return usuario


async def criar(sessao: AsyncSession, dados: CriarUsuarioIn) -> Usuario:
    """Cria o perfil. Chamado pelo auth-service durante o cadastro."""
    await _garantir_par_valido(sessao, dados.universidade_id, dados.curso_id)

    if await _username_em_uso(sessao, dados.username, exceto=None):
        raise AppError(
            code="username_ja_existe",
            message="Username já existe",
            status_code=409,
        )
    if await _email_em_uso(sessao, dados.email):
        raise AppError(
            code="email_ja_cadastrado",
            message="Email já cadastrado",
            status_code=409,
        )

    usuario = Usuario(
        id=dados.id,
        nome_completo=dados.nome_completo,
        email=dados.email.lower(),
        username=dados.username.lower(),
        telefone=dados.telefone,
        tipo=dados.tipo,
        universidade_id=dados.universidade_id,
        curso_id=dados.curso_id,
    )
    sessao.add(usuario)
    await sessao.flush()
    await sessao.refresh(usuario)
    return usuario


async def atualizar(sessao: AsyncSession, usuario_id: UUID, dados: AtualizarPerfilIn) -> Usuario:
    usuario = await obter(sessao, usuario_id)
    campos = dados.model_dump(exclude_unset=True)

    if not campos:
        raise AppError(
            code="validation_error",
            message="Envie pelo menos um campo para atualizar",
            status_code=422,
        )

    if (novo_username := campos.get("username")) and novo_username != usuario.username:
        if await _username_em_uso(sessao, novo_username, exceto=usuario_id):
            raise AppError(
                code="username_ja_existe",
                message="Username já existe",
                status_code=409,
            )
        usuario.username = novo_username

    # Universidade e curso mudam juntos ou o curso é validado contra a
    # universidade vigente — um par inválido é o erro fácil de deixar passar.
    nova_uni = campos.get("universidade_id", usuario.universidade_id)
    novo_curso = campos.get("curso_id", usuario.curso_id)
    if ("universidade_id" in campos or "curso_id" in campos) and nova_uni and novo_curso:
        await _garantir_par_valido(sessao, nova_uni, novo_curso)
        usuario.universidade_id = nova_uni
        usuario.curso_id = novo_curso

    for campo in ("nome_completo", "telefone", "bio", "foto_url"):
        if campo in campos:
            setattr(usuario, campo, campos[campo])

    usuario.alterado_em = datetime.now(UTC)
    await sessao.flush()
    await sessao.refresh(usuario)
    return usuario


async def buscar(
    sessao: AsyncSession,
    termo: str,
    *,
    universidade_id: UUID | None = None,
    curso_id: UUID | None = None,
    limite: int = 20,
) -> list[Usuario]:
    """Busca por username ou nome.

    Substitui o truque `isLessThan: '${termo}z'` do Firestore, que só casava
    prefixo. Aqui é `ILIKE` com curinga dos dois lados, apoiado no índice
    trigram criado na migração.
    """
    if len(termo.strip()) < TERMO_MINIMO_DE_BUSCA:
        return []

    padrao = f"%{termo.strip()}%"
    consulta = select(Usuario).where(
        or_(Usuario.username.ilike(padrao), Usuario.nome_completo.ilike(padrao))
    )
    if universidade_id:
        consulta = consulta.where(Usuario.universidade_id == universidade_id)
    if curso_id:
        consulta = consulta.where(Usuario.curso_id == curso_id)

    resultado = await sessao.execute(consulta.order_by(Usuario.username).limit(limite))
    return list(resultado.unique().scalars())


async def listar_universidades(
    sessao: AsyncSession, termo: str | None = None
) -> list[Universidade]:
    consulta = select(Universidade).order_by(Universidade.sigla)
    if termo:
        padrao = f"%{termo.strip()}%"
        consulta = consulta.where(
            or_(Universidade.nome.ilike(padrao), Universidade.sigla.ilike(padrao))
        )
    return list((await sessao.execute(consulta)).scalars())


async def listar_cursos(sessao: AsyncSession, universidade_id: UUID) -> list[Curso]:
    if await sessao.get(Universidade, universidade_id) is None:
        raise _nao_encontrado("Universidade não encontrada")

    resultado = await sessao.execute(
        select(Curso).where(Curso.universidade_id == universidade_id).order_by(Curso.nome)
    )
    return list(resultado.scalars())


async def _garantir_par_valido(sessao: AsyncSession, universidade_id: UUID, curso_id: UUID) -> None:
    """O curso precisa pertencer à universidade informada.

    Sem esta checagem o banco aceitaria o par — as duas chaves estrangeiras são
    válidas isoladamente — e o aluno ficaria afiliado a um curso de outra
    instituição, quebrando o filtro do pilar Acadêmico em silêncio.
    """
    curso = await sessao.get(Curso, curso_id)
    if curso is None:
        raise AppError(
            code="validation_error",
            message="Verifique os campos destacados",
            status_code=422,
            fields={"cursoId": ["Curso é obrigatório"]},
        )
    if curso.universidade_id != universidade_id:
        raise AppError(
            code="validation_error",
            message="Verifique os campos destacados",
            status_code=422,
            fields={"cursoId": ["Este curso não pertence à universidade escolhida"]},
        )


async def _username_em_uso(sessao: AsyncSession, username: str, *, exceto: UUID | None) -> bool:
    consulta = (
        select(func.count())
        .select_from(Usuario)
        .where(func.lower(Usuario.username) == username.lower())
    )
    if exceto:
        consulta = consulta.where(Usuario.id != exceto)
    return bool((await sessao.execute(consulta)).scalar_one())


async def _email_em_uso(sessao: AsyncSession, email: str) -> bool:
    consulta = (
        select(func.count()).select_from(Usuario).where(func.lower(Usuario.email) == email.lower())
    )
    return bool((await sessao.execute(consulta)).scalar_one())
