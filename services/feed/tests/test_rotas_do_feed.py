"""As rotas do feed ponta a ponta: HTTP de verdade, banco de verdade, user-service falso.

Mesma divisão do teste equivalente do academic-service, e pelas mesmas razões:

- **O banco é real.** Sem ele não se testa o `OR` dos dois ramos do feed, nem o
  `ON CONFLICT` da curtida, nem o `CASCADE` que apaga comentário junto com o post.
- **O user-service é `respx`.** O que interessa aqui é como o feed-service usa a
  resposta dele, e subir dois serviços para provar isso trocaria um teste rápido por
  um ambiente.

O custo conhecido é o falso poder mentir de um jeito que o real não mente. O que
segura isso é o formato vir dos **schemas do user-service**, não de dicionários
escritos à mão: `_escopo()` e `_ativacao()` montam o corpo com `EscopoDoFeedOut` e
`AtivacaoOut`, então uma mudança no contrato interno quebra este arquivo em vez de
passar.
"""

from uuid import UUID, uuid4

import httpx
import pytest
import pytest_asyncio
import respx
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from feed_service.api.deps import obter_sessao
from feed_service.main import app
from feed_service.settings import settings
from integra_shared.security import UsuarioAutenticado, criar_access_token
from user_service.schemas import AtivacaoOut, EscopoDoFeedOut, ResumoDePerfilOut

FATEC = uuid4()
OUTRA_FACULDADE = uuid4()
ADS = uuid4()

LEITOR = uuid4()  # aluno com vínculo na FATEC
COLEGA = uuid4()  # aluno com vínculo na FATEC, que o leitor NÃO segue
ESTRANHO = uuid4()  # aluno com vínculo em outra faculdade
EMPRESA = uuid4()  # conta empresa que o leitor segue
EMPRESA_NAO_SEGUIDA = uuid4()
CONTA_DA_FATEC = uuid4()  # conta faculdade — não publica neste pilar

USER = "http://user-de-teste:8000"

DSN = settings.database_url or ""


