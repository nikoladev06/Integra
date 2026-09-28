"""As rotas de vaga e candidatura ponta a ponta, com banco real e user-service falso.

Mesma divisão dos outros dois serviços: banco de verdade porque é onde vive a
invariante do `local`, a `UniqueConstraint` da candidatura e o `CASCADE`; user-service
em `respx` porque o que interessa aqui é como o jobs-service usa a resposta dele.

O formato dos corpos falsos vem dos **schemas do user-service**, e não de dicionários
escritos à mão: uma mudança no contrato interno quebra este arquivo em vez de passar.
"""

from uuid import UUID, uuid4

import httpx
import pytest
import pytest_asyncio
import respx
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from integra_shared.security import UsuarioAutenticado, criar_access_token
from jobs_service.api.deps import obter_sessao
from jobs_service.main import app
from jobs_service.settings import settings
from user_service.schemas import AtivacaoOut, ResumoDePerfilOut

EMPRESA = uuid4()
OUTRA_EMPRESA = uuid4()
ALUNO = uuid4()
OUTRO_ALUNO = uuid4()
CONTA_DA_FATEC = uuid4()

USER = "http://user-de-teste:8000"
DSN = settings.database_url or ""


@pytest_asyncio.fixture
async def cliente():
    """`TestClient` com engine por requisição, e `TRUNCATE` ao fim.

    As duas escolhas são as dos outros serviços; a nota do teste do academic-service
    explica as duas. `TRUNCATE` é seguro porque o schema `jobs` não tem seed.
    """
    if not DSN or DSN.startswith("postgresql+asyncpg://u:p@"):
        pytest.skip(
            "INTEGRA_DATABASE_URL não aponta para um Postgres real. "
            "Suba com: cd infra && docker compose up -d postgres"
        )

    motor_do_teste = create_async_engine(DSN)
    try:
        try:
            async with motor_do_teste.connect() as conexao:
                await conexao.execute(text("SELECT 1"))
        except Exception as erro:
            pytest.skip(f"Postgres indisponível: {type(erro).__name__}")

        async def _sessao_por_requisicao():
            motor = create_async_engine(DSN)
            fabrica = async_sessionmaker(motor, expire_on_commit=False)
            try:
                async with fabrica() as sessao:
                    try:
                        yield sessao
                        await sessao.commit()
                    except Exception:
                        await sessao.rollback()
                        raise
            finally:
                await motor.dispose()

        app.dependency_overrides[obter_sessao] = _sessao_por_requisicao
        try:
            with TestClient(app) as c:
                yield c
        finally:
            app.dependency_overrides.clear()
    finally:
        async with motor_do_teste.begin() as conexao:
            await conexao.execute(text("TRUNCATE jobs.vagas CASCADE"))
        await motor_do_teste.dispose()


def _token(usuario_id: UUID, *, tipo: str = "aluno") -> dict[str, str]:
    jwt = criar_access_token(
        UsuarioAutenticado(id=usuario_id, tipo=tipo)  # type: ignore[arg-type]
    )
    return {"Authorization": f"Bearer {jwt}"}


def _perfis(*ids: UUID) -> list[dict]:
    return [
        ResumoDePerfilOut(
            id=i, nome_completo=f"Conta {str(i)[:4]}", username=f"c{str(i)[:4]}", foto_url=None
        ).model_dump(mode="json", by_alias=True)
        for i in ids
    ]


def _user_service(*, tipos: dict[UUID, str] | None = None, ativas: bool = True) -> respx.Router:
    """As duas rotas internas que o jobs-service consome."""
    tipos = tipos or {}
    roteador = respx.mock(base_url=USER, assert_all_called=False)
    roteador.get(url__regex=r"/users/interno/(?P<conta>[0-9a-f-]+)/ativacao$").mock(
        side_effect=lambda pedido, conta: httpx.Response(
            200,
            json=AtivacaoOut(
                ativa=ativas,
                tipo=tipos.get(UUID(conta), "empresa"),  # type: ignore[arg-type]
            ).model_dump(mode="json", by_alias=True),
        )
    )
    roteador.get("/users/interno/resumos").mock(
        side_effect=lambda pedido: httpx.Response(
            200, json=_perfis(*[UUID(i) for i in pedido.url.params.get_list("ids")])
        )
    )
    return roteador


