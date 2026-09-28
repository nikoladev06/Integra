"""Rotas de comentário.

Nenhuma delas confia no id do post que recebe: as três passam por
`posts.garantir_visivel` dentro do serviço. Checar visibilidade na leitura e
esquecer na escrita é o erro clássico deste desenho, e listar comentários de um
post restrito é a forma mais discreta dele — o post nunca aparece na resposta, só
a conversa que acontece embaixo.
"""

from uuid import UUID

from fastapi import APIRouter, Query, Response

from academic_service import apresentacao
from academic_service.api.deps import SessaoDep, UsuarioDep
from academic_service.paginacao import LIMITE_MAXIMO, LIMITE_PADRAO
from academic_service.schemas import ComentarIn, ComentarioOut, PaginaDeComentarios
from academic_service.services import comentarios, posts
from integra_shared.errors import AppError

router = APIRouter(prefix="/academic", tags=["comentários"])


@router.get("/posts/{postId}/comentarios", response_model=PaginaDeComentarios)
async def listar(
    postId: UUID,
    sessao: SessaoDep,
    usuario: UsuarioDep,
    limit: int = Query(default=LIMITE_PADRAO, ge=1, le=LIMITE_MAXIMO),
    cursor: str | None = None,
) -> PaginaDeComentarios:
    """Do mais antigo para o mais novo — conversa se lê na ordem em que aconteceu."""
    post = await posts.garantir_visivel(sessao, postId, usuario)
    pagina, proximo = await comentarios.listar(sessao, postId, usuario, limit, cursor)
    return PaginaDeComentarios(
        itens=await apresentacao.montar_comentarios(pagina, post, usuario),
        proximo_cursor=proximo,
    )


@router.post("/posts/{postId}/comentarios", response_model=ComentarioOut, status_code=201)
async def comentar(
    postId: UUID,
    dados: ComentarIn,
    sessao: SessaoDep,
    usuario: UsuarioDep,
) -> ComentarioOut:
    """Comenta, se puder ver o post.

    Qualquer tipo de conta comenta, inclusive a `faculdade` autora respondendo no
    próprio comunicado — restringir a `aluno` faria a instituição precisar de outro
    canal para responder à pergunta que alguém fez ali.
    """
    post = await posts.garantir_visivel(sessao, postId, usuario)
    criado = await comentarios.comentar(sessao, postId, usuario, dados)
    montados = await apresentacao.montar_comentarios([criado], post, usuario)

    if not montados:
        # A montagem descarta comentário cujo autor o user-service não conhece.
        # Aqui o autor é quem está chamando, com token válido, então isto só
        # acontece se o perfil dele tiver desaparecido no meio da requisição — e
        # aí o comentário foi gravado e não há o que devolver. 503 em vez de um
        # IndexError, que viraria 500 sem dizer nada.
        raise AppError(
            code="dependencia_indisponivel",
            message="Comentário publicado, mas não foi possível carregá-lo. Recarregue a lista.",
            status_code=503,
        )

    return montados[0]


@router.delete("/comentarios/{comentarioId}", status_code=204)
async def remover(comentarioId: UUID, sessao: SessaoDep, usuario: UsuarioDep) -> Response:
    """Autor do comentário, ou a faculdade autora do post (moderação)."""
    await comentarios.remover(sessao, comentarioId, usuario)
    return Response(status_code=204)
