"""Rotas de perfil e busca de pessoas."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query

from user_service.api.deps import SessaoDep, TokenDeServico, UsuarioDep
from user_service.schemas import (
    AtualizarPerfilIn,
    CriarUsuarioIn,
    PaginaDePerfis,
    PerfilOut,
    PerfilPublicoOut,
    ResumoDePerfilOut,
)
from user_service.services import instituicoes, perfis, seguir

router = APIRouter(tags=["perfil"])


@router.get("/users/me", response_model=PerfilOut)
async def meu_perfil(sessao: SessaoDep, usuario: UsuarioDep) -> PerfilOut:
    return PerfilOut.model_validate(await perfis.obter(sessao, usuario.id))


@router.patch("/users/me", response_model=PerfilOut)
async def atualizar_meu_perfil(
    dados: AtualizarPerfilIn, sessao: SessaoDep, usuario: UsuarioDep
) -> PerfilOut:
    return PerfilOut.model_validate(await perfis.atualizar(sessao, usuario.id, dados))


@router.get("/users", response_model=PaginaDePerfis)
async def buscar_usuarios(
    sessao: SessaoDep,
    _: UsuarioDep,
    q: str = Query(min_length=2),
    universidadeId: UUID | None = None,
    cursoId: UUID | None = None,
    limit: int = Query(default=20, le=50),
) -> PaginaDePerfis:
    achados = await perfis.buscar_pessoas(
        sessao, q, universidade_id=universidadeId, curso_id=cursoId, limite=limit
    )
    return PaginaDePerfis(
        itens=[PerfilPublicoOut.model_validate(u) for u in achados],
        proximo_cursor=None,
    )


@router.get("/users/{userId}", response_model=PerfilPublicoOut)
async def perfil_de(
    userId: UUID,
    sessao: SessaoDep,
    _: UsuarioDep,
) -> PerfilPublicoOut:
    # `PerfilPublicoOut` omite e-mail, telefone e **CPF** por construção: os
    # campos não existem no tipo de saída, então não há como uma rota nova
    # esquecer de removê-los.
    return PerfilPublicoOut.model_validate(await perfis.obter(sessao, userId))


# ───────────────────────  rotas internas (serviço)  ───────────────────────


@router.post(
    "/users/interno",
    response_model=PerfilOut,
    status_code=201,
    include_in_schema=False,
    dependencies=[TokenDeServico],
)
async def criar_interno(dados: CriarUsuarioIn, sessao: SessaoDep) -> PerfilOut:
    """Cria o perfil durante o cadastro. Chamada pelo auth-service.

    `include_in_schema=False` a mantém fora do OpenAPI público — ela não é parte
    do contrato que o cliente Flutter consome, e o guarda de deriva em
    `test_contratos.py` a ignora pelo mesmo motivo.
    """
    return PerfilOut.model_validate(await perfis.criar(sessao, dados))


@router.get(
    "/users/interno/resumos",
    response_model=list[ResumoDePerfilOut],
    include_in_schema=False,
    dependencies=[TokenDeServico],
)
async def resumos_de_perfis(
    sessao: SessaoDep,
    ids: Annotated[list[UUID], Query(max_length=50)],
) -> list[ResumoDePerfilOut]:
    """Nome, arroba e foto de vários usuários de uma vez.

    Chamada pelo academic-service para montar os cards de comentário. Em lote
    porque uma página de 20 comentários de 5 pessoas deve custar uma consulta, e
    não vinte.

    **Registrada antes de `/users/interno/{userId}`**, e a ordem não é estética:
    os dois caminhos têm três segmentos, então a parametrizada capturaria
    "resumos" como identificador e o FastAPI responderia 422 ao validar o UUID —
    sem nunca chegar aqui.
    """
    encontrados = await perfis.resumos_de_usuarios(sessao, ids)
    return [ResumoDePerfilOut.model_validate(u) for u in encontrados]


@router.get(
    "/users/interno/{userId}/seguindo/universidades",
    response_model=list[UUID],
    include_in_schema=False,
    dependencies=[TokenDeServico],
)
async def universidades_do_escopo_interno(
    userId: UUID,
    sessao: SessaoDep,
) -> list[UUID]:
    """Os ids que compõem o escopo `geral` do feed acadêmico.

    Só ids: o academic-service vai usá-los num `IN`, e mandar nome e sigla aqui
    seria pagar por dados que ele resolve depois, em lote, apenas para as
    instituições que sobrarem na página.

    Reaproveita `seguir.listar_universidades` para a regra de que **a
    universidade do vínculo entra sempre**, mesmo sem registro de seguir, morar
    num lugar só. Reimplementá-la do outro lado é como o escopo "geral" acabaria
    excluindo justamente a instituição do aluno.

    Não concede nada. Esta lista decide QUAIS universidades entram no feed; o que
    o leitor pode ver dentro delas continua saindo do vínculo, que viaja no token.

    Para uma conta `faculdade`, a **universidade que ela administra** entra na
    lista. Pelo mesmo motivo da do vínculo: ela não é opcional, e sem isto o feed
    acadêmico da própria instituição nasceria vazio — a faculdade não veria o que
    acabou de publicar, porque conta institucional não tem vínculo.
    """
    ids = [u.id for u in await seguir.listar_universidades(sessao, userId)]
    propria = await instituicoes.universidade_administrada(sessao, userId)
    if propria is not None and propria not in ids:
        ids.insert(0, propria)
    return ids


@router.get(
    "/users/interno/{userId}",
    response_model=PerfilOut,
    include_in_schema=False,
    dependencies=[TokenDeServico],
)
async def perfil_interno(
    userId: UUID,
    sessao: SessaoDep,
) -> PerfilOut:
    """Perfil para o auth-service montar o access token, no login.

    Existe porque `GET /users/{userId}` exige JWT — e no login ainda não há token
    para apresentar: é justamente ele que está sendo emitido.

    Devolve `PerfilOut`, com `vinculo`, porque é de lá que saem os claims
    `vinculoUniversidadeId` e `vinculoCursoId`.
    """
    return PerfilOut.model_validate(await perfis.obter(sessao, userId))