VAGA = {
    "titulo": "Estágio em desenvolvimento",
    "descricao": "Trabalhar com Python e Flutter.",
    "tipo": "estagio",
    "modalidade": "hibrido",
    "local": "Ribeirão Preto, SP",
}


def _publicar(cliente, empresa: UUID = EMPRESA, **campos) -> dict:
    with _user_service():
        resposta = cliente.post(
            "/jobs/vagas", json={**VAGA, **campos}, headers=_token(empresa, tipo="empresa")
        )
    assert resposta.status_code == 201, resposta.text
    return resposta.json()


# ═════════════════  O PORTÃO DA SPRINT 5  ═════════════════


def test_o_portao_empresa_publica_aluno_se_candidata_empresa_ve(cliente):
    """O portão inteiro numa função, na ordem em que o plano o escreve.

    Está junto de propósito: os testes abaixo cobrem cada peça isolada, e este prova
    que as peças se encaixam na sequência real — que é o que um teste por rota não
    afirma.
    """
    with _user_service():
        # 1. a empresa publica
        vaga = cliente.post(
            "/jobs/vagas", json=VAGA, headers=_token(EMPRESA, tipo="empresa")
        ).json()
        assert vaga["estado"] == "aberta"
        # Empresa não é `aluno`: o campo é nulo, e não `false`, para ela não parecer
        # elegível a se candidatar à própria vaga.
        assert vaga["candidaturaEnviada"] is None

        # 2. o aluno vê a vaga na listagem, com o botão no estado certo
        lista = cliente.get("/jobs/vagas", headers=_token(ALUNO)).json()
        assert [v["id"] for v in lista["itens"]] == [vaga["id"]]
        assert lista["itens"][0]["candidaturaEnviada"] is False

        # 3. o aluno se candidata
        criada = cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        assert criada.status_code == 201
        candidatura = criada.json()
        assert candidatura["estado"] == "enviada"
        assert candidatura["visualizadaEm"] is None
        assert candidatura["candidato"]["id"] == str(ALUNO)

        # e a listagem passa a refletir isso, sem o aluno descobrir no toque
        depois = cliente.get("/jobs/vagas", headers=_token(ALUNO)).json()
        assert depois["itens"][0]["candidaturaEnviada"] is True
        assert depois["itens"][0]["totalDeCandidaturas"] == 1

        # 4. a empresa vê a candidatura recebida
        recebidas = cliente.get(
            f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(EMPRESA, tipo="empresa")
        ).json()
        assert [c["id"] for c in recebidas["itens"]] == [candidatura["id"]]
        # Listar NÃO marca como visualizada: a transição é um PATCH explícito.
        assert recebidas["itens"][0]["estado"] == "enviada"

        # 5. a empresa marca como visualizada, e o aluno enxerga a mudança
        marcada = cliente.patch(
            f"/jobs/candidaturas/{candidatura['id']}",
            json={"estado": "visualizada"},
            headers=_token(EMPRESA, tipo="empresa"),
        ).json()
        assert marcada["estado"] == "visualizada"
        assert marcada["visualizadaEm"] is not None

        minhas = cliente.get("/jobs/candidaturas/me", headers=_token(ALUNO)).json()
        assert minhas["itens"][0]["estado"] == "visualizada"
        assert minhas["itens"][0]["vaga"]["titulo"] == VAGA["titulo"]


# ──────────────────────────────  publicação  ──────────────────────────────


def test_o_aluno_nao_publica_vaga(cliente):
    with _user_service():
        resposta = cliente.post("/jobs/vagas", json=VAGA, headers=_token(ALUNO))
    assert resposta.status_code == 403
    assert resposta.json()["code"] == "permissao_negada"


def test_a_faculdade_nao_publica_vaga(cliente):
    with _user_service():
        resposta = cliente.post(
            "/jobs/vagas", json=VAGA, headers=_token(CONTA_DA_FATEC, tipo="faculdade")
        )
    assert resposta.status_code == 403


def test_empresa_pendente_nao_publica(cliente):
    """A checagem vem do banco, não do token: no JWT ela publicaria por 15 minutos."""
    with _user_service(ativas=False):
        resposta = cliente.post(
            "/jobs/vagas", json=VAGA, headers=_token(EMPRESA, tipo="empresa")
        )
    assert resposta.status_code == 403
    assert resposta.json()["code"] == "conta_pendente"