@pytest_asyncio.fixture
async def cliente():
    """`TestClient` com uma engine por requisição, e `TRUNCATE` nas duas pontas.

    As duas escolhas são as do teste do academic-service, e a nota lá explica as
    duas: o `TestClient` roda o app num event loop próprio, e uma engine async
    guarda um pool preso ao loop em que nasceu. `TRUNCATE` é seguro porque o schema
    `feed` **não tem seed** — no schema `user` ele apagaria a FATEC semeada.

    **Nas duas pontas**, como no academic-service: o fim deixa limpo para o próximo
    teste, e o começo protege do que os roteiros de portão deixam neste mesmo banco.
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
            await conexao.execute(text("TRUNCATE feed.posts CASCADE"))

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
            await conexao.execute(text("TRUNCATE feed.posts CASCADE"))
        await motor_do_teste.dispose()


def _token(
    usuario_id: UUID,
    *,
    tipo: str = "aluno",
    universidade: UUID | None = None,
) -> dict[str, str]:
    jwt = criar_access_token(
        UsuarioAutenticado(
            id=usuario_id,
            tipo=tipo,  # type: ignore[arg-type]
            vinculo_universidade_id=universidade,
            vinculo_curso_id=ADS if universidade else None,
        )
    )
    return {"Authorization": f"Bearer {jwt}"}


def _escopo(universidades: list[UUID], seguidos: list[UUID]) -> dict:
    return EscopoDoFeedOut(universidades=universidades, seguidos=seguidos).model_dump(
        mode="json", by_alias=True
    )


def _ativacao(tipo: str, *, ativa: bool = True) -> dict:
    return AtivacaoOut(ativa=ativa, tipo=tipo).model_dump(  # type: ignore[arg-type]
        mode="json", by_alias=True
    )


def _perfis(*ids: UUID) -> list[dict]:
    return [
        ResumoDePerfilOut(
            id=i, nome_completo=f"Pessoa {str(i)[:4]}", username=f"p{str(i)[:4]}", foto_url=None
        ).model_dump(mode="json", by_alias=True)
        for i in ids
    ]


def _user_service(
    *,
    universidades: list[UUID] | None = None,
    seguidos: list[UUID] | None = None,
    tipos: dict[UUID, str] | None = None,
    ativas: bool = True,
) -> respx.Router:
    """As três rotas internas que o feed-service consome.

    `tipos` mapeia conta → tipo, para a rota de ativação responder por quem chama. O
    padrão trata qualquer conta desconhecida como `aluno` ativo: é o caso da maioria
    dos testes, e listar todas as contas em cada um esconderia qual delas importa.
    """
    tipos = tipos or {}
    roteador = respx.mock(base_url=USER, assert_all_called=False)

    roteador.get(url__regex=r".*/escopo-do-feed$").mock(
        return_value=httpx.Response(
            200,
            json=_escopo(
                universidades if universidades is not None else [FATEC],
                seguidos if seguidos is not None else [],
            ),
        )
    )
    roteador.get(url__regex=r"/users/interno/(?P<conta>[0-9a-f-]+)/ativacao$").mock(
        side_effect=lambda pedido, conta: httpx.Response(
            200, json=_ativacao(tipos.get(UUID(conta), "aluno"), ativa=ativas)
        )
    )
    roteador.get("/users/interno/resumos").mock(
        side_effect=lambda pedido: httpx.Response(
            200, json=_perfis(*[UUID(i) for i in pedido.url.params.get_list("ids")])
        )
    )
    return roteador


def _publicar(
    cliente,
    autor: UUID,
    *,
    tipo: str = "aluno",
    universidade: UUID | None = None,
) -> dict:
    """Publica como `autor`, pelo caminho real — inclusive a dependência de ativação."""
    with _user_service(tipos={autor: tipo}):
        resposta = cliente.post(
            "/feed/posts",
            json={"conteudo": f"post de {str(autor)[:4]}"},
            headers=_token(autor, tipo=tipo, universidade=universidade),
        )
    assert resposta.status_code == 201, resposta.text
    return resposta.json()


# ──────────────────────────────  publicação  ──────────────────────────────


def test_o_aluno_publica_e_o_vinculo_do_token_fica_gravado_no_post(cliente):
    """O vínculo é copiado na publicação — é o que decide `recomendado` depois."""
    post = _publicar(cliente, LEITOR, universidade=FATEC)

    assert post["autor"]["id"] == str(LEITOR)
    assert post["autor"]["tipo"] == "aluno"
    # `origem` é nula fora do feed: quem acabou de publicar não precisa que o
    # servidor explique por que está vendo o próprio post.
    assert post["origem"] is None
    assert post["podeEditar"] is True


def test_a_empresa_publica_e_o_post_nasce_sem_universidade(cliente):
    """Empresa não tem vínculo — e é o nulo que a mantém fora de `recomendado`."""
    post = _publicar(cliente, EMPRESA, tipo="empresa")
    assert post["autor"]["tipo"] == "empresa"

    # Sem seguir a empresa e sem universidade em comum, o post dela não alcança.
    with _user_service(universidades=[FATEC], seguidos=[]):
        feed = cliente.get("/feed/posts", headers=_token(LEITOR, universidade=FATEC))
    assert [p["id"] for p in feed.json()["itens"]] == []


def test_a_faculdade_nao_publica_no_pilar_profissional(cliente):
    """Comunicado de instituição é o pilar acadêmico. Recusa pelo tipo, antes do banco."""
    with _user_service(tipos={CONTA_DA_FATEC: "faculdade"}):
        resposta = cliente.post(
            "/feed/posts",
            json={"conteudo": "comunicado"},
            headers=_token(CONTA_DA_FATEC, tipo="faculdade"),
        )
    assert resposta.status_code == 403
    assert resposta.json()["code"] == "permissao_negada"


def test_conta_institucional_pendente_nao_publica(cliente):
    """A checagem vem do banco, não do token: no JWT ela publicaria por 15 minutos."""
    with _user_service(tipos={EMPRESA: "empresa"}, ativas=False):
        resposta = cliente.post(
            "/feed/posts",
            json={"conteudo": "vaga incrível"},
            headers=_token(EMPRESA, tipo="empresa"),
        )
    assert resposta.status_code == 403
    assert resposta.json()["code"] == "conta_pendente"


def test_conteudo_vazio_e_erro_de_campo(cliente):
    with _user_service(tipos={LEITOR: "aluno"}):
        resposta = cliente.post(
            "/feed/posts", json={"conteudo": ""}, headers=_token(LEITOR, universidade=FATEC)
        )
    assert resposta.status_code == 422
    assert "conteudo" in resposta.json()["fields"]


# ────────────────────────  o conjunto do feed e a origem  ────────────────────────


def test_o_colega_de_universidade_entra_como_recomendado(cliente):
    """A resposta à pergunta que o rascunho deixou aberta, e o portão desta metade."""
    do_colega = _publicar(cliente, COLEGA, universidade=FATEC)

    with _user_service(universidades=[FATEC], seguidos=[]):
        feed = cliente.get("/feed/posts", headers=_token(LEITOR, universidade=FATEC))

    itens = {p["id"]: p for p in feed.json()["itens"]}
    assert do_colega["id"] in itens
    assert itens[do_colega["id"]]["origem"] == "recomendado"


def test_quem_o_leitor_segue_entra_como_seguindo_mesmo_de_outra_faculdade(cliente):
    """Seguir atravessa universidade; recomendação não."""
    do_estranho = _publicar(cliente, ESTRANHO, universidade=OUTRA_FACULDADE)

    with _user_service(universidades=[FATEC], seguidos=[ESTRANHO]):
        feed = cliente.get("/feed/posts", headers=_token(LEITOR, universidade=FATEC))

    itens = {p["id"]: p for p in feed.json()["itens"]}
    assert itens[do_estranho["id"]]["origem"] == "seguindo"


def test_aluno_de_outra_faculdade_que_o_leitor_nao_segue_nao_aparece(cliente):
    """Sem os dois ramos, o post não entra. É o que impede o feed de ser global."""
    _publicar(cliente, ESTRANHO, universidade=OUTRA_FACULDADE)

    with _user_service(universidades=[FATEC], seguidos=[]):
        feed = cliente.get("/feed/posts", headers=_token(LEITOR, universidade=FATEC))

    assert feed.json()["itens"] == []


def test_o_proprio_post_aparece_no_feed_como_seguindo(cliente):
    """Conta nova, sem seguir ninguém: o que ela publicou tem que aparecer.

    Sem este ramo, quem instala o app, publica e abre o feed vê vazio — e o pior
    lugar para mostrar vazio é logo depois da primeira ação do usuário.
    """
    meu = _publicar(cliente, LEITOR, universidade=None)

    with _user_service(universidades=[], seguidos=[]):
        feed = cliente.get("/feed/posts", headers=_token(LEITOR))

    itens = {p["id"]: p for p in feed.json()["itens"]}
    assert itens[meu["id"]]["origem"] == "seguindo"


def test_a_empresa_seguida_aparece_e_a_nao_seguida_nao(cliente):
    seguida = _publicar(cliente, EMPRESA, tipo="empresa")
    _publicar(cliente, EMPRESA_NAO_SEGUIDA, tipo="empresa")

    with _user_service(universidades=[FATEC], seguidos=[EMPRESA]):
        feed = cliente.get("/feed/posts", headers=_token(LEITOR, universidade=FATEC))

    assert [p["id"] for p in feed.json()["itens"]] == [seguida["id"]]


# ────────────────────────────  o escopo da tela  ────────────────────────────


def test_o_escopo_estreita_e_nunca_amplia(cliente):
    """`escopo=empresas` não traz empresa que o leitor não segue.

    É o `AND` sobre a união dos dois ramos. Um `OR` aqui transformaria filtro em
    concessão — a mesma frase que o academic-service guarda sobre `visibilidade`.
    """
    do_colega = _publicar(cliente, COLEGA, universidade=FATEC)
    _publicar(cliente, EMPRESA_NAO_SEGUIDA, tipo="empresa")

    with _user_service(universidades=[FATEC], seguidos=[]):
        so_empresas = cliente.get(
            "/feed/posts", params={"escopo": "empresas"}, headers=_token(LEITOR, universidade=FATEC)
        )
        so_pessoas = cliente.get(
            "/feed/posts", params={"escopo": "pessoas"}, headers=_token(LEITOR, universidade=FATEC)
        )

    assert so_empresas.json()["itens"] == []
    assert [p["id"] for p in so_pessoas.json()["itens"]] == [do_colega["id"]]


def test_escopo_invalido_e_erro_do_cliente(cliente):
    with _user_service():
        resposta = cliente.get(
            "/feed/posts", params={"escopo": "faculdades"}, headers=_token(LEITOR)
        )
    assert resposta.status_code == 422


def test_sem_o_user_service_o_feed_responde_503_e_nao_uma_lista_pela_metade(cliente):
    """Um feed que esconde metade sem dizer nada é pior que um erro."""
    with respx.mock(base_url=USER, assert_all_called=False) as roteador:
        roteador.get(url__regex=r".*/escopo-do-feed$").mock(side_effect=httpx.ConnectError("caiu"))
        resposta = cliente.get("/feed/posts", headers=_token(LEITOR, universidade=FATEC))

    assert resposta.status_code == 503
    assert resposta.json()["code"] == "dependencia_indisponivel"


# ───────────────────────────  detalhe e aba de perfil  ───────────────────────────


def test_o_detalhe_e_legivel_por_qualquer_conta_e_nao_traz_origem(cliente):
    """Aqui não há 404 por permissão: todo post profissional é legível."""
    do_estranho = _publicar(cliente, ESTRANHO, universidade=OUTRA_FACULDADE)

    with _user_service():
        resposta = cliente.get(f"/feed/posts/{do_estranho['id']}", headers=_token(LEITOR))

    assert resposta.status_code == 200
    assert resposta.json()["origem"] is None
    assert resposta.json()["podeEditar"] is False


def test_post_inexistente_responde_404(cliente):
    with _user_service():
        resposta = cliente.get(f"/feed/posts/{uuid4()}", headers=_token(LEITOR))
    assert resposta.status_code == 404


def test_a_aba_de_publicacoes_do_perfil_lista_sem_chamar_o_escopo(cliente):
    """Ela sobrevive a uma falha que derruba o feed — só precisa dos resumos."""
    do_estranho = _publicar(cliente, ESTRANHO, universidade=OUTRA_FACULDADE)

    with respx.mock(base_url=USER, assert_all_called=False) as roteador:
        roteador.get(url__regex=r".*/escopo-do-feed$").mock(side_effect=httpx.ConnectError("caiu"))
        roteador.get("/users/interno/resumos").mock(
            side_effect=lambda pedido: httpx.Response(
                200, json=_perfis(*[UUID(i) for i in pedido.url.params.get_list("ids")])
            )
        )
        resposta = cliente.get(f"/feed/usuarios/{ESTRANHO}/posts", headers=_token(LEITOR))

    assert [p["id"] for p in resposta.json()["itens"]] == [do_estranho["id"]]


# ──────────────────────────────  edição e remoção  ──────────────────────────────


def test_so_o_autor_edita_e_quem_nao_e_recebe_404(cliente):
    meu = _publicar(cliente, LEITOR, universidade=FATEC)

    with _user_service():
        de_outro = cliente.patch(
            f"/feed/posts/{meu['id']}", json={"conteudo": "sequestrado"}, headers=_token(COLEGA)
        )
        do_autor = cliente.patch(
            f"/feed/posts/{meu['id']}",
            json={"conteudo": "corrigido"},
            headers=_token(LEITOR, universidade=FATEC),
        )

    assert de_outro.status_code == 404
    assert do_autor.status_code == 200
    assert do_autor.json()["conteudo"] == "corrigido"
    assert do_autor.json()["editadoEm"] is not None


def test_patch_vazio_nao_marca_editado(cliente):
    """Um `PATCH` sem campo marcaria "editado" num post intacto."""
    meu = _publicar(cliente, LEITOR, universidade=FATEC)

    with _user_service():
        resposta = cliente.patch(
            f"/feed/posts/{meu['id']}", json={}, headers=_token(LEITOR, universidade=FATEC)
        )

    assert resposta.status_code == 422


def test_imagem_nula_remove_e_campo_omitido_mantem(cliente):
    """A única ambiguidade de `PATCH` que este contrato resolve por valor explícito."""
    with _user_service(tipos={LEITOR: "aluno"}):
        criado = cliente.post(
            "/feed/posts",
            json={"conteudo": "com foto", "imagemUrl": "http://storage/posts/x.jpg"},
            headers=_token(LEITOR, universidade=FATEC),
        ).json()

        so_texto = cliente.patch(
            f"/feed/posts/{criado['id']}",
            json={"conteudo": "texto novo"},
            headers=_token(LEITOR, universidade=FATEC),
        ).json()
        sem_imagem = cliente.patch(
            f"/feed/posts/{criado['id']}",
            json={"imagemUrl": None},
            headers=_token(LEITOR, universidade=FATEC),
        ).json()

    assert so_texto["imagemUrl"] == "http://storage/posts/x.jpg"
    assert sem_imagem["imagemUrl"] is None


def test_remover_leva_curtidas_e_comentarios(cliente):
    meu = _publicar(cliente, LEITOR, universidade=FATEC)

    with _user_service():
        cliente.put(f"/feed/posts/{meu['id']}/curtidas", headers=_token(COLEGA))
        cliente.post(
            f"/feed/posts/{meu['id']}/comentarios",
            json={"conteudo": "parabéns"},
            headers=_token(COLEGA),
        )
        removido = cliente.delete(
            f"/feed/posts/{meu['id']}", headers=_token(LEITOR, universidade=FATEC)
        )
        depois = cliente.get(f"/feed/posts/{meu['id']}/comentarios", headers=_token(LEITOR))

    assert removido.status_code == 204
    assert depois.status_code == 404


# ──────────────────────────────  curtidas  ──────────────────────────────


def test_curtir_duas_vezes_conta_uma(cliente):
    """A idempotência é da chave primária composta, não de um `if` em código."""
    meu = _publicar(cliente, LEITOR, universidade=FATEC)

    with _user_service():
        cliente.put(f"/feed/posts/{meu['id']}/curtidas", headers=_token(COLEGA))
        cliente.put(f"/feed/posts/{meu['id']}/curtidas", headers=_token(COLEGA))
        visto_pelo_colega = cliente.get(f"/feed/posts/{meu['id']}", headers=_token(COLEGA)).json()
        visto_pelo_autor = cliente.get(
            f"/feed/posts/{meu['id']}", headers=_token(LEITOR, universidade=FATEC)
        ).json()

    assert visto_pelo_colega["totalDeCurtidas"] == 1
    # Estado POR LEITOR: o `isLiked` do protótipo fazia a curtida de um aparecer
    # para todos.
    assert visto_pelo_colega["curtidoPorMim"] is True
    assert visto_pelo_autor["curtidoPorMim"] is False


def test_descurtir_o_que_nao_estava_curtido_responde_204(cliente):
    meu = _publicar(cliente, LEITOR, universidade=FATEC)
    with _user_service():
        resposta = cliente.delete(f"/feed/posts/{meu['id']}/curtidas", headers=_token(COLEGA))
    assert resposta.status_code == 204


def test_curtir_post_inexistente_responde_404(cliente):
    with _user_service():
        resposta = cliente.put(f"/feed/posts/{uuid4()}/curtidas", headers=_token(COLEGA))
    assert resposta.status_code == 404


# ──────────────────────────────  comentários  ──────────────────────────────


def test_o_autor_do_post_remove_comentario_de_terceiro(cliente):
    """Moderação. Sem ela, a saída seria apagar o próprio post inteiro."""
    meu = _publicar(cliente, LEITOR, universidade=FATEC)

    with _user_service():
        comentario = cliente.post(
            f"/feed/posts/{meu['id']}/comentarios",
            json={"conteudo": "spam"},
            headers=_token(COLEGA),
        ).json()

        de_estranho = cliente.delete(
            f"/feed/comentarios/{comentario['id']}", headers=_token(ESTRANHO)
        )
        do_autor_do_post = cliente.delete(
            f"/feed/comentarios/{comentario['id']}",
            headers=_token(LEITOR, universidade=FATEC),
        )

    # `podeRemover` é por leitor: quem criou foi COLEGA, então na resposta dele é True.
    assert comentario["podeRemover"] is True
    assert de_estranho.status_code == 404
    assert do_autor_do_post.status_code == 204


def test_comentarios_saem_do_mais_antigo_para_o_mais_novo(cliente):
    meu = _publicar(cliente, LEITOR, universidade=FATEC)

    with _user_service():
        for texto in ("primeiro", "segundo", "terceiro"):
            cliente.post(
                f"/feed/posts/{meu['id']}/comentarios",
                json={"conteudo": texto},
                headers=_token(COLEGA),
            )
        pagina = cliente.get(f"/feed/posts/{meu['id']}/comentarios", headers=_token(LEITOR)).json()

    assert [c["conteudo"] for c in pagina["itens"]] == ["primeiro", "segundo", "terceiro"]


def test_o_card_de_comentario_nao_tem_tipo_de_autor(cliente):
    """`AutorDeComentario` não traz `tipo`: nenhum escopo filtra comentário.

    Um campo que o serviço não tem como preencher corretamente é pior que um campo
    ausente — e reusar `AutorDePost` aqui obrigaria a inventar um valor.
    """
    meu = _publicar(cliente, LEITOR, universidade=FATEC)
    with _user_service():
        comentario = cliente.post(
            f"/feed/posts/{meu['id']}/comentarios",
            json={"conteudo": "oi"},
            headers=_token(COLEGA),
        ).json()

    assert "tipo" not in comentario["autor"]


# ──────────────────────────────  paginação  ──────────────────────────────


def test_a_paginacao_nao_repete_nem_perde_post(cliente):
    """Keyset: publicar no meio da rolagem não desloca a segunda página.

    Com `OFFSET`, o item da borda apareceria duas vezes e outro nunca apareceria — o
    bug intermitente que depende de quem publicou no meio.
    """
    criados = [_publicar(cliente, LEITOR, universidade=FATEC)["id"] for _ in range(5)]

    with _user_service(universidades=[FATEC], seguidos=[]):
        primeira = cliente.get(
            "/feed/posts", params={"limit": 2}, headers=_token(LEITOR, universidade=FATEC)
        ).json()

        # Alguém publica entre as duas páginas.
        _publicar(cliente, COLEGA, universidade=FATEC)

        segunda = cliente.get(
            "/feed/posts",
            params={"limit": 2, "cursor": primeira["proximoCursor"]},
            headers=_token(LEITOR, universidade=FATEC),
        ).json()

    vistos = [p["id"] for p in primeira["itens"]] + [p["id"] for p in segunda["itens"]]
    assert len(vistos) == len(set(vistos)), "um post apareceu em duas páginas"
    assert set(vistos) <= set(criados)


def test_cursor_invalido_e_erro_de_campo(cliente):
    with _user_service():
        resposta = cliente.get(
            "/feed/posts", params={"cursor": "nao-e-base64!!"}, headers=_token(LEITOR)
        )
    assert resposta.status_code == 422
    assert "cursor" in resposta.json()["fields"]
