"""A URL pré-assinada para a imagem de um post.

Registrada num router próprio, incluído **antes** do de posts em `main.py`:
`/feed/posts/imagem/upload-url` e `/feed/posts/{postId}` competem, e a parametrizada
capturaria "imagem" como identificador — o FastAPI responderia 422 ao validar o UUID
sem nunca chegar aqui. É o mesmo cuidado que `/users/interno/resumos` exigiu no
user-service.
"""

from fastapi import APIRouter

from feed_service.api.deps import UsuarioDep
from feed_service.schemas import UploadUrlIn, UploadUrlOut
from feed_service.settings import settings
from integra_shared import armazenamento

router = APIRouter(prefix="/feed", tags=["arquivos"])


@router.post("/posts/imagem/upload-url", response_model=UploadUrlOut, status_code=201)
async def url_de_upload(dados: UploadUrlIn, usuario: UsuarioDep) -> UploadUrlOut:
    """Assina um `PUT` para o cliente enviar a imagem direto ao storage.

    O caminho do objeto é derivado do id de quem pede — o cliente não o escolhe, e
    por isso não há como sobrescrever a imagem de outra pessoa.

    Não exige `AutorDep`: pedir URL não publica nada. Uma conta pendente que peça a
    URL e envie o arquivo vai ser recusada no `POST /feed/posts`, e o que sobra é um
    objeto órfão no bucket — mais barato que uma ida extra ao user-service em cada
    composição de post, e é o que a política de ciclo de vida do prefixo `posts/`
    limpa.
    """
    emitido = armazenamento.emitir_upload(
        settings,
        prefixo="posts",
        conta_id=usuario.id,
        content_type=dados.content_type,
        tamanho_bytes=dados.tamanho_bytes,
    )
    return UploadUrlOut(
        upload_url=emitido.upload_url,
        imagem_url=emitido.url_publica,
        expira_em=emitido.expira_em,
    )
