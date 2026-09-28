"""O portão da Sprint 4, contra os serviços de verdade, pelo Traefik.

    cd infra && docker compose up -d --build
    uv run --project ../services python portao_academico.py

Não é teste automatizado e não roda na CI — é o **roteiro do portão**, executável.
Os testes de `services/academic/tests/` provam a regra contra o banco, e os de
`app/test/` provam a costura das telas contra os falsos. Isto prova a terceira
coisa, que nenhum dos dois alcança: que os dois lados leram o contrato igual, com
auth, user e academic no ar e o gateway no caminho.

A frase que ele verifica é a do plano:

    a faculdade publica restrito a um curso; o aluno COM VÍNCULO naquele curso vê;
    o aluno que só DECLAROU a mesma formação não recebe.

E, no caminho, o que a Sprint 4 acrescentou ao redor dela: conta institucional
pendente não publica, o 404 do post restrito é idêntico ao de post inexistente,
curtida é idempotente e por leitor, e o perfil da instituição mostra os públicos a
quem não tem vínculo nenhum.

Cada execução cria contas novas, com uma marca aleatória no e-mail e no username, e
CPF/CNPJ gerados pelos validadores de `integra_shared`. Nada é limpo no fim: o banco
de desenvolvimento acumula as contas de teste, e `docker compose down -v` zera tudo
quando incomodar. Escrever a limpeza custaria mais do que ela vale aqui, e um script
que apaga dados é um script que um dia apaga o dado errado.
"""

import os
import secrets
import subprocess
import sys
import time

import httpx

from integra_shared.cnpj import gerar_valido as gerar_cnpj
from integra_shared.cpf import gerar_valido as gerar_cpf

BASE = os.environ.get("INTEGRA_GATEWAY", "http://localhost:8080")

# A pasta do compose, para chamar `ativar.py` dentro do contêiner. O padrão supõe
# que o script roda de dentro de `infra/`, que é onde ele mora.
INFRA = os.environ.get("INTEGRA_INFRA", os.getcwd())

SENHA = "integra123456"

# Marca de execução: entra no e-mail e no username de tudo que este roteiro cria.
# Sem ela, a segunda execução colidiria em `email_ja_cadastrado` e pareceria um bug
# do serviço.
MARCA = secrets.token_hex(3)

cliente = httpx.Client(base_url=BASE, timeout=20.0)
falhas: list[str] = []


def conferir(condicao: bool, descricao: str) -> None:
    print(("  ok    " if condicao else "  FALHA ") + descricao)
    if not condicao:
        falhas.append(descricao)


def _exigir(resposta: httpx.Response, esperado: int, oque: str) -> dict:
    if resposta.status_code != esperado:
        raise SystemExit(f"\n{oque} falhou ({resposta.status_code}): {resposta.text}")
    return resposta.json() if resposta.content else {}


def cadastrar_aluno(nome: str, cpf: str, formacao: tuple[str, str] | None = None) -> str:
    """Cadastra uma conta de aluno. `formacao` cria formação **declarada**, sem selo."""
    email = f"{nome.lower()}.{MARCA}@exemplo.com"
    corpo: dict[str, object] = {
        "nomeCompleto": f"{nome} de Teste",
        "email": email,
        "username": f"{nome.lower()}_{MARCA}",
        "senha": SENHA,
        "telefone": "(16)99999-0000",
        "cpf": cpf,
    }
    if formacao:
        corpo["universidadeId"], corpo["cursoId"] = formacao

    _exigir(cliente.post("/auth/register", json=corpo), 201, f"cadastro de {nome}")
    return email


def cadastrar_faculdade(sigla: str, cnpj: str) -> str:
    email = f"reitoria.{MARCA}@{sigla.lower()}.br"
    _exigir(
        cliente.post(
            "/auth/register/instituicao",
            json={
                "tipo": "faculdade",
                "nome": f"Faculdade {sigla}",
                "sigla": sigla,
                "cnpj": cnpj,
                "email": email,
                "username": f"{sigla.lower()}_{MARCA}",
                "senha": SENHA,
                "telefone": "(16)3333-0000",
            },
        ),
        201,
        "cadastro institucional",
    )
    return email


def entrar(email: str) -> dict[str, str]:
    par = _exigir(cliente.post("/auth/login", json={"email": email, "senha": SENHA}), 200, "login")
    return {"Authorization": f"Bearer {par['accessToken']}"}


def ativar(email: str) -> None:
    """Roda `ativar.py` dentro do contêiner.

    É deliberadamente **não** uma rota HTTP: ativar concede o poder de publicar como
    a instituição e de vincular alunos, e exigir acesso ao servidor é uma barreira
    que nenhuma falha de autorização contorna. O preço é este passo manual, que o
    plano registra como débito aceito.
    """
    resultado = subprocess.run(
        ["docker", "compose", "exec", "-T", "user", "python", "-m", "user_service.ativar", email],
        cwd=INFRA,
        capture_output=True,
        text=True,
    )
    conferir(
        resultado.returncode == 0,
        f"ativar.py concluiu — {(resultado.stdout or resultado.stderr).strip()[:120]}",
    )


