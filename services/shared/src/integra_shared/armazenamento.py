"""URLs pré-assinadas para upload de imagem. Bytes nunca atravessam os serviços.

## O fluxo, em três passos

    1. cliente  -> POST .../upload-url   (contentType, tamanhoBytes)
    2. cliente  -> PUT uploadUrl         o arquivo, direto no storage
    3. cliente  -> PATCH /users/me       grava a fotoUrl devolvida no passo 1

O serviço assina e sai do caminho. A alternativa — receber o multipart e repassar —
faria cada upload ocupar um worker do uvicorn pelo tempo da conexão do celular, e
um serviço de perfil ficaria indisponível por causa de fotos.

## Assinar não é I/O

`generate_presigned_url` **não chama o storage**: é HMAC sobre a requisição que o
cliente vai fazer. Duas consequências, e as duas importam:

- O serviço não precisa alcançar o storage para emitir a URL. Um storage fora do ar
  ainda emite URL — e o `PUT` do cliente é que falha, onde o cliente pode tentar de
  novo.
- **O endpoint que vale é o que o CLIENTE alcança**, não o da rede interna. Assinar
  contra `http://minio:9000` renderia uma URL que só funciona de dentro do compose,
  e o celular receberia um host que não resolve. Por isso há um endpoint só na
  configuração, e ele é o público.

## O que a assinatura trava, e por que trava

O caminho do objeto é **derivado do id de quem pede**, nunca escolhido pelo
cliente: `{prefixo}/{conta}/{uuid}.{ext}`. Sem isso, um cliente pediria URL para o
caminho do avatar de outra pessoa e sobrescreveria a foto dela — a URL assinada
vale para o que ela diz, e quem escolhe o que ela diz é este módulo.

`Content-Type` e `Content-Length` entram **na assinatura**, e é o que faz o limite
de tamanho ser real: o storage recusa um `PUT` cujo `content-length` não seja
exatamente o declarado. Sem assiná-los, "tamanhoBytes" seria uma declaração de boa
vontade, e nada impediria 500 MB numa URL pedida para 2 KB.

## Sem chave configurada, não há upload

`emitir_upload` levanta 503 quando o storage não está configurado. É o caso do
ambiente local sem MinIO: o serviço **sobe**, as outras rotas funcionam, e só o
upload responde "tente novamente em instantes". Um default aqui — bucket de
exemplo, chave vazia — produziria URLs que falham no `PUT` com erro do storage, e
o cliente culparia o próprio arquivo.
"""

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

from integra_shared.config import Settings
from integra_shared.errors import AppError

# As três que o contrato declara. Mapeadas para extensão porque o caminho do objeto
# precisa de uma — o storage serve pelo `Content-Type` gravado, mas um objeto sem
# extensão baixa como arquivo sem tipo quando alguém abre a URL direto.
EXTENSOES = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}

TAMANHO_MAXIMO = 5 * 1024 * 1024


@dataclass(frozen=True)
class UploadEmitido:
    """O que a rota devolve: onde enviar, o que gravar depois, e até quando vale."""

    upload_url: str
    url_publica: str
    expira_em: datetime


def _indisponivel() -> AppError:
    return AppError(
        code="dependencia_indisponivel",
        message="Não foi possível preparar o envio agora. Tente novamente em instantes.",
        status_code=503,
    )


def _campo_invalido(campo: str, mensagem: str) -> AppError:
    return AppError(
        code="validation_error",
        message="Verifique os campos destacados",
        status_code=422,
        fields={campo: [mensagem]},
    )


def emitir_upload(
    settings: Settings,
    prefixo: str,
    conta_id: UUID,
    content_type: str,
    tamanho_bytes: int,
) -> UploadEmitido:
    """Assina um `PUT` de um arquivo, num caminho que o cliente não escolhe.

    `prefixo` separa os usos no bucket (`avatares/`, `posts/`) para uma política de
    ciclo de vida poder tratá-los diferente: avatar substituído é lixo no dia
    seguinte, imagem de post vive enquanto o post viver.

    As duas validações aqui repetem o que o Pydantic já cobre pelo schema, e a
    repetição é deliberada: este módulo é chamado por dois serviços, e um terceiro
    que esqueça o `enum` no schema não deve conseguir assinar um `.exe`.
    """
    extensao = EXTENSOES.get(content_type)
    if extensao is None:
        raise _campo_invalido("contentType", "Envie uma imagem JPEG, PNG ou WebP")
    if not 0 < tamanho_bytes <= TAMANHO_MAXIMO:
        raise _campo_invalido("tamanhoBytes", "A imagem deve ter até 5 MB")

    cliente = _cliente(settings)
    chave = f"{prefixo}/{conta_id}/{uuid4()}.{extensao}"

    try:
        upload_url = cliente.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": settings.storage_bucket,
                "Key": chave,
                # Os dois entram na assinatura: o storage recusa o `PUT` que não
                # trouxer exatamente estes valores. É o que faz o limite de tamanho
                # ser do storage, e não uma promessa do cliente.
                "ContentType": content_type,
                "ContentLength": tamanho_bytes,
            },
            ExpiresIn=settings.upload_ttl_segundos,
        )
    except Exception as erro:
        # Assinar é computação local, então cair aqui significa configuração
        # inválida (região malformada, endpoint sem esquema), e não storage fora do
        # ar. Para quem está na tela dá no mesmo, e o 503 é a mesma mensagem.
        raise _indisponivel() from erro

    return UploadEmitido(
        upload_url=upload_url,
        url_publica=f"{settings.storage_endpoint.rstrip('/')}/{settings.storage_bucket}/{chave}",  # type: ignore[union-attr]
        expira_em=datetime.now(UTC) + timedelta(seconds=settings.upload_ttl_segundos),
    )


def _cliente(settings: Settings):
    """Cliente S3 por chamada, e a razão é a mesma do cliente HTTP de `interno`.

    Um cliente global economizaria a montagem do modelo do botocore, mas guardaria
    estado ligado ao processo em que nasceu. Assinar é barato e local; não vale
    cachear e ganhar um objeto compartilhado entre requisições.
    """
    if not settings.storage_configurado:
        raise _indisponivel()

    # Importado aqui, e não no topo: boto3 monta o modelo de serviço na importação,
    # e é o único import caro do processo. Um serviço que nunca emite upload não
    # deve pagá-lo no boot.
    import boto3
    from botocore.config import Config

    return boto3.client(
        "s3",
        endpoint_url=settings.storage_endpoint,
        aws_access_key_id=settings.storage_access_key,
        aws_secret_access_key=settings.storage_secret_key,
        region_name=settings.storage_regiao,
        # `s3v4` explícito e `path` como estilo de endereço: MinIO e o Object
        # Storage da Oracle servem por caminho (`host/bucket/chave`), não por
        # subdomínio. Com o padrão (`virtual`), a URL assinada aponta para
        # `bucket.localhost:9000` — um host que não resolve, e o sintoma é um
        # `PUT` que nem sai do celular.
        config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
    )
