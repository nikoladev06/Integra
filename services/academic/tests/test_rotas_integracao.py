"""As rotas ponta a ponta: HTTP de verdade, banco de verdade, user-service falso.

O que é real e o que não é, e por quê:

- **O banco é real.** Sem ele não se testa a cláusula SQL, nem o `ON CONFLICT` da
  curtida, nem o `CASCADE` que apaga comentário junto com o post.
- **O user-service é `respx`.** Ele não pertence a este teste: o que interessa aqui
  é como o academic-service usa a resposta dele, e subir dois serviços para provar
  isso trocaria um teste rápido por um ambiente.

A troca tem um custo conhecido, o mesmo que o plano registra para o `FakeRepository`
do app: **o falso pode mentir de um jeito que o real não mente.** O que segura isso
é o formato vir dos schemas do user-service, não de um dicionário escrito à mão —
`_universidade()` monta o corpo com `UniversidadeDaContaOut`, então uma mudança no
contrato interno quebra este arquivo em vez de passar.
"""

from uuid import UUID, uuid4

import httpx
import pytest
import pytest_asyncio
import respx
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from academic_service.api.deps import obter_sessao
from academic_service.main import app
from academic_service.settings import settings
from integra_shared.security import UsuarioAutenticado, criar_access_token
from user_service.schemas import (
    CursoOut,
    ResumoDePerfilOut,
    ResumoDeUniversidadeOut,
    UniversidadeDaContaOut,
)

FATEC = uuid4()
ADS = uuid4()
GESTAO = uuid4()
CONTA_DA_FATEC = uuid4()
ALUNO_DE_ADS = uuid4()
ALUNO_DE_GESTAO = uuid4()
ALUNO_SEM_VINCULO = uuid4()

USER = "http://user-de-teste:8000"


# ─────────────────────────  o ambiente de cada teste  ─────────────────────────


DSN = settings.database_url or ""


