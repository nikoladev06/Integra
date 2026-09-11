"""Guarda de deriva entre `contracts/` e o que os serviços realmente expõem.

"Contrato primeiro" só é verdade se algo verificar. Sem isto, os arquivos em
`contracts/` viram documentação que envelhece — e o cliente Flutter é escrito
contra uma promessa que o servidor não cumpre mais.

A checagem é assimétrica de propósito, porque as duas derivas têm gravidade
diferente:

- **Rota implementada que não está no contrato** → falha agora. É a deriva
  perigosa: uma rota que ninguém revisou, que o cliente não conhece, e que
  costuma ser onde a checagem de permissão foi esquecida.
- **Rota no contrato ainda não implementada** → só reportada. Na Sprint 1 isso é
  o estado normal: o contrato foi escrito antes do código, que é o método.
  Vira falha na Sprint 3, quando o núcleo tiver que estar completo.
"""

from pathlib import Path

import pytest
import yaml
from fastapi import FastAPI

RAIZ = Path(__file__).resolve().parents[3]
CONTRATOS = RAIZ / "contracts"

SERVICOS = {
    "auth": CONTRATOS / "auth.openapi.yaml",
    "user": CONTRATOS / "user.openapi.yaml",
}


def _carregar(caminho: Path) -> dict:
    return yaml.safe_load(caminho.read_text(encoding="utf-8"))


def _rotas_do_app(app: FastAPI) -> set[str]:
    """Caminhos que o serviço realmente expõe, pelo OpenAPI que ele mesmo gera.

    Comparar OpenAPI com OpenAPI, em vez de andar por `app.routes`: as rotas
    incluídas por `include_router` ficam sob um objeto interno que não expõe as
    filhas, e uma varredura ingênua devolve conjunto vazio — um guarda que passa
    sem ter olhado nada. `app.openapi()` já resolve prefixos e omite `/docs` e
    `/openapi.json`, que não são API.
    """
    return set(app.openapi().get("paths", {}))


def _app_do_servico(nome: str) -> FastAPI:
    if nome == "auth":
        from auth_service.main import app
    else:
        from user_service.main import app
    return app


def test_todo_contrato_e_yaml_valido_e_openapi_31():
    arquivos = sorted(CONTRATOS.glob("*.yaml"))
    assert arquivos, f"nenhum contrato encontrado em {CONTRATOS}"

    for arquivo in arquivos:
        doc = _carregar(arquivo)
        assert doc.get("openapi", "").startswith("3.1"), f"{arquivo.name}: openapi deve ser 3.1.x"
        assert doc.get("info", {}).get("title"), f"{arquivo.name}: info.title ausente"
        assert doc.get("paths"), f"{arquivo.name}: nenhum path declarado"


@pytest.mark.parametrize("servico", sorted(SERVICOS))
def test_nenhuma_rota_fora_do_contrato(servico: str):
    """A deriva perigosa: endpoint no ar que ninguém documentou nem revisou."""
    contrato = set(_carregar(SERVICOS[servico])["paths"])
    implementadas = _rotas_do_app(_app_do_servico(servico))

    fora_do_contrato = implementadas - contrato
    assert not fora_do_contrato, (
        f"{servico}-service expõe rotas que não estão em "
        f"contracts/{SERVICOS[servico].name}: {sorted(fora_do_contrato)}. "
        "Escreva o contrato antes da rota, ou remova a rota."
    )


@pytest.mark.parametrize("servico", sorted(SERVICOS))
def test_health_do_contrato_esta_implementado(servico: str):
    """`/health` é a única rota que a Sprint 1 exige de pé — é o gate da sprint."""
    contrato = set(_carregar(SERVICOS[servico])["paths"])
    implementadas = _rotas_do_app(_app_do_servico(servico))

    assert "/health" in contrato, f"contrato de {servico} não declara /health"
    assert "/health" in implementadas, f"{servico}-service não implementa /health"


@pytest.mark.parametrize("servico", sorted(SERVICOS))
def test_pendencias_do_contrato_sao_visiveis(servico: str, capsys):
    """Não falha: transforma o contrato numa lista de tarefas das Sprints 3+."""
    contrato = set(_carregar(SERVICOS[servico])["paths"])
    implementadas = _rotas_do_app(_app_do_servico(servico))
    pendentes = sorted(contrato - implementadas)

    with capsys.disabled():
        if pendentes:
            print(
                f"\n  [{servico}-service] {len(pendentes)} rota(s) "
                f"do contrato ainda por implementar:"
            )
            for rota in pendentes:
                print(f"    - {rota}")

    # Toda rota pendente precisa estar no contrato, por construção. A asserção
    # existe para o teste não virar um print silencioso que ninguém nota quebrado.
    assert set(pendentes) <= contrato
