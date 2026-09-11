"""Fumaça: o serviço sobe e responde /health. Sem isso, o gate da Sprint 1 é fé."""

from fastapi.testclient import TestClient

from user_service.main import app


def test_health_responde():
    r = TestClient(app).get("/health")

    assert r.status_code == 200
    corpo = r.json()
    assert corpo["status"] == "ok"
    assert corpo["service"] == "user-service"