def test_vaga_presencial_sem_local_e_erro_de_campo(cliente):
    with _user_service():
        resposta = cliente.post(
            "/jobs/vagas",
            json={**VAGA, "modalidade": "presencial", "local": None},
            headers=_token(EMPRESA, tipo="empresa"),
        )
    assert resposta.status_code == 422
    assert "local" in resposta.json()["fields"]


def test_vaga_remota_com_local_e_recusada_em_vez_de_ignorada(cliente):
    """Aceito em silêncio, o local pareceria uma restrição geográfica que não existe."""
    with _user_service():
        resposta = cliente.post(
            "/jobs/vagas",
            json={**VAGA, "modalidade": "remoto"},
            headers=_token(EMPRESA, tipo="empresa"),
        )
    assert resposta.status_code == 422
    assert "local" in resposta.json()["fields"]


# ────────────────────────  edição, encerramento, filtros  ────────────────────────


def test_passar_a_remoto_limpa_o_local(cliente):
    """A edição não pode produzir estado que a publicação recusaria."""
    vaga = _publicar(cliente)
    with _user_service():
        editada = cliente.patch(
            f"/jobs/vagas/{vaga['id']}",
            json={"modalidade": "remoto"},
            headers=_token(EMPRESA, tipo="empresa"),
        ).json()
    assert editada["modalidade"] == "remoto"
    assert editada["local"] is None


def test_sair_de_remoto_sem_informar_local_usa_o_que_ja_estava(cliente):
    vaga = _publicar(cliente)
    with _user_service():
        cabecalho = _token(EMPRESA, tipo="empresa")
        cliente.patch(f"/jobs/vagas/{vaga['id']}", json={"modalidade": "remoto"}, headers=cabecalho)
        de_volta = cliente.patch(
            f"/jobs/vagas/{vaga['id']}", json={"modalidade": "presencial"}, headers=cabecalho
        )
    # A vaga foi a remoto e voltou: o local antigo foi limpo, então voltar exige um novo.
    assert de_volta.status_code == 422
    assert "local" in de_volta.json()["fields"]


def test_so_a_empresa_autora_edita_e_outra_recebe_404(cliente):
    vaga = _publicar(cliente)
    with _user_service():
        resposta = cliente.patch(
            f"/jobs/vagas/{vaga['id']}",
            json={"titulo": "sequestrada"},
            headers=_token(OUTRA_EMPRESA, tipo="empresa"),
        )
    assert resposta.status_code == 404


def test_fechada_sai_da_listagem_mas_continua_legivel_por_id(cliente):
    """Esconder no detalhe faria "minhas candidaturas" apontar para 404."""
    vaga = _publicar(cliente)
    with _user_service():
        cliente.patch(
            f"/jobs/vagas/{vaga['id']}",
            json={"estado": "fechada"},
            headers=_token(EMPRESA, tipo="empresa"),
        )
        abertas = cliente.get("/jobs/vagas", headers=_token(ALUNO)).json()
        fechadas = cliente.get(
            "/jobs/vagas", params={"estado": "fechada"}, headers=_token(ALUNO)
        ).json()
        detalhe = cliente.get(f"/jobs/vagas/{vaga['id']}", headers=_token(ALUNO))

    assert abertas["itens"] == []
    assert [v["id"] for v in fechadas["itens"]] == [vaga["id"]]
    assert detalhe.status_code == 200


def test_os_filtros_de_tipo_e_modalidade(cliente):
    estagio = _publicar(cliente)
    junior = _publicar(cliente, tipo="junior", modalidade="remoto", local=None)

    with _user_service():
        cabecalho = _token(ALUNO)
        por_tipo = cliente.get("/jobs/vagas", params={"tipo": "junior"}, headers=cabecalho).json()
        por_modo = cliente.get(
            "/jobs/vagas", params={"modalidade": "hibrido"}, headers=cabecalho
        ).json()
        por_empresa = cliente.get(
            "/jobs/vagas", params={"empresaId": str(OUTRA_EMPRESA)}, headers=cabecalho
        ).json()

    assert [v["id"] for v in por_tipo["itens"]] == [junior["id"]]
    assert [v["id"] for v in por_modo["itens"]] == [estagio["id"]]
    assert por_empresa["itens"] == []