@pytest_asyncio.fixture
async def cliente():
    """`TestClient` com uma sessão nova por requisição, e limpeza ao fim.

    Duas coisas aqui divergem do fixture `sessao` compartilhado, e as duas por
    causa do event loop.

    **Uma engine por requisição, criada dentro da requisição.** O `TestClient`
    roda o app num portal próprio, com event loop próprio; uma engine async
    guarda um pool preso ao loop em que nasceu, então a engine do módulo
    `database.py` — criada na importação — rende
    `got Future attached to a different loop` na primeira consulta. Criar a
    engine dentro do handler custa milissegundos e elimina a classe inteira de
    problema, que é a mesma nota que o `conftest.py` da raiz já traz sobre criar
    uma engine por teste.

    **`TRUNCATE`, e não transação desfeita.** O fixture compartilhado embrulha o
    teste numa transação e a desfaz, mas aqui quem abre transação é o app, do outro
    lado do portal — não há como o teste participar dela. O `TRUNCATE` é seguro
    neste schema por um motivo específico: `academic` **não tem seed**. No schema
    `user` ele apagaria a FATEC semeada, e é justamente por isso que lá a escolha
    foi outra.

    **Nas duas pontas, e a de entrada não é redundante.** No fim, para o próximo
    teste encontrar o schema limpo; no começo, porque o fim não basta: os roteiros
    de portão (`infra/portao_*.py`) escrevem neste mesmo banco de desenvolvimento e
    não limpam nada, de propósito. Sem a limpeza de entrada, rodar um portão e
    depois a suíte derruba o **primeiro** teste do arquivo — e só ele, porque o
    teardown dele limpa para os outros. O sintoma é um flake que aparece uma vez e
    cujo culpado parece ser o teste.
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

        # Entra limpo: ver a nota do docstring sobre os roteiros de portão.
        async with motor_do_teste.begin() as conexao:
            await conexao.execute(text("TRUNCATE academic.posts CASCADE"))

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
            # CASCADE alcança curtidas e comentários pelas chaves estrangeiras.
            await conexao.execute(text("TRUNCATE academic.posts CASCADE"))
        await motor_do_teste.dispose()


def _token(
    usuario_id: UUID,
    *,
    tipo: str = "aluno",
    universidade: UUID | None = None,
    curso: UUID | None = None,
) -> dict[str, str]:
    jwt = criar_access_token(
        UsuarioAutenticado(
            id=usuario_id,
            tipo=tipo,  # type: ignore[arg-type]
            vinculo_universidade_id=universidade,
            vinculo_curso_id=curso,
        )
    )
    return {"Authorization": f"Bearer {jwt}"}


COMO_FACULDADE = {"tipo": "faculdade"}


def _cursos() -> list[CursoOut]:
    return [
        CursoOut(id=ADS, nome="Análise e Desenvolvimento de Sistemas"),
        CursoOut(id=GESTAO, nome="Gestão Empresarial"),
    ]


def _universidade(*, ativa: bool = True) -> dict:
    """O corpo de `/universidades/interno/de-conta/{id}`, montado pelo schema real.

    Escrever o dicionário à mão seria a forma de este teste passar enquanto o
    contrato interno mudou de nome de campo.
    """
    return UniversidadeDaContaOut(
        id=FATEC,
        nome="Faculdade de Tecnologia de Ribeirão Preto",
        sigla="FATEC RP",
        foto_url=None,
        cursos=_cursos(),
        conta_ativa=ativa,
    ).model_dump(mode="json", by_alias=True)


def _resumo() -> list[dict]:
    return [
        ResumoDeUniversidadeOut(
            id=FATEC,
            nome="Faculdade de Tecnologia de Ribeirão Preto",
            sigla="FATEC RP",
            foto_url=None,
            cursos=_cursos(),
        ).model_dump(mode="json", by_alias=True)
    ]


def _perfis(*ids: UUID) -> list[dict]:
    return [
        ResumoDePerfilOut(
            id=i, nome_completo=f"Pessoa {str(i)[:4]}", username=f"p{str(i)[:4]}", foto_url=None
        ).model_dump(mode="json", by_alias=True)
        for i in ids
    ]


def _user_service(escopo: list[UUID] | None = None, *, ativa: bool = True) -> respx.Router:
    """As quatro rotas internas que o academic-service consome."""
    roteador = respx.mock(base_url=USER, assert_all_called=False)
    roteador.get(f"/universidades/interno/de-conta/{CONTA_DA_FATEC}").mock(
        return_value=httpx.Response(200, json=_universidade(ativa=ativa))
    )
    roteador.get("/universidades/interno/resumos").mock(
        return_value=httpx.Response(200, json=_resumo())
    )
    roteador.get(url__regex=r".*/seguindo/universidades$").mock(
        return_value=httpx.Response(
            200, json=[str(u) for u in (escopo if escopo is not None else [FATEC])]
        )
    )
    roteador.get("/users/interno/resumos").mock(
        side_effect=lambda pedido: httpx.Response(
            200,
            json=_perfis(*[UUID(i) for i in pedido.url.params.get_list("ids")]),
        )
    )
    return roteador


def _publicar(cliente, visibilidade: str, *, curso: UUID | None = None) -> dict:
    resposta = cliente.post(
        "/academic/posts",
        json={
            "conteudo": f"comunicado {visibilidade}",
            "visibilidade": visibilidade,
            **({"cursoId": str(curso)} if curso else {}),
        },
        headers=_token(CONTA_DA_FATEC, **COMO_FACULDADE),
    )
    assert resposta.status_code == 201, resposta.text
    return resposta.json()


# ──────────────────────────────  publicação  ──────────────────────────────


def test_a_faculdade_publica_e_a_universidade_vem_da_conta(cliente):
    """A universidade do post **não** é campo do corpo: sai da conta autora."""
    with _user_service():
        post = _publicar(cliente, "institucional")

    assert post["instituicao"]["id"] == str(FATEC)
    assert post["instituicao"]["sigla"] == "FATEC RP"
    assert post["visibilidade"] == "institucional"
    assert post["podeEditar"] is True
    assert post["editadoEm"] is None


def test_aluno_nao_publica(cliente):
    with _user_service():
        resposta = cliente.post(
            "/academic/posts",
            json={"conteudo": "quero publicar", "visibilidade": "publico"},
            headers=_token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS),
        )

    assert resposta.status_code == 403
    assert resposta.json()["code"] == "permissao_negada"


def test_instituicao_pendente_nao_publica(cliente):
    """A checagem consulta o user-service, não o token.

    É o teste que prova por que ela não está no JWT: o token aqui é idêntico ao do
    caso anterior, e o que muda é só a resposta do outro serviço.
    """
    with _user_service(ativa=False):
        resposta = cliente.post(
            "/academic/posts",
            json={"conteudo": "ainda em análise", "visibilidade": "publico"},
            headers=_token(CONTA_DA_FATEC, **COMO_FACULDADE),
        )

    assert resposta.status_code == 403
    assert resposta.json()["code"] == "conta_pendente"


def test_restrito_a_curso_exige_curso(cliente):
    with _user_service():
        resposta = cliente.post(
            "/academic/posts",
            json={"conteudo": "sem curso", "visibilidade": "curso"},
            headers=_token(CONTA_DA_FATEC, **COMO_FACULDADE),
        )

    assert resposta.status_code == 422
    assert "cursoId" in resposta.json()["fields"]


def test_curso_de_outra_instituicao_e_recusado(cliente):
    """422 e não 404: o problema é o campo, não um recurso ausente."""
    with _user_service():
        resposta = cliente.post(
            "/academic/posts",
            json={
                "conteudo": "curso alheio",
                "visibilidade": "curso",
                "cursoId": str(uuid4()),
            },
            headers=_token(CONTA_DA_FATEC, **COMO_FACULDADE),
        )

    assert resposta.status_code == 422
    assert "cursoId" in resposta.json()["fields"]


def test_curso_sobrando_em_post_institucional_e_recusado(cliente):
    """Recusado, e não ignorado: aceito em silêncio, pareceria restrição que não é."""
    with _user_service():
        resposta = cliente.post(
            "/academic/posts",
            json={
                "conteudo": "alcance ambíguo",
                "visibilidade": "institucional",
                "cursoId": str(ADS),
            },
            headers=_token(CONTA_DA_FATEC, **COMO_FACULDADE),
        )

    assert resposta.status_code == 422


# ────────────────────────────  o portão, via HTTP  ────────────────────────────


def test_o_portao_da_sprint_pelo_feed(cliente):
    """Faculdade publica restrito a ADS; quem tem vínculo em ADS vê, quem só declarou não.

    O mesmo portão de `test_regra_integracao`, agora atravessando serialização,
    escopo e paginação — que é onde um filtro pode se perder entre a consulta e a
    resposta.
    """
    with _user_service():
        restrito = _publicar(cliente, "curso", curso=ADS)
        publico = _publicar(cliente, "publico")

        def ids_do_feed(headers):
            r = cliente.get("/academic/posts", headers=headers)
            assert r.status_code == 200, r.text
            return {item["id"] for item in r.json()["itens"]}

        de_quem_tem_vinculo = ids_do_feed(_token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS))
        de_quem_so_declarou = ids_do_feed(_token(ALUNO_SEM_VINCULO))
        de_outro_curso = ids_do_feed(_token(ALUNO_DE_GESTAO, universidade=FATEC, curso=GESTAO))

    assert restrito["id"] in de_quem_tem_vinculo
    assert restrito["id"] not in de_quem_so_declarou
    assert restrito["id"] not in de_outro_curso

    # O público chega a todos os três — é o controle que mostra que a ausência
    # acima é da restrição, e não de o feed estar vazio por outro motivo.
    for visiveis in (de_quem_tem_vinculo, de_quem_so_declarou, de_outro_curso):
        assert publico["id"] in visiveis


def test_a_etiqueta_do_curso_acompanha_o_post_restrito(cliente):
    """`curso` sai com nome, e só em post restrito: a tela precisa dizer a quem vai."""
    with _user_service():
        _publicar(cliente, "curso", curso=ADS)
        _publicar(cliente, "institucional")

        itens = cliente.get(
            "/academic/posts", headers=_token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)
        ).json()["itens"]

    por_alcance = {i["visibilidade"]: i for i in itens}
    assert por_alcance["curso"]["curso"]["nome"] == "Análise e Desenvolvimento de Sistemas"
    assert por_alcance["institucional"]["curso"] is None


def test_escopo_minha_sem_vinculo_responde_vazio_sem_erro(cliente):
    """Não é erro: é o estado de quem ainda não informou o CPF em nenhuma instituição."""
    with _user_service():
        _publicar(cliente, "publico")

        resposta = cliente.get(
            "/academic/posts", params={"escopo": "minha"}, headers=_token(ALUNO_SEM_VINCULO)
        )

    assert resposta.status_code == 200
    assert resposta.json()["itens"] == []


def test_escopo_geral_nao_traz_universidade_fora_do_conjunto(cliente):
    """Escopo escolhe QUAIS instituições entram. Um público fora dele não aparece.

    Prova a decisão da Sprint 4: post `publico` não entra no feed de quem não segue.
    Ele continua legível pelo perfil da instituição, que é o teste seguinte.
    """
    with _user_service():
        publico = _publicar(cliente, "publico")

    # Mesmo leitor, mas com a lista de seguidas vazia: a FATEC sai do escopo.
    with _user_service(escopo=[]):
        resposta = cliente.get("/academic/posts", headers=_token(ALUNO_SEM_VINCULO))

    assert resposta.json()["itens"] == []

    # E pelo perfil da instituição o mesmo post aparece — é o caminho de quem
    # chegou pela busca, sem seguir nem ter vínculo.
    with _user_service(escopo=[]):
        pelo_perfil = cliente.get(
            f"/academic/universidades/{FATEC}/posts", headers=_token(ALUNO_SEM_VINCULO)
        )

    assert [i["id"] for i in pelo_perfil.json()["itens"]] == [publico["id"]]


def test_perfil_da_instituicao_nao_mostra_interno_a_quem_nao_tem_vinculo(cliente):
    with _user_service():
        interno = _publicar(cliente, "institucional")
        publico = _publicar(cliente, "publico")

        visiveis = {
            i["id"]
            for i in cliente.get(
                f"/academic/universidades/{FATEC}/posts", headers=_token(ALUNO_SEM_VINCULO)
            ).json()["itens"]
        }

    assert publico["id"] in visiveis
    assert interno["id"] not in visiveis


def test_detalhe_de_post_fora_do_alcance_responde_404(cliente):
    """404 e não 403: um 403 confirmaria que existe comunicado restrito naquele id."""
    with _user_service():
        interno = _publicar(cliente, "institucional")

        resposta = cliente.get(
            f"/academic/posts/{interno['id']}", headers=_token(ALUNO_SEM_VINCULO)
        )

    assert resposta.status_code == 404
    assert resposta.json()["message"] == "Post não encontrado"

    # Idêntico ao de um id que nunca existiu — é o ponto.
    with _user_service():
        inexistente = cliente.get(f"/academic/posts/{uuid4()}", headers=_token(ALUNO_SEM_VINCULO))

    assert inexistente.status_code == 404
    assert inexistente.json() == resposta.json()


# ──────────────────────────────  edição  ──────────────────────────────


def test_a_faculdade_edita_o_proprio_post_e_o_alcance(cliente):
    """Decisão da Sprint 4: edita tudo, inclusive o alcance. `editadoEm` fica no registro."""
    with _user_service():
        post = _publicar(cliente, "curso", curso=ADS)

        resposta = cliente.patch(
            f"/academic/posts/{post['id']}",
            json={"conteudo": "texto corrigido", "visibilidade": "publico"},
            headers=_token(CONTA_DA_FATEC, **COMO_FACULDADE),
        )

    assert resposta.status_code == 200, resposta.text
    editado = resposta.json()
    assert editado["conteudo"] == "texto corrigido"
    assert editado["visibilidade"] == "publico"
    # Sair de `curso` limpa a restrição, em vez de deixar uma órfã no registro.
    assert editado["curso"] is None
    assert editado["editadoEm"] is not None


def test_passar_para_curso_sem_informar_curso_e_recusado(cliente):
    with _user_service():
        post = _publicar(cliente, "publico")

        resposta = cliente.patch(
            f"/academic/posts/{post['id']}",
            json={"visibilidade": "curso"},
            headers=_token(CONTA_DA_FATEC, **COMO_FACULDADE),
        )

    assert resposta.status_code == 422
    assert "cursoId" in resposta.json()["fields"]


def test_patch_vazio_e_recusado(cliente):
    """Marcaria `editadoEm` sem edição nenhuma, e a tela diria "editado" à toa."""
    with _user_service():
        post = _publicar(cliente, "publico")

        resposta = cliente.patch(
            f"/academic/posts/{post['id']}",
            json={},
            headers=_token(CONTA_DA_FATEC, **COMO_FACULDADE),
        )

    assert resposta.status_code == 422


def test_outra_faculdade_nao_edita_nem_apaga(cliente):
    outra_conta = uuid4()

    with _user_service() as roteador:
        post = _publicar(cliente, "publico")

        roteador.get(f"/universidades/interno/de-conta/{outra_conta}").mock(
            return_value=httpx.Response(200, json=_universidade())
        )
        headers = _token(outra_conta, **COMO_FACULDADE)

        assert (
            cliente.patch(
                f"/academic/posts/{post['id']}", json={"conteudo": "sequestrado"}, headers=headers
            ).status_code
            == 404
        )
        assert cliente.delete(f"/academic/posts/{post['id']}", headers=headers).status_code == 404


def test_apagar_leva_curtidas_e_comentarios(cliente):
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)

    with _user_service():
        post = _publicar(cliente, "institucional")
        assert (
            cliente.put(f"/academic/posts/{post['id']}/curtidas", headers=aluno).status_code == 204
        )
        assert (
            cliente.post(
                f"/academic/posts/{post['id']}/comentarios",
                json={"conteudo": "combinado"},
                headers=aluno,
            ).status_code
            == 201
        )

        assert (
            cliente.delete(
                f"/academic/posts/{post['id']}",
                headers=_token(CONTA_DA_FATEC, **COMO_FACULDADE),
            ).status_code
            == 204
        )

        # As duas coleções foram embora com o post: o 404 aqui é do post, e é o
        # `ON DELETE CASCADE` que garante que não sobrou linha órfã.
        assert (
            cliente.get(f"/academic/posts/{post['id']}/comentarios", headers=aluno).status_code
            == 404
        )


# ─────────────────────────  curtidas e comentários  ─────────────────────────


def test_curtir_e_idempotente_e_a_contagem_e_por_leitor(cliente):
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)
    outro = _token(ALUNO_DE_GESTAO, universidade=FATEC, curso=GESTAO)

    with _user_service():
        post = _publicar(cliente, "institucional")

        for _ in range(2):
            assert (
                cliente.put(f"/academic/posts/{post['id']}/curtidas", headers=aluno).status_code
                == 204
            )

        meu = cliente.get(f"/academic/posts/{post['id']}", headers=aluno).json()
        dele = cliente.get(f"/academic/posts/{post['id']}", headers=outro).json()

    # Duas chamadas, uma curtida: a idempotência é da chave composta, não de um `if`.
    assert meu["totalDeCurtidas"] == 1
    assert dele["totalDeCurtidas"] == 1

    # `curtidoPorMim` é estado por leitor. O protótipo guardava `isLiked` no post,
    # e a curtida de um aparecia para todos.
    assert meu["curtidoPorMim"] is True
    assert dele["curtidoPorMim"] is False


def test_descurtir_o_que_nao_estava_curtido_responde_204(cliente):
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)

    with _user_service():
        post = _publicar(cliente, "institucional")
        resposta = cliente.delete(f"/academic/posts/{post['id']}/curtidas", headers=aluno)

    assert resposta.status_code == 204


def test_quem_nao_ve_o_post_nao_curte_nem_comenta_nem_le_comentarios(cliente):
    """O erro clássico: checar visibilidade na leitura e esquecer na escrita.

    As três rotas passam pelo mesmo `garantir_visivel`, e este teste é o que
    impediria uma quarta de nascer sem ele.
    """
    de_fora = _token(ALUNO_SEM_VINCULO)

    with _user_service():
        post = _publicar(cliente, "institucional")

        curtir = cliente.put(f"/academic/posts/{post['id']}/curtidas", headers=de_fora)
        comentar = cliente.post(
            f"/academic/posts/{post['id']}/comentarios",
            json={"conteudo": "li o que não devia"},
            headers=de_fora,
        )
        listar = cliente.get(f"/academic/posts/{post['id']}/comentarios", headers=de_fora)

    assert curtir.status_code == 404
    assert comentar.status_code == 404
    assert listar.status_code == 404


def test_comentarios_em_ordem_cronologica_com_autor_resolvido(cliente):
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)

    with _user_service():
        post = _publicar(cliente, "institucional")

        for texto in ("primeiro", "segundo", "terceiro"):
            assert (
                cliente.post(
                    f"/academic/posts/{post['id']}/comentarios",
                    json={"conteudo": texto},
                    headers=aluno,
                ).status_code
                == 201
            )

        itens = cliente.get(f"/academic/posts/{post['id']}/comentarios", headers=aluno).json()[
            "itens"
        ]

    assert [i["conteudo"] for i in itens] == ["primeiro", "segundo", "terceiro"]
    assert itens[0]["autor"]["id"] == str(ALUNO_DE_ADS)
    # O próprio autor remove o que escreveu.
    assert itens[0]["podeRemover"] is True


def test_a_faculdade_autora_modera_comentario_de_outro(cliente):
    """Sem isso, a única saída da instituição seria apagar o comunicado inteiro."""
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)
    faculdade = _token(CONTA_DA_FATEC, **COMO_FACULDADE)

    with _user_service():
        post = _publicar(cliente, "institucional")
        comentario = cliente.post(
            f"/academic/posts/{post['id']}/comentarios",
            json={"conteudo": "fora de lugar"},
            headers=aluno,
        ).json()

        visto_pela_faculdade = cliente.get(
            f"/academic/posts/{post['id']}/comentarios", headers=faculdade
        ).json()["itens"][0]

        removido = cliente.delete(f"/academic/comentarios/{comentario['id']}", headers=faculdade)

    assert visto_pela_faculdade["podeRemover"] is True
    assert removido.status_code == 204


def test_um_aluno_nao_remove_o_comentario_de_outro(cliente):
    autor = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)
    intruso = _token(ALUNO_DE_GESTAO, universidade=FATEC, curso=GESTAO)

    with _user_service():
        post = _publicar(cliente, "institucional")
        comentario = cliente.post(
            f"/academic/posts/{post['id']}/comentarios",
            json={"conteudo": "meu"},
            headers=autor,
        ).json()

        alheio = cliente.get(f"/academic/posts/{post['id']}/comentarios", headers=intruso).json()[
            "itens"
        ][0]

        resposta = cliente.delete(f"/academic/comentarios/{comentario['id']}", headers=intruso)

    assert alheio["podeRemover"] is False
    assert resposta.status_code == 404


# ──────────────────────────────  paginação  ──────────────────────────────


def test_a_paginacao_nao_repete_nem_perde_post(cliente):
    """Keyset, e não `OFFSET`: o teste publica **entre** as duas páginas.

    Com `OFFSET`, o post novo empurra todo mundo uma posição e a segunda página
    repete o último item da primeira. É o bug que só aparece quando alguém publica
    no meio da rolagem — intermitente e dependente de terceiros.
    """
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)

    with _user_service():
        publicados = [_publicar(cliente, "publico")["id"] for _ in range(5)]

        primeira = cliente.get("/academic/posts", params={"limit": 2}, headers=aluno).json()
        assert primeira["proximoCursor"]

        # Alguém publica no meio da rolagem.
        intruso = _publicar(cliente, "publico")["id"]

        segunda = cliente.get(
            "/academic/posts",
            params={"limit": 2, "cursor": primeira["proximoCursor"]},
            headers=aluno,
        ).json()

    ids_primeira = [i["id"] for i in primeira["itens"]]
    ids_segunda = [i["id"] for i in segunda["itens"]]

    assert not set(ids_primeira) & set(ids_segunda), "a paginação repetiu um post"
    # O post publicado no meio é mais recente que o cursor, então não aparece na
    # segunda página — ele estaria no topo se o feed fosse recarregado.
    assert intruso not in ids_segunda
    assert set(ids_primeira + ids_segunda) <= set([*publicados, intruso])


def test_cursor_invalido_responde_422(cliente):
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)

    with _user_service():
        resposta = cliente.get(
            "/academic/posts", params={"cursor": "nao-e-um-cursor"}, headers=aluno
        )

    assert resposta.status_code == 422
    assert "cursor" in resposta.json()["fields"]


# ──────────────────────  o user-service fora do ar  ──────────────────────


def test_sem_o_user_service_o_escopo_minha_ainda_responde(cliente):
    """A propriedade que o vínculo no token compra.

    `minha` sai inteiramente dos claims: com o user-service inalcançável, o aluno
    continua lendo o feed da própria instituição. `geral` é o que depende da lista
    de seguidas, e esse responde 503 em vez de um feed pela metade que pareceria
    completo.
    """
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)

    with _user_service():
        _publicar(cliente, "institucional")

    with respx.mock(base_url=USER) as caiu:
        caiu.get(url__regex=r".*/seguindo/universidades$").mock(
            side_effect=httpx.ConnectError("sem rota")
        )
        caiu.get("/universidades/interno/resumos").mock(
            return_value=httpx.Response(200, json=_resumo())
        )

        geral = cliente.get("/academic/posts", headers=aluno)
        minha = cliente.get("/academic/posts", params={"escopo": "minha"}, headers=aluno)

    assert geral.status_code == 503
    assert geral.json()["code"] == "dependencia_indisponivel"

    assert minha.status_code == 200
    assert len(minha.json()["itens"]) == 1


# ────────────  as três abas do perfil da instituição (v1.1)  ────────────


def test_cada_aba_do_perfil_pede_um_alcance(cliente):
    """As três abas são três chamadas com `visibilidade` diferente.

    Sem o parâmetro, elas dividiriam uma lista paginada só, e a segunda página de
    uma viria misturada com as das outras.
    """
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)

    with _user_service():
        publico = _publicar(cliente, "publico")
        interno = _publicar(cliente, "institucional")
        restrito = _publicar(cliente, "curso", curso=ADS)

        def aba(valor: str) -> set[str]:
            r = cliente.get(
                f"/academic/universidades/{FATEC}/posts",
                params={"visibilidade": valor},
                headers=aluno,
            )
            assert r.status_code == 200, r.text
            return {i["id"] for i in r.json()["itens"]}

        assert aba("publico") == {publico["id"]}
        assert aba("institucional") == {interno["id"]}
        assert aba("curso") == {restrito["id"]}


def test_o_filtro_de_alcance_nao_concede_nada(cliente):
    """**O teste que justifica o parâmetro poder vir do cliente.**

    `visibilidade` entra na consulta com `AND` sobre a cláusula de visibilidade, e
    não com `OR`. Um `OR` transformaria o filtro em concessão: quem não tem vínculo
    pediria `?visibilidade=curso` e receberia os restritos.

    O leitor aqui é o que só declarou a formação — o mesmo do portão da sprint.
    """
    with _user_service():
        interno = _publicar(cliente, "institucional")
        restrito = _publicar(cliente, "curso", curso=ADS)
        publico = _publicar(cliente, "publico")

        de_fora = _token(ALUNO_SEM_VINCULO)

        def aba(valor: str) -> list[dict]:
            return cliente.get(
                f"/academic/universidades/{FATEC}/posts",
                params={"visibilidade": valor},
                headers=de_fora,
            ).json()["itens"]

        assert [i["id"] for i in aba("publico")] == [publico["id"]]
        assert aba("institucional") == [], "pedir o alcance não abre o alcance"
        assert aba("curso") == [], "nem o restrito a curso"

    # E os ids existem — as abas vazias não são "não há post nenhum".
    assert interno["id"] and restrito["id"]


def test_alcance_invalido_e_erro_do_cliente(cliente):
    """422 e não 500: o enum é validado pelo FastAPI antes de chegar à consulta."""
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)

    with _user_service():
        resposta = cliente.get(
            f"/academic/universidades/{FATEC}/posts",
            params={"visibilidade": "secreto"},
            headers=aluno,
        )

    assert resposta.status_code == 422


def test_sem_o_parametro_a_rota_devolve_todos_os_alcances_visiveis(cliente):
    """Compatibilidade com a v1.0: o parâmetro é opcional, e ausente não filtra."""
    aluno = _token(ALUNO_DE_ADS, universidade=FATEC, curso=ADS)

    with _user_service():
        esperados = {
            _publicar(cliente, "publico")["id"],
            _publicar(cliente, "institucional")["id"],
            _publicar(cliente, "curso", curso=ADS)["id"],
        }

        itens = cliente.get(f"/academic/universidades/{FATEC}/posts", headers=aluno).json()["itens"]

    assert {i["id"] for i in itens} == esperados
