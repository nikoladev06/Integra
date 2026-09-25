"""Fumaça do user-service: o app sobe e se identifica.

Estes testes NÃO afirmam se o /health está ok ou degradado. Isso depende de o
banco do ambiente estar no ar, e a primeira versão deles passava só por acidente
— o DSN padrão do conftest aponta para um banco inexistente, então respondiam 503.
Rodando com INTEGRA_DATABASE_URL apontando para um Postgres de verdade, quebravam.

Os dois estados do /health são verificados em `shared/tests/test_app.py`, com as
verificações injetadas, que é onde a condição pode ser controlada em vez de lida
do ambiente.
"""

from fastapi.testclient import TestClient

from user_service.main import app


def test_health_responde_e_identifica_o_servico():
    r = TestClient(app).get("/health")

    # Os dois códigos são respostas válidas: 200 com banco no ar, 503 sem.
    assert r.status_code in (200, 503)

    corpo = r.json()
    assert corpo["service"] == "user-service"
    assert corpo["status"] in ("ok", "degraded")
    # Coerência entre status e código: um 200 com "degraded" faria o Traefik
    # seguir mandando tráfego para um serviço sem banco.
    assert (r.status_code == 200) == (corpo["status"] == "ok")


def test_o_banco_e_uma_dependencia_declarada():
    """O /health tem que CHECAR o banco, não só responder.

    Sem esta asserção, remover a verificação do main.py deixaria o endpoint
    respondendo 200 sempre — e a suíte verde.
    """
    corpo = TestClient(app).get("/health").json()
    assert "database" in corpo["dependencies"]
