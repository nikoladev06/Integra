"""Perfil e busca de pessoas.

A lógica mora aqui, não nas rotas: as rotas só traduzem HTTP. Isso mantém as
regras testáveis sem subir o FastAPI e impede que a mesma checagem seja escrita
de dois jeitos em rotas diferentes.
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from integra_shared.cpf import normalizar as normalizar_cpf
from integra_shared.errors import AppError
from user_service.models import Curso, Formacao, TipoConta, Universidade, Usuario, Vinculo
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
    cpf = normalizar_cpf(dados.cpf)

    if await username_em_uso(sessao, dados.username, exceto=None):
        raise AppError(code="username_ja_existe", message="Username já existe", status_code=409)
    if await email_em_uso(sessao, dados.email):
        raise AppError(code="email_ja_cadastrado", message="Email já cadastrado", status_code=409)
    if cpf and await _cpf_em_uso(sessao, cpf):
        raise AppError(code="cpf_ja_cadastrado", message="CPF já cadastrado", status_code=409)

    usuario = Usuario(
        id=dados.id,
        nome_completo=dados.nome_completo,
        email=dados.email.lower(),
        username=dados.username.lower(),
        cpf=cpf or None,
        telefone=dados.telefone,
        tipo=dados.tipo,
        # Conta de pessoa nasce ATIVA: autocadastro de aluno não precisa de
        # aprovação, e o que ele pode fazer não afeta mais ninguém. Só a conta
        # institucional nasce pendente, porque ela emite selo de verificado.
        ativada_em=datetime.now(UTC),
    )
    sessao.add(usuario)
    await sessao.flush()

    # Formação opcional e **declarada**: entra sem `verificada_em`. O cadastro
    # nunca cria vínculo — isso só acontece pelo fluxo do CPF no perfil da
    # instituição.
    if dados.universidade_id and dados.curso_id:
        await garantir_par_valido(sessao, dados.universidade_id, dados.curso_id)
        sessao.add(
            Formacao(
                usuario_id=usuario.id,
                universidade_id=dados.universidade_id,
                curso_id=dados.curso_id,
                verificada_em=None,
            )
        )
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
        if await username_em_uso(sessao, novo_username, exceto=usuario_id):
            raise AppError(code="username_ja_existe", message="Username já existe", status_code=409)
        usuario.username = novo_username

    # `email` e `cpf` não estão em AtualizarPerfilIn, então não há como chegarem
    # aqui — a proteção é o tipo, não um `if`.
    for campo in ("nome_completo", "telefone", "bio", "foto_url"):
        if campo in campos:
            setattr(usuario, campo, campos[campo])

    usuario.alterado_em = datetime.now(UTC)
    await sessao.flush()
    await sessao.refresh(usuario)
    return usuario


async def buscar_pessoas(
    sessao: AsyncSession,
    termo: str,
    *,
    universidade_id: UUID | None = None,
    curso_id: UUID | None = None,
    tipos: tuple[TipoConta, ...] = (TipoConta.ALUNO, TipoConta.FACULDADE, TipoConta.EMPRESA),
    limite: int = 20,
) -> list[Usuario]:
    """Busca por username ou nome completo.

    `ILIKE` com curinga dos dois lados, apoiado no índice GIN trigram. Substitui
    o truque `isLessThan: '${termo}z'` do Firestore, que só casava prefixo —
    buscar "carvalho" não achava "Bruno Carvalho Lima".

    `universidade_id` filtra por **vínculo ativo**, não por formação declarada:
    "alunos desta instituição" significa quem ela confirmou, não quem digitou o
    nome dela no perfil.
    """
    if len(termo.strip()) < TERMO_MINIMO_DE_BUSCA:
        return []

    padrao = f"%{termo.strip()}%"
    consulta = (
        select(Usuario)
        .where(or_(Usuario.username.ilike(padrao), Usuario.nome_completo.ilike(padrao)))
        .where(Usuario.tipo.in_(tipos))
    )

    if universidade_id or curso_id:
        consulta = consulta.join(Vinculo, Vinculo.usuario_id == Usuario.id)
        if universidade_id:
            consulta = consulta.where(Vinculo.universidade_id == universidade_id)
        if curso_id:
            consulta = consulta.where(Vinculo.curso_id == curso_id)

    resultado = await sessao.execute(consulta.order_by(Usuario.username).limit(limite))
    return list(resultado.unique().scalars())


async def listar_universidades(
    sessao: AsyncSession, termo: str | None = None, limite: int | None = None
) -> list[Universidade]:
    consulta = select(Universidade).order_by(Universidade.sigla)
    if termo and termo.strip():
        padrao = f"%{termo.strip()}%"
        consulta = consulta.where(
            or_(Universidade.nome.ilike(padrao), Universidade.sigla.ilike(padrao))
        )
    if limite:
        consulta = consulta.limit(limite)
    return list((await sessao.execute(consulta)).scalars())


async def obter_universidade(sessao: AsyncSession, universidade_id: UUID) -> Universidade:
    universidade = await sessao.get(Universidade, universidade_id)
    if universidade is None:
        raise _nao_encontrado("Universidade não encontrada")
    return universidade


async def listar_cursos(sessao: AsyncSession, universidade_id: UUID) -> list[Curso]:
    await obter_universidade(sessao, universidade_id)
    resultado = await sessao.execute(
        select(Curso).where(Curso.universidade_id == universidade_id).order_by(Curso.nome)
    )
    return list(resultado.scalars())


async def garantir_par_valido(sessao: AsyncSession, universidade_id: UUID, curso_id: UUID) -> None:
    """O curso precisa pertencer à universidade informada.

    Sem esta checagem o banco aceitaria o par — as duas chaves estrangeiras são
    válidas isoladamente — e a formação apontaria para um curso de outra
    instituição. Não é desconfiança do usuário: os dois campos vêm de listas
    encadeadas na tela, então um par impossível indica requisição malformada.
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


async def username_em_uso(sessao: AsyncSession, username: str, *, exceto: UUID | None) -> bool:
    consulta = (
        select(func.count())
        .select_from(Usuario)
        .where(func.lower(Usuario.username) == username.lower())
    )
    if exceto:
        consulta = consulta.where(Usuario.id != exceto)
    return bool((await sessao.execute(consulta)).scalar_one())


async def email_em_uso(sessao: AsyncSession, email: str) -> bool:
    consulta = (
        select(func.count()).select_from(Usuario).where(func.lower(Usuario.email) == email.lower())
    )
    return bool((await sessao.execute(consulta)).scalar_one())


async def _cpf_em_uso(sessao: AsyncSession, cpf: str) -> bool:
    consulta = select(func.count()).select_from(Usuario).where(Usuario.cpf == cpf)
    return bool((await sessao.execute(consulta)).scalar_one())
