"""Universidades: catálogo público, perfil, e a administração que cada uma faz."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query, Response

from user_service.api.deps import (
    FaculdadeAtivaDep,
    FaculdadeDep,
    SessaoDep,
    TokenDeServico,
    UsuarioDep,
)
from user_service.schemas import (
    CriarCursoIn,
    CriarInstituicaoIn,
    CriarMatriculaIn,
    CursoOut,
    MatriculaOut,
    PerfilDeUniversidadeOut,
    PerfilOut,
    PerfilPublicoOut,
    ResumoDeUniversidadeOut,
    UniversidadeDaContaOut,
    UniversidadeOut,
)
from user_service.services import instituicoes, perfis, seguir

router = APIRouter(tags=["instituições"])

# ORDEM DE REGISTRO IMPORTA, e não é estética.
#
# `/universidades/me/cursos` e `/universidades/{universidadeId}/cursos` têm o
# mesmo número de segmentos. Registrada primeiro, a parametrizada captura "me"
# como identificador e o FastAPI responde 422 ao validar o UUID — sem nunca
# chegar na rota certa. Por isso as literais vêm todas antes das parametrizadas
# neste arquivo. Mover uma função para cima ou para baixo quebra rota.


@router.post(
    "/universidades/interno/conta",
    response_model=PerfilOut,
    status_code=201,
    include_in_schema=False,
    dependencies=[TokenDeServico],
)
async def criar_conta_interna(dados: CriarInstituicaoIn, sessao: SessaoDep) -> PerfilOut:
    """Cria a conta institucional. Chamada pelo auth-service no cadastro.

    Fora do OpenAPI público: não é parte do contrato que o cliente consome, e o
    guarda de deriva a ignora pelo mesmo motivo.
    """
    conta = await instituicoes.criar_conta(sessao, dados)
    return PerfilOut.model_validate(conta)


@router.get(
    "/universidades/interno/resumos",
    response_model=list[ResumoDeUniversidadeOut],
    include_in_schema=False,
    dependencies=[TokenDeServico],
)
async def resumos_de_universidades(
    sessao: SessaoDep,
    ids: Annotated[list[UUID], Query(max_length=50)],
) -> list[ResumoDeUniversidadeOut]:
    """Nome, sigla e foto de várias universidades de uma vez.

    O cabeçalho dos cards de post, resolvido pelo academic-service na leitura em
    vez de copiado para dentro de cada post na publicação. O limite de 50 é o
    tamanho máximo de uma página de feed: mais ids que isso não vêm de um caso
    de uso real.
    """
    encontradas = await perfis.resumos_de_universidades(sessao, ids)
    return [ResumoDeUniversidadeOut.model_validate(u) for u in encontradas]


@router.get(
    "/universidades/interno/de-conta/{contaId}",
    response_model=UniversidadeDaContaOut,
    include_in_schema=False,
    dependencies=[TokenDeServico],
)
async def universidade_da_conta_interna(
    contaId: UUID,
    sessao: SessaoDep,
) -> UniversidadeDaContaOut:
    """Tudo que o academic-service precisa para autorizar uma publicação.

    As três coisas numa chamada, e cada uma por um motivo:

    - **a universidade da conta** — porque a universidade do post é a do autor, e
      não um campo do corpo: aceitá-lo do cliente deixaria uma faculdade publicar
      no nome de outra;
    - **`contaAtiva`** — porque a conta institucional nasce pendente, e a checagem
      tem que consultar o banco: no JWT, uma conta desativada seguiria publicando
      por até 15 minutos;
    - **os cursos** — porque `visibilidade: curso` exige um curso *desta*
      instituição, e quem é dono dessa lista é este serviço.
    """
    universidade = await instituicoes.universidade_da_conta(sessao, contaId)
    conta = await perfis.obter(sessao, contaId)
    cursos = await instituicoes.listar_cursos(sessao, universidade.id)

    return UniversidadeDaContaOut(
        id=universidade.id,
        nome=universidade.nome,
        sigla=universidade.sigla,
        foto_url=universidade.foto_url,
        cursos=[CursoOut.model_validate(c) for c in cursos],
        conta_ativa=conta.ativa,
    )


# ─────────────────────────  catálogo público  ─────────────────────────


@router.get("/universidades", response_model=list[UniversidadeOut])
async def listar_universidades(sessao: SessaoDep, q: str | None = None) -> list[UniversidadeOut]:
    """Sem autenticação: alimenta o combobox de formação na tela de cadastro."""
    encontradas = await perfis.listar_universidades(sessao, q)
    return [UniversidadeOut.model_validate(u) for u in encontradas]


@router.get("/universidades/me/cursos", response_model=list[CursoOut])
async def meus_cursos(sessao: SessaoDep, conta: FaculdadeDep) -> list[CursoOut]:
    universidade = await instituicoes.universidade_da_conta(sessao, conta.id)
    cursos = await instituicoes.listar_cursos(sessao, universidade.id)
    return [CursoOut.model_validate(c) for c in cursos]


@router.post("/universidades/me/cursos", response_model=CursoOut, status_code=201)
async def criar_curso(dados: CriarCursoIn, sessao: SessaoDep, conta: FaculdadeAtivaDep) -> CursoOut:
    universidade = await instituicoes.universidade_da_conta(sessao, conta.id)
    criado = await instituicoes.criar_curso(sessao, universidade.id, dados.nome)
    return CursoOut.model_validate(criado)


@router.get("/universidades/me/matriculas", response_model=list[MatriculaOut])
async def listar_matriculas(
    sessao: SessaoDep,
    conta: FaculdadeDep,
    cursoId: UUID | None = None,
    situacao: str = Query(default="todas", pattern="^(todas|pendentes|vinculadas)$"),
) -> list[MatriculaOut]:
    universidade = await instituicoes.universidade_da_conta(sessao, conta.id)
    linhas = await instituicoes.listar_matriculas(
        sessao, universidade.id, curso_id=cursoId, situacao=situacao
    )
    return [
        MatriculaOut(
            id=matricula.id,
            # O CPF sai apenas aqui, para a instituição que o cadastrou — foi ela
            # que o digitou. Nunca em resposta pública nem para outra instituição.
            cpf=matricula.cpf,
            curso=CursoOut.model_validate(matricula.curso),
            vinculada=dono is not None,
            usuario=PerfilPublicoOut.model_validate(dono) if dono else None,
            criado_em=matricula.criado_em,
        )
        for matricula, dono in linhas
    ]


@router.post("/universidades/me/matriculas", response_model=MatriculaOut, status_code=201)
async def criar_matricula(
    dados: CriarMatriculaIn, sessao: SessaoDep, conta: FaculdadeAtivaDep
) -> MatriculaOut:
    """Cadastra um aluno por CPF. Pode acontecer antes de a conta dele existir."""
    universidade = await instituicoes.universidade_da_conta(sessao, conta.id)
    criada = await instituicoes.criar_matricula(sessao, universidade.id, dados.cpf, dados.curso_id)
    return MatriculaOut(
        id=criada.id,
        cpf=criada.cpf,
        curso=CursoOut.model_validate(criada.curso),
        vinculada=False,
        usuario=None,
        criado_em=criada.criado_em,
    )


@router.get("/universidades/{universidadeId}", response_model=PerfilDeUniversidadeOut)
async def perfil_da_universidade(
    universidadeId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> PerfilDeUniversidadeOut:
    """A tela que o aluno alcança pela busca.

    `temVinculo` é o que decide se o menu oferece "inserir CPF" ou "encerrar
    vínculo" — calculado aqui, e não inferido no cliente, para a tela não ter que
    cruzar duas respostas.
    """
    universidade = await perfis.obter_universidade(sessao, universidadeId)
    return PerfilDeUniversidadeOut(
        id=universidade.id,
        nome=universidade.nome,
        sigla=universidade.sigla,
        bio=universidade.bio,
        foto_url=universidade.foto_url,
        tem_vinculo=usuario.tem_vinculo_com(universidadeId),
        seguindo=await seguir.segue_universidade(sessao, usuario.id, universidadeId),
    )


@router.get("/universidades/{universidadeId}/cursos", response_model=list[CursoOut])
async def listar_cursos(
    universidadeId: UUID,
    sessao: SessaoDep,
) -> list[CursoOut]:
    """Os cursos que a própria instituição cadastrou. Sem autenticação."""
    cursos = await perfis.listar_cursos(sessao, universidadeId)
    return [CursoOut.model_validate(c) for c in cursos]


# ───────────────────  administração da própria instituição  ───────────────────


@router.delete("/universidades/me/cursos/{cursoId}", status_code=204)
async def remover_curso(
    cursoId: UUID,
    sessao: SessaoDep,
    conta: FaculdadeAtivaDep,
) -> Response:
    universidade = await instituicoes.universidade_da_conta(sessao, conta.id)
    await instituicoes.remover_curso(sessao, universidade.id, cursoId)
    return Response(status_code=204)


@router.delete("/universidades/me/matriculas/{matriculaId}", status_code=204)
async def remover_matricula(
    matriculaId: UUID,
    sessao: SessaoDep,
    conta: FaculdadeAtivaDep,
) -> Response:
    """Remove a matrícula e encerra o vínculo. A formação segue verificada."""
    universidade = await instituicoes.universidade_da_conta(sessao, conta.id)
    await instituicoes.remover_matricula(sessao, universidade.id, matriculaId)
    return Response(status_code=204)
