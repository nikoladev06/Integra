"""Fumaça do academic-service: o app sobe, se identifica, e o cursor fecha o ciclo.

Como nos outros serviços, estes testes **não** afirmam se o `/health` está ok ou
degradado: isso depende de o banco do ambiente estar no ar. Os dois estados são
verificados em `shared/tests/test_app.py`, com as verificações injetadas.
"""

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from academic_service.main import app
from integra_shared import paginacao
from integra_shared.errors import AppError


def test_health_responde_e_identifica_o_servico():
    r = TestClient(app).get("/health")

    assert r.status_code in (200, 503)

    corpo = r.json()
    assert corpo["service"] == "academic-service"
    assert corpo["status"] in ("ok", "degraded")
    # Um 200 com "degraded" faria o Traefik seguir mandando tráfego para um
    # serviço sem banco.
    assert (r.status_code == 200) == (corpo["status"] == "ok")


def test_o_banco_e_uma_dependencia_declarada():
    """O /health tem que CHECAR o banco, não só responder."""
    assert "database" in TestClient(app).get("/health").json()["dependencies"]


def test_toda_rota_de_post_exige_autenticacao():
    """Nenhuma rota do serviço é pública — nem a de leitura.

    O feed depende de quem está lendo: sem token não há vínculo, e sem vínculo não
    há como decidir alcance. Uma rota aberta aqui devolveria "os públicos de todo
    mundo", que não é um produto que exista nesta tela.
    """
    cliente = TestClient(app)
    id_ = uuid4()

    chamadas = [
        cliente.get("/academic/posts"),
        cliente.post("/academic/posts", json={"conteudo": "x", "visibilidade": "publico"}),
        cliente.get(f"/academic/posts/{id_}"),
        cliente.patch(f"/academic/posts/{id_}", json={"conteudo": "x"}),
        cliente.delete(f"/academic/posts/{id_}"),
        cliente.put(f"/academic/posts/{id_}/curtidas"),
        cliente.delete(f"/academic/posts/{id_}/curtidas"),
        cliente.get(f"/academic/posts/{id_}/comentarios"),
        cliente.post(f"/academic/posts/{id_}/comentarios", json={"conteudo": "x"}),
        cliente.delete(f"/academic/comentarios/{id_}"),
        cliente.get(f"/academic/universidades/{id_}/posts"),
    ]

    assert [r.status_code for r in chamadas] == [401] * len(chamadas)


# ──────────────────────────────  cursor  ──────────────────────────────


def test_o_cursor_sobrevive_a_ida_e_volta():
    quando = datetime(2026, 9, 26, 14, 30, 5, 123456, tzinfo=UTC)
    id_ = uuid4()

    assert paginacao.decodificar(paginacao.codificar(quando, id_)) == (quando, id_)


def test_o_cursor_nao_carrega_caractere_que_quebre_query_string():
    """Sem `=`, `+` nem `/`: base64**url**, com o padding removido.

    Um `+` num cursor colado em query string chega ao servidor como espaço, e a
    página seguinte responde 422 em vez de continuar a lista.
    """
    cursor = paginacao.codificar(datetime.now(UTC), uuid4())

    assert not set(cursor) & set("=+/")


@pytest.mark.parametrize(
    "invalido",
    [
        "nao-e-base64",
        "YWJjZGVm",  # base64 válido, conteúdo sem o separador
        "MjAyNi0wOS0yNnxuYW8tZS11dWlk",  # data ok, id inválido
    ],
)
def test_cursor_invalido_e_erro_do_cliente_e_nao_500(invalido):
    """422 com o campo nomeado. Acontece quando alguém edita a query à mão.

    String vazia não está na lista de propósito: para as rotas ela significa
    "primeira página", e o decodificador nem é chamado.
    """
    with pytest.raises(AppError) as erro:
        paginacao.decodificar(invalido)

    assert erro.value.status_code == 422
    assert "cursor" in (erro.value.fields or {})


def test_o_limite_e_grampeado_nas_duas_pontas():
    """Segunda linha de defesa: o `Query(le=...)` do FastAPI é a primeira.

    Existe para as chamadas internas — testes, e rotas que compõem listas — não
    conseguirem pedir dez mil posts por engano.
    """
    assert paginacao.limite_valido(10_000) == paginacao.LIMITE_MAXIMO
    assert paginacao.limite_valido(0) == 1
    assert paginacao.limite_valido(20) == 20
