"""Formato de erro e health — o que os contratos prometem ao cliente Flutter."""

import pytest
from fastapi.testclient import TestClient
from pydantic import BaseModel

from integra_shared.app import criar_app
from integra_shared.errors import AppError
from integra_shared.security import UsuarioAtual


class _Corpo(BaseModel):
    email: str
    idade: int


@pytest.fixture
def cliente(settings):
    async def _saudavel() -> bool:
        return True

    async def _fora() -> bool:
        return False

    async def _explode() -> bool:
        raise RuntimeError("driver caiu")

    app = criar_app("teste-service", verificacoes={"database": _saudavel}, settings=settings)

    quebrado = criar_app("quebrado", verificacoes={"database": _fora}, settings=settings)
    explodindo = criar_app("explodindo", verificacoes={"database": _explode}, settings=settings)

    @app.post("/eco")
    async def _eco(corpo: _Corpo) -> dict:
        return {"ok": True, "email": corpo.email}

    @app.get("/negocio")
    async def _negocio() -> dict:
        raise AppError(
            code="username_ja_existe",
            message="Username já existe",
            status_code=409,
        )

    @app.get("/protegido")
    async def _protegido(usuario: UsuarioAtual) -> dict:
        return {"id": str(usuario.id)}

    return TestClient(app), TestClient(quebrado), TestClient(explodindo)


def test_health_ok(cliente):
    saudavel, _, _ = cliente
    r = saudavel.get("/health")

    assert r.status_code == 200
    corpo = r.json()
    assert corpo["status"] == "ok"
    assert corpo["service"] == "teste-service"
    assert corpo["dependencies"] == {"database": "ok"}


def test_health_degradado_responde_503(cliente):
    """503, não 200: com 200 o Traefik segue mandando tráfego para um serviço sem banco."""
    _, quebrado, _ = cliente
    r = quebrado.get("/health")

    assert r.status_code == 503
    assert r.json()["status"] == "degraded"
    assert r.json()["dependencies"]["database"] == "unreachable"


def test_verificacao_que_estoura_nao_derruba_o_health(cliente):
    _, _, explodindo = cliente
    r = explodindo.get("/health")

    assert r.status_code == 503
    assert r.json()["dependencies"]["database"] == "unreachable"


def test_erro_de_validacao_sai_no_formato_do_contrato(cliente):
    saudavel, _, _ = cliente
    r = saudavel.post("/eco", json={"email": "ana@exemplo.com"})

    assert r.status_code == 422
    corpo = r.json()
    # E não o `{"detail": [...]}` padrão do FastAPI, que o cliente não sabe ler.
    assert "detail" not in corpo
    assert corpo["code"] == "validation_error"
    assert corpo["message"] == "Verifique os campos destacados"
    assert corpo["fields"] == {"idade": ["Campo obrigatório"]}


def test_campo_aninhado_vira_caminho_pontuado(cliente):
    saudavel, _, _ = cliente
    r = saudavel.post("/eco", json={"email": "ana@exemplo.com", "idade": "vinte"})

    assert r.status_code == 422
    assert list(r.json()["fields"]) == ["idade"]


def test_app_error_vira_corpo_do_contrato(cliente):
    saudavel, _, _ = cliente
    r = saudavel.get("/negocio")

    assert r.status_code == 409
    assert r.json() == {"code": "username_ja_existe", "message": "Username já existe"}


def test_rota_protegida_sem_token_responde_401_no_formato(cliente):
    saudavel, _, _ = cliente
    r = saudavel.get("/protegido")

    assert r.status_code == 401
    assert r.json()["code"] == "nao_autenticado"


def test_rota_inexistente_tambem_sai_no_formato(cliente):
    saudavel, _, _ = cliente
    r = saudavel.get("/nao-existe")

    assert r.status_code == 404
    assert r.json()["code"] == "http_404"
