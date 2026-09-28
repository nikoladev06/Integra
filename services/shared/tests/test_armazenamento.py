"""A assinatura de URL de upload, sem storage no ar.

Assinar é HMAC local, então este teste não precisa de MinIO — e é justamente o que ele
prova de mais útil: o serviço emite a URL sem alcançar o storage.

O que os casos guardam:

- **as duas validações**, que não estão no schema de nenhum serviço de propósito: elas
  vivem aqui para um terceiro serviço que esqueça o `enum` não conseguir assinar um
  `.exe`;
- **o caminho derivado do id de quem pede**, que é o que impede alguém de pedir URL
  para o avatar de outra pessoa;
- **o `Content-Length` na assinatura**, que é o que faz o limite de tamanho ser do
  storage e não uma promessa do cliente;
- **o endereçamento por caminho**, porque com o padrão (`virtual`) a URL aponta para
  `bucket.localhost:9000` — um host que não resolve, e o sintoma é um `PUT` que nem sai
  do celular.
"""

from urllib.parse import parse_qs, urlparse
from uuid import uuid4

import pytest

from integra_shared import armazenamento
from integra_shared.config import Settings
from integra_shared.errors import AppError

CONTA = uuid4()


def _settings(**trocas) -> Settings:
    base = {
        "jwt_secret": "segredo-de-teste-com-32-caracteres-ok",
        "storage_endpoint": "http://localhost:9000",
        "storage_bucket": "integra",
        "storage_access_key": "integra",
        "storage_secret_key": "integra-minio-dev",
    }
    return Settings(**{**base, **trocas})  # type: ignore[arg-type]


def _emitir(**trocas):
    return armazenamento.emitir_upload(
        _settings(**trocas.pop("settings", {})),
        prefixo="avatares",
        conta_id=CONTA,
        content_type=trocas.pop("content_type", "image/jpeg"),
        tamanho_bytes=trocas.pop("tamanho_bytes", 120_000),
    )


def test_a_url_publica_leva_o_id_de_quem_pediu_e_nao_um_caminho_do_cliente():
    """É o que impede pedir URL para o avatar de outra pessoa e sobrescrever a foto."""
    emitido = _emitir()
    assert emitido.url_publica.startswith(f"http://localhost:9000/integra/avatares/{CONTA}/")
    assert emitido.url_publica.endswith(".jpg")


def test_o_caminho_nunca_repete_entre_dois_pedidos():
    """Sem isto, dois envios da mesma conta disputariam o mesmo objeto."""
    assert _emitir().url_publica != _emitir().url_publica


def test_o_content_length_entra_na_assinatura():
    """É o que faz o limite de tamanho ser do storage, e não uma declaração do cliente."""
    assinados = parse_qs(urlparse(_emitir().upload_url).query)["X-Amz-SignedHeaders"][0]
    assert "content-length" in assinados
    assert "content-type" in assinados


def test_o_endereco_e_por_caminho_e_nao_por_subdominio():
    """Com `virtual`, a URL apontaria para `integra.localhost:9000`, que não resolve."""
    destino = urlparse(_emitir().upload_url)
    assert destino.netloc == "localhost:9000"
    assert destino.path.startswith("/integra/avatares/")


def test_a_url_expira_e_a_validade_vem_da_configuracao():
    assinada = parse_qs(urlparse(_emitir().upload_url).query)
    assert assinada["X-Amz-Expires"] == ["300"]


@pytest.mark.parametrize("tipo", ["application/pdf", "image/gif", "text/html", ""])
def test_tipo_fora_das_tres_imagens_e_recusado_nomeando_o_campo(tipo):
    with pytest.raises(AppError) as erro:
        _emitir(content_type=tipo)
    assert erro.value.status_code == 422
    assert "contentType" in (erro.value.fields or {})


@pytest.mark.parametrize("tamanho", [0, -1, 5 * 1024 * 1024 + 1])
def test_tamanho_fora_da_faixa_e_recusado_nomeando_o_campo(tamanho):
    with pytest.raises(AppError) as erro:
        _emitir(tamanho_bytes=tamanho)
    assert erro.value.status_code == 422
    assert "tamanhoBytes" in (erro.value.fields or {})


def test_o_limite_de_5_mb_e_inclusivo():
    """A borda exata, porque `<` e `<=` errados aqui recusam um arquivo válido."""
    assert _emitir(tamanho_bytes=armazenamento.TAMANHO_MAXIMO).upload_url


def test_sem_chave_configurada_responde_503_e_o_servico_continua_de_pe():
    """O ambiente local sem MinIO: só o upload falha, e o resto da API funciona.

    Um default de bucket e chave vazia produziria URLs que falham no `PUT` com erro do
    storage — e o cliente culparia o próprio arquivo.
    """
    with pytest.raises(AppError) as erro:
        _emitir(settings={"storage_access_key": None, "storage_secret_key": None})
    assert erro.value.status_code == 503
    assert erro.value.code == "dependencia_indisponivel"