def test_patch_vazio_e_recusado(cliente):
    vaga = _publicar(cliente)
    with _user_service():
        resposta = cliente.patch(
            f"/jobs/vagas/{vaga['id']}", json={}, headers=_token(EMPRESA, tipo="empresa")
        )
    assert resposta.status_code == 422


# ──────────────────────────────  candidaturas  ──────────────────────────────


def test_candidatar_duas_vezes_devolve_a_mesma_com_200(cliente):
    """A tela mostra "enviada" no 201 e nada no 200 — avisar duas vezes confunde."""
    vaga = _publicar(cliente)
    with _user_service():
        primeira = cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        segunda = cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        detalhe = cliente.get(f"/jobs/vagas/{vaga['id']}", headers=_token(ALUNO)).json()

    assert primeira.status_code == 201
    assert segunda.status_code == 200
    assert primeira.json()["id"] == segunda.json()["id"]
    assert detalhe["totalDeCandidaturas"] == 1


def test_a_empresa_nao_se_candidata(cliente):
    vaga = _publicar(cliente)
    with _user_service():
        resposta = cliente.post(
            f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(OUTRA_EMPRESA, tipo="empresa")
        )
    assert resposta.status_code == 403


def test_candidatar_se_a_vaga_fechada_responde_409(cliente):
    """Código próprio: não há campo a corrigir, a vaga encerrou."""
    vaga = _publicar(cliente)
    with _user_service():
        cliente.patch(
            f"/jobs/vagas/{vaga['id']}",
            json={"estado": "fechada"},
            headers=_token(EMPRESA, tipo="empresa"),
        )
        resposta = cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))

    assert resposta.status_code == 409
    assert resposta.json()["code"] == "vaga_fechada"


def test_quem_ja_se_candidatou_nao_perde_a_candidatura_quando_a_vaga_fecha(cliente):
    """Recusar aqui faria a tela dele perder o item ao recarregar."""
    vaga = _publicar(cliente)
    with _user_service():
        cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        cliente.patch(
            f"/jobs/vagas/{vaga['id']}",
            json={"estado": "fechada"},
            headers=_token(EMPRESA, tipo="empresa"),
        )
        de_novo = cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        minhas = cliente.get("/jobs/candidaturas/me", headers=_token(ALUNO)).json()

    assert de_novo.status_code == 200
    assert len(minhas["itens"]) == 1
    assert minhas["itens"][0]["vaga"]["estado"] == "fechada"


def test_candidatar_se_a_vaga_inexistente_responde_404_e_nao_409(cliente):
    """Um 409 diria que existe uma vaga fechada com aquele id."""
    with _user_service():
        resposta = cliente.post(f"/jobs/vagas/{uuid4()}/candidaturas", headers=_token(ALUNO))
    assert resposta.status_code == 404


def test_so_a_empresa_autora_ve_as_candidaturas_recebidas(cliente):
    """Qualquer outra conta recebe 404 — um 403 diria que a vaga tem candidatos."""
    vaga = _publicar(cliente)
    with _user_service():
        cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))

        do_aluno = cliente.get(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        de_outra = cliente.get(
            f"/jobs/vagas/{vaga['id']}/candidaturas",
            headers=_token(OUTRA_EMPRESA, tipo="empresa"),
        )
        da_autora = cliente.get(
            f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(EMPRESA, tipo="empresa")
        )

    assert do_aluno.status_code == 404
    assert de_outra.status_code == 404
    assert da_autora.status_code == 200


def test_o_aluno_nao_ve_a_candidatura_de_outro_aluno(cliente):
    """`/candidaturas/me` sai do token. Não há parâmetro de candidato a forjar."""
    vaga = _publicar(cliente)
    with _user_service():
        cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        minhas = cliente.get("/jobs/candidaturas/me", headers=_token(OUTRO_ALUNO)).json()
    assert minhas["itens"] == []


def test_a_empresa_ve_de_quem_se_candidatou_apenas_o_resumo(cliente):
    """Nem CPF, nem telefone, nem e-mail. A garantia é o tipo não ter os campos."""
    vaga = _publicar(cliente)
    with _user_service():
        cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        recebidas = cliente.get(
            f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(EMPRESA, tipo="empresa")
        ).json()

    candidato = recebidas["itens"][0]["candidato"]
    assert set(candidato) == {"id", "nomeCompleto", "username", "fotoUrl"}


def test_marcar_visualizada_de_novo_nao_move_a_data(cliente):
    """A data é a da primeira vez — é o que o aluno lê como "foi vista"."""
    vaga = _publicar(cliente)
    with _user_service():
        candidatura = cliente.post(
            f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO)
        ).json()
        cabecalho = _token(EMPRESA, tipo="empresa")
        primeira = cliente.patch(
            f"/jobs/candidaturas/{candidatura['id']}",
            json={"estado": "visualizada"},
            headers=cabecalho,
        ).json()
        segunda = cliente.patch(
            f"/jobs/candidaturas/{candidatura['id']}",
            json={"estado": "visualizada"},
            headers=cabecalho,
        ).json()

    assert primeira["visualizadaEm"] == segunda["visualizadaEm"]


