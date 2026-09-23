"""Fumaça do user-service: o app sobe e o /health reflete o estado do banco."""

from fastapi.testclient import TestClient

from user_service.main import app


def test_health_reporta_banco_inalcancavel_com_503():
    """503, não 200, quando o banco não responde.

    Foi escrito na Sprint 1 esperando 200, quando /health não checava nada. A
    partir da Sprint 3 ele pinga o Postgres — e com o DSN de teste apontando
    para um banco que não existe, degradado é a resposta certa. Com 200 aqui, o
    Traefik seguiria mandando tráfego para um serviço sem banco.
    """
    r = TestClient(app).get("/health")

    assert r.status_code == 503
    corpo = r.json()
    assert corpo["status"] == "degraded"
    assert corpo["service"] == "user-service"
    assert corpo["dependencies"]["database"] == "unreachable"