def main() -> int:
    print(f"\n== portão do pilar Acadêmico · {BASE} · marca {MARCA} ==\n")

    semente = int(time.time())
    cpf_com_vinculo = gerar_cpf(semente % 900_000_000)
    cpf_so_declarou = gerar_cpf((semente + 7_777) % 900_000_000)
    sigla = f"FT{MARCA}"

    print("1. a conta institucional nasce PENDENTE")
    email_faculdade = cadastrar_faculdade(sigla, gerar_cnpj(semente % 90_000_000))
    faculdade = entrar(email_faculdade)

    recusa = cliente.post(
        "/academic/posts",
        json={"conteudo": "antes da ativação", "visibilidade": "publico"},
        headers=faculdade,
    )
    conferir(
        recusa.status_code == 403,
        f"pendente não publica — 403 esperado, veio {recusa.status_code}",
    )
    conferir(
        recusa.json().get("code") == "conta_pendente",
        f"com o código conta_pendente — veio {recusa.json().get('code')!r}",
    )

    print("\n2. ativação")
    ativar(email_faculdade)
    # A checagem de conta ativa consulta o BANCO, não o token — é por isso que o
    # mesmo access token de antes já serve para publicar, sem relogar.
    print("   (o token de antes continua valendo: a checagem lê o banco, não o claim)")

    print("\n3. cursos e matrículas — o que faz o vínculo poder nascer")
    curso = _exigir(
        cliente.post(
            "/universidades/me/cursos",
            json={"nome": "Engenharia de Teste"},
            headers=faculdade,
        ),
        201,
        "criar curso",
    )
    conferir(True, f"curso criado: {curso['nome']}")

    _exigir(
        cliente.post(
            "/universidades/me/matriculas",
            json={"cpf": cpf_com_vinculo, "cursoId": curso["id"]},
            headers=faculdade,
        ),
        201,
        "criar matrícula",
    )
    conferir(True, "matrícula criada antes de a conta do aluno existir")

    universidade_id = cliente.get("/universidades", params={"q": sigla}).json()[0]["id"]

    print("\n4. a faculdade publica")
    restrito = _exigir(
        cliente.post(
            "/academic/posts",
            json={
                "conteudo": "Entrega do projeto remarcada para o dia 30.",
                "visibilidade": "curso",
                "cursoId": curso["id"],
            },
            headers=faculdade,
        ),
        201,
        "publicar restrito",
    )
    conferir(
        restrito["curso"]["nome"] == "Engenharia de Teste",
        "o post traz o NOME do curso, resolvido na leitura e não copiado na publicação",
    )

    publico = _exigir(
        cliente.post(
            "/academic/posts",
            json={"conteudo": "Inscrições abertas.", "visibilidade": "publico"},
            headers=faculdade,
        ),
        201,
        "publicar público",
    )

    print("\n5. o aluno COM VÍNCULO naquele curso")
    email_com_vinculo = cadastrar_aluno("Aluna", cpf_com_vinculo)
    aluna = entrar(email_com_vinculo)

    _exigir(
        cliente.post(
            f"/universidades/{universidade_id}/vinculo",
            json={"cpf": cpf_com_vinculo},
            headers=aluna,
        ),
        201,
        "criar vínculo",
    )
    # O vínculo viaja no TOKEN, então o access token emitido antes dele não o traz.
    # É o preço conhecido da escolha: entrar num vínculo vale no token seguinte.
    aluna = entrar(email_com_vinculo)

    no_feed = {p["id"] for p in cliente.get("/academic/posts", headers=aluna).json()["itens"]}
    conferir(restrito["id"] in no_feed, "o restrito APARECE no feed dela")
    conferir(publico["id"] in no_feed, "o público também")

    print("\n6. o aluno que só DECLAROU a mesma formação")
    email_so_declarou = cadastrar_aluno(
        "Bruno", cpf_so_declarou, formacao=(universidade_id, curso["id"])
    )
    bruno = entrar(email_so_declarou)

    perfil = cliente.get("/users/me", headers=bruno).json()
    conferir(
        len(perfil["formacoes"]) == 1 and perfil["formacoes"][0]["verificadaEm"] is None,
        "a formação dele existe e NÃO tem selo",
    )
    conferir(perfil["vinculo"] is None, "e ele não tem vínculo")

    # Seguir coloca a instituição no feed dele — e não abre nada além dos públicos.
    cliente.put(f"/users/me/seguindo/universidades/{universidade_id}", headers=bruno)

    no_feed = {p["id"] for p in cliente.get("/academic/posts", headers=bruno).json()["itens"]}
    conferir(
        restrito["id"] not in no_feed,
        "declarar a formação e seguir NÃO trazem o restrito — o portão da sprint",
    )
    conferir(publico["id"] in no_feed, "o público, sim: seguir coloca a instituição no feed")

    detalhe = cliente.get(f"/academic/posts/{restrito['id']}", headers=bruno)
    inexistente = cliente.get("/academic/posts/00000000-0000-0000-0000-000000000000", headers=bruno)
    conferir(
        detalhe.status_code == 404,
        f"o detalhe do restrito responde 404 — veio {detalhe.status_code}",
    )
    conferir(
        detalhe.json() == inexistente.json(),
        "e responde EXATAMENTE o mesmo que um id que nunca existiu",
    )

    comentar = cliente.post(
        f"/academic/posts/{restrito['id']}/comentarios",
        json={"conteudo": "li o que não devia"},
        headers=bruno,
    )
    conferir(
        comentar.status_code == 404,
        f"nem comenta nele — 404 esperado, veio {comentar.status_code}",
    )

    print("\n7. curtir e comentar, de quem pode ver")
    cliente.put(f"/academic/posts/{restrito['id']}/curtidas", headers=aluna)
    cliente.put(f"/academic/posts/{restrito['id']}/curtidas", headers=aluna)
    cliente.post(
        f"/academic/posts/{restrito['id']}/comentarios",
        json={"conteudo": "combinado"},
        headers=aluna,
    )

    visto = cliente.get(f"/academic/posts/{restrito['id']}", headers=aluna).json()
    conferir(
        visto["totalDeCurtidas"] == 1,
        f"duas chamadas, uma curtida — veio {visto['totalDeCurtidas']}",
    )
    conferir(visto["curtidoPorMim"] is True, "curtidoPorMim é estado por leitor")
    conferir(visto["totalDeComentarios"] == 1, "o comentário entrou na contagem")

    print("\n8. o perfil da instituição, para quem não tem vínculo")
    do_perfil = {
        p["id"]
        for p in cliente.get(
            f"/academic/universidades/{universidade_id}/posts", headers=bruno
        ).json()["itens"]
    }
    conferir(publico["id"] in do_perfil, "o público aparece ali")
    conferir(restrito["id"] not in do_perfil, "o restrito, não")

    print("\n9. as três abas do perfil da instituição")
    interno = _exigir(
        cliente.post(
            "/academic/posts",
            json={
                "conteudo": "Biblioteca em horário reduzido.",
                "visibilidade": "institucional",
            },
            headers=faculdade,
        ),
        201,
        "publicar interno",
    )

    def aba(alcance: str, headers: dict[str, str]) -> set[str]:
        return {
            p["id"]
            for p in cliente.get(
                f"/academic/universidades/{universidade_id}/posts",
                params={"visibilidade": alcance},
                headers=headers,
            ).json()["itens"]
        }

    conferir(aba("publico", aluna) == {publico["id"]}, "aba Geral traz só os públicos")
    conferir(
        aba("institucional", aluna) == {interno["id"]},
        "aba Institucional traz só os internos",
    )
    conferir(aba("curso", aluna) == {restrito["id"]}, "aba Por curso traz só os restritos")

    # **O filtro não concede nada.** Se `visibilidade` fosse aplicado em lugar da
    # cláusula de visibilidade — e não junto dela, com `AND` —, quem só declarou a
    # formação pediria a aba e receberia o conteúdo restrito.
    conferir(aba("publico", bruno) == {publico["id"]}, "sem vínculo, a aba Geral funciona")
    conferir(aba("institucional", bruno) == set(), "pedir a aba Institucional NÃO a abre")
    conferir(aba("curso", bruno) == set(), "pedir a aba Por curso NÃO a abre")

    invalido = cliente.get(
        f"/academic/universidades/{universidade_id}/posts",
        params={"visibilidade": "secreto"},
        headers=aluna,
    )
    conferir(
        invalido.status_code == 422,
        f"alcance inexistente é 422, não 500 — veio {invalido.status_code}",
    )

    print("\n10. o perfil não conta quantos alunos a instituição tem")
    corpo = cliente.get(f"/universidades/{universidade_id}", headers=bruno).json()
    # Decisão de produto: quantos alunos uma faculdade tem no Integra é informação
    # dela. O campo saiu da **resposta**, não só da tela — escondê-lo no cliente
    # deixaria o número legível para quem lesse o JSON, e a decisão não valeria nada.
    conferir(
        "totalDeAlunos" not in corpo,
        f"`totalDeAlunos` não volta mais — chaves: {sorted(corpo)}",
    )
    conferir("temVinculo" in corpo, "`temVinculo` fica: é o que decide o menu e os vazios")

    print()
    if falhas:
        print(f"== {len(falhas)} FALHA(S) ==")
        for descricao in falhas:
            print(f"  - {descricao}")
        return 1

    print("== TODAS AS CONFERÊNCIAS PASSARAM ==")
    return 0


if __name__ == "__main__":
    sys.exit(main())