def test_o_estado_nao_volta_para_enviada(cliente):
    """`Literal["visualizada"]`: a recusa é do tipo, com o campo nomeado."""
    vaga = _publicar(cliente)
    with _user_service():
        candidatura = cliente.post(
            f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO)
        ).json()
        resposta = cliente.patch(
            f"/jobs/candidaturas/{candidatura['id']}",
            json={"estado": "enviada"},
            headers=_token(EMPRESA, tipo="empresa"),
        )
    assert resposta.status_code == 422
    assert "estado" in resposta.json()["fields"]


def test_outra_empresa_nao_marca_a_candidatura_como_visualizada(cliente):
    vaga = _publicar(cliente)
    with _user_service():
        candidatura = cliente.post(
            f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO)
        ).json()
        resposta = cliente.patch(
            f"/jobs/candidaturas/{candidatura['id']}",
            json={"estado": "visualizada"},
            headers=_token(OUTRA_EMPRESA, tipo="empresa"),
        )
    assert resposta.status_code == 404


def test_encerrar_a_vaga_nao_apaga_as_candidaturas(cliente):
    """Encerrar é estado, e não remoção: o histórico dos dois lados fica."""
    vaga = _publicar(cliente)
    with _user_service():
        cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        cabecalho = _token(EMPRESA, tipo="empresa")
        cliente.patch(f"/jobs/vagas/{vaga['id']}", json={"estado": "fechada"}, headers=cabecalho)
        recebidas = cliente.get(
            f"/jobs/vagas/{vaga['id']}/candidaturas", headers=cabecalho
        ).json()
    assert len(recebidas["itens"]) == 1


# ──────────────────────────────  paginação  ──────────────────────────────


def test_a_paginacao_de_vagas_nao_repete_nem_perde(cliente):
    criadas = [_publicar(cliente)["id"] for _ in range(5)]

    with _user_service():
        primeira = cliente.get("/jobs/vagas", params={"limit": 2}, headers=_token(ALUNO)).json()
        _publicar(cliente)  # alguém publica entre as duas páginas
        segunda = cliente.get(
            "/jobs/vagas",
            params={"limit": 2, "cursor": primeira["proximoCursor"]},
            headers=_token(ALUNO),
        ).json()

    vistas = [v["id"] for v in primeira["itens"]] + [v["id"] for v in segunda["itens"]]
    assert len(vistas) == len(set(vistas)), "uma vaga apareceu em duas páginas"
    assert set(vistas) <= set(criadas)


def test_o_total_de_candidaturas_e_o_da_vaga_e_nao_o_da_linha(cliente):
    """A subconsulta precisa de um alias: sem ele, toda candidatura contaria 1."""
    vaga = _publicar(cliente)
    with _user_service():
        cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(ALUNO))
        cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(OUTRO_ALUNO))
        recebidas = cliente.get(
            f"/jobs/vagas/{vaga['id']}/candidaturas", headers=_token(EMPRESA, tipo="empresa")
        ).json()

    assert len(recebidas["itens"]) == 2
    assert {c["vaga"]["totalDeCandidaturas"] for c in recebidas["itens"]} == {2}
