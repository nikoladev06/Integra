"""O portão da Sprint 5, contra os serviços de verdade, pelo Traefik.

    cd infra && docker compose up -d --build
    uv run --project ../services python portao_profissional.py

Não é teste automatizado e não roda na CI — é o **roteiro do portão**, executável.
Os testes de `services/feed/tests` e `services/jobs/tests` provam as regras contra o
banco, e os de `app/test/` provam a costura das telas contra os falsos. Isto prova a
terceira coisa, que nenhum dos dois alcança: que os dois lados leram o contrato igual,
com auth, user, feed e jobs no ar e o gateway no caminho.

A frase que ele verifica é a do plano:

    a empresa publica uma vaga; o aluno se candidata; a empresa vê a candidatura.

E, no caminho, o que a Sprint 5 acrescentou ao redor dela:

- a conta `empresa` pendente não publica vaga nem post, e o código é `conta_pendente`;
- **a recomendação sai do vínculo**: um aluno com vínculo alcança o post de outro aluno
  com vínculo na mesma universidade, como `recomendado`, sem seguir ninguém — e um
  aluno que só declarou a formação não alcança nada;
- **empresa nunca é recomendada**: o post dela só chega a quem a segue, e
  `escopo=empresas` não contorna isso;
- o escopo **estreita** e nunca amplia;
- candidatar-se duas vezes devolve 200 com a mesma candidatura, e vaga encerrada
  recusa candidatura NOVA com 409 sem tirar a de quem já se candidatou;
- listar candidaturas **não** marca como visualizada, e marcar duas vezes não move a
  data;
- quem não é a empresa autora recebe 404 na lista de candidaturas, e não 403.

Cada execução cria contas novas, com uma marca aleatória no e-mail e no username, e
CPF/CNPJ gerados pelos validadores de `integra_shared`. Nada é limpo no fim, pelo mesmo
motivo do portão do Acadêmico: um script que apaga dados é um script que um dia apaga o
dado errado. `docker compose down -v` zera tudo quando incomodar.
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
INFRA = os.environ.get("INTEGRA_INFRA", os.getcwd())

SENHA = "integra123456"

# Marca de execução: entra no e-mail e no username de tudo que este roteiro cria. Sem
# ela, a segunda execução colidiria em `email_ja_cadastrado` e pareceria um bug.
MARCA = secrets.token_hex(3)

cliente = httpx.Client(base_url=BASE, timeout=20.0)
falhas: list[str] = []

# O console do Windows abre em cp1252, que não tem a maioria dos acentos deste arquivo
# nem os sinais de seta. Sem isto o roteiro sai com mojibake — e **derruba** no primeiro
# caractere fora da tabela, com um UnicodeEncodeError que não diz nada sobre o portão.
# `errors="replace"` fica como rede: um terminal exótico degrada a acentuação em vez de
# perder a execução inteira.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


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


def cadastrar_instituicao(tipo: str, sigla: str, cnpj: str) -> str:
    email = f"contato.{MARCA}@{sigla.lower()}.br"
    _exigir(
        cliente.post(
            "/auth/register/instituicao",
            json={
                "tipo": tipo,
                "nome": f"{'Faculdade' if tipo == 'faculdade' else 'Empresa'} {sigla}",
                "sigla": sigla,
                "cnpj": cnpj,
                "email": email,
                "username": f"{sigla.lower()}_{MARCA}",
                "senha": SENHA,
                "telefone": "(16)3333-0000",
            },
        ),
        201,
        f"cadastro de {tipo}",
    )
    return email


def entrar(email: str) -> dict[str, str]:
    par = _exigir(cliente.post("/auth/login", json={"email": email, "senha": SENHA}), 200, "login")
    return {"Authorization": f"Bearer {par['accessToken']}"}


def id_de(cabecalho: dict[str, str]) -> str:
    """O id da conta autenticada, por `GET /users/me`.

    Existe porque `/auth/register` devolve o par de tokens, e não o perfil: o id da
    conta que acabou de nascer não volta na resposta do cadastro. Pela busca seria
    indireto e frágil — dois usernames parecidos e o roteiro seguiria com o id errado,
    falhando três passos depois por um motivo que não é o que ele verifica.
    """
    return _exigir(cliente.get("/users/me", headers=cabecalho), 200, "perfil próprio")["id"]


def ativar(email: str) -> None:
    """Roda `ativar.py` dentro do contêiner.

    É deliberadamente **não** uma rota HTTP: ativar concede o poder de publicar como a
    instituição, e exigir acesso ao servidor é uma barreira que nenhuma falha de
    autorização contorna.
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


def ids_do_feed(cabecalho: dict[str, str], **params: str) -> dict[str, str]:
    """Os posts do feed profissional, id → origem.

    Devolve a origem junto porque ela é metade do que este portão verifica: um post que
    aparece pelo ramo errado passaria por um teste que só olhasse a presença.
    """
    pagina = _exigir(cliente.get("/feed/posts", params=params, headers=cabecalho), 200, "feed")
    return {p["id"]: p["origem"] for p in pagina["itens"]}


def main() -> int:
    print(f"\n== portão do pilar Profissional · {BASE} · marca {MARCA} ==\n")

    semente = int(time.time())
    cpf_com_vinculo = gerar_cpf(semente % 900_000_000)
    cpf_colega = gerar_cpf((semente + 3_333) % 900_000_000)
    cpf_so_declarou = gerar_cpf((semente + 7_777) % 900_000_000)

    sigla_faculdade = f"FT{MARCA}"
    sigla_empresa = f"EM{MARCA}"

    # ─────────────────  a instituição que dá o vínculo  ─────────────────

    print("0. a faculdade, os cursos e as matrículas — é daqui que sai a recomendação")
    email_faculdade = cadastrar_instituicao(
        "faculdade", sigla_faculdade, gerar_cnpj(semente % 90_000_000)
    )
    faculdade = entrar(email_faculdade)
    ativar(email_faculdade)

    curso = _exigir(
        cliente.post(
            "/universidades/me/cursos",
            json={"nome": "Engenharia de Teste"},
            headers=faculdade,
        ),
        201,
        "criar curso",
    )
    for cpf in (cpf_com_vinculo, cpf_colega):
        _exigir(
            cliente.post(
                "/universidades/me/matriculas",
                json={"cpf": cpf, "cursoId": curso["id"]},
                headers=faculdade,
            ),
            201,
            "criar matrícula",
        )
    universidade_id = cliente.get("/universidades", params={"q": sigla_faculdade}).json()[0]["id"]
    conferir(True, "duas matrículas criadas antes de as contas existirem")

    # ─────────────────  1. a empresa nasce pendente  ─────────────────

    print("\n1. a conta `empresa` nasce PENDENTE, e não publica nada")
    email_empresa = cadastrar_instituicao(
        "empresa", sigla_empresa, gerar_cnpj((semente + 11) % 90_000_000)
    )
    empresa = entrar(email_empresa)

    recusa_vaga = cliente.post(
        "/jobs/vagas",
        json={
            "titulo": "antes da ativação",
            "descricao": "não deveria existir",
            "tipo": "estagio",
            "modalidade": "remoto",
        },
        headers=empresa,
    )
    conferir(
        recusa_vaga.status_code == 403,
        f"pendente não publica vaga — 403 esperado, veio {recusa_vaga.status_code}",
    )
    conferir(
        recusa_vaga.json().get("code") == "conta_pendente",
        f"com o código conta_pendente — veio {recusa_vaga.json().get('code')!r}",
    )

    recusa_post = cliente.post(
        "/feed/posts", json={"conteudo": "antes da ativação"}, headers=empresa
    )
    conferir(
        recusa_post.status_code == 403 and recusa_post.json().get("code") == "conta_pendente",
        "e também não publica no feed — a mesma checagem nos dois serviços",
    )

    print("\n2. ativação da empresa")
    ativar(email_empresa)
    # A checagem de conta ativa consulta o BANCO, não o token — é por isso que o mesmo
    # access token de antes já serve, sem relogar.
    print("   (o token de antes continua valendo: a checagem lê o banco, não o claim)")

    # ─────────────────  3. as três contas de aluno  ─────────────────

    print("\n3. os alunos: um com vínculo, um colega de curso, e um que só declarou")
    email_aluna = cadastrar_aluno("Aluna", cpf_com_vinculo)
    aluna = entrar(email_aluna)
    _exigir(
        cliente.post(
            f"/universidades/{universidade_id}/vinculo",
            json={"cpf": cpf_com_vinculo},
            headers=aluna,
        ),
        201,
        "criar vínculo da aluna",
    )
    # O vínculo viaja no TOKEN: o access token emitido antes dele não o traz.
    aluna = entrar(email_aluna)

    email_colega = cadastrar_aluno("Colega", cpf_colega)
    colega = entrar(email_colega)
    _exigir(
        cliente.post(
            f"/universidades/{universidade_id}/vinculo",
            json={"cpf": cpf_colega},
            headers=colega,
        ),
        201,
        "criar vínculo do colega",
    )
    colega = entrar(email_colega)

    email_bruno = cadastrar_aluno("Bruno", cpf_so_declarou, formacao=(universidade_id, curso["id"]))
    bruno = entrar(email_bruno)

    perfil_bruno = cliente.get("/users/me", headers=bruno).json()
    conferir(
        perfil_bruno["vinculo"] is None and perfil_bruno["formacoes"][0]["verificadaEm"] is None,
        "o Bruno declarou a mesma formação e NÃO tem vínculo nem selo",
    )

    # ─────────────────  4. os posts, e de onde vem a recomendação  ─────────────────

    print("\n4. os posts — e a recomendação sai do VÍNCULO, não da formação")
    post_do_colega = _exigir(
        cliente.post(
            "/feed/posts",
            json={"conteudo": "Terminei o projeto integrador do semestre."},
            headers=colega,
        ),
        201,
        "post do colega",
    )
    conferir(
        post_do_colega["origem"] is None,
        "a resposta da publicação não traz origem — fora do feed a pergunta não se faz",
    )

    post_do_bruno = _exigir(
        cliente.post(
            "/feed/posts",
            json={"conteudo": "Procurando primeira oportunidade em dados."},
            headers=bruno,
        ),
        201,
        "post do Bruno",
    )

    post_da_empresa = _exigir(
        cliente.post(
            "/feed/posts",
            json={"conteudo": "Abrimos duas vagas de estágio."},
            headers=empresa,
        ),
        201,
        "post da empresa",
    )

    feed_da_aluna = ids_do_feed(aluna)
    conferir(
        feed_da_aluna.get(post_do_colega["id"]) == "recomendado",
        "o colega de vínculo aparece como RECOMENDADO, sem a aluna seguir ninguém",
    )
    conferir(
        post_do_bruno["id"] not in feed_da_aluna,
        "o Bruno NÃO aparece — declarar a formação não põe ninguém na comunidade",
    )
    conferir(
        post_da_empresa["id"] not in feed_da_aluna,
        "a empresa NÃO aparece: empresa não tem vínculo, então não é recomendada",
    )

    print("\n5. seguir é o único caminho até a empresa")
    cliente.put(f"/users/me/seguindo/usuarios/{id_de(empresa)}", headers=aluna)
    feed_da_aluna = ids_do_feed(aluna)
    conferir(
        feed_da_aluna.get(post_da_empresa["id"]) == "seguindo",
        "depois de seguir, o post da empresa aparece como SEGUINDO",
    )

    print("\n6. o escopo ESTREITA e nunca amplia")
    so_empresas = ids_do_feed(aluna, escopo="empresas")
    conferir(
        set(so_empresas) == {post_da_empresa["id"]},
        "escopo=empresas deixa só a empresa seguida",
    )
    so_pessoas = ids_do_feed(aluna, escopo="pessoas")
    conferir(
        post_da_empresa["id"] not in so_pessoas and post_do_colega["id"] in so_pessoas,
        "escopo=pessoas deixa só o colega",
    )

    # O Bruno não segue ninguém e não tem vínculo: para ele, nenhum escopo inventa
    # conteúdo. É a prova de que o filtro não concede.
    so_empresas_do_bruno = ids_do_feed(bruno, escopo="empresas")
    conferir(
        post_da_empresa["id"] not in so_empresas_do_bruno,
        "para quem não segue a empresa, escopo=empresas NÃO a traz — o filtro não concede",
    )
    conferir(
        set(so_empresas_do_bruno) == set(),
        "e o feed dele em escopo=empresas é vazio, não uma lista de empresas quaisquer",
    )

    print("\n7. o próprio post aparece no próprio feed")
    conferir(
        ids_do_feed(bruno).get(post_do_bruno["id"]) == "seguindo",
        "o Bruno vê o que publicou, mesmo sem seguir ninguém e sem vínculo",
    )

    # ═════════════════  8. O PORTÃO  ═════════════════

    print("\n8. O PORTÃO: empresa publica vaga, aluno se candidata, empresa vê")
    vaga = _exigir(
        cliente.post(
            "/jobs/vagas",
            json={
                "titulo": "Estágio em desenvolvimento",
                "descricao": "Python e Postgres, com code review em toda entrega.",
                "tipo": "estagio",
                "modalidade": "hibrido",
                "local": "Ribeirão Preto, SP",
            },
            headers=empresa,
        ),
        201,
        "publicar vaga",
    )
    conferir(vaga["estado"] == "aberta", "a vaga nasce aberta")
    conferir(
        vaga["candidaturaEnviada"] is None,
        "e `candidaturaEnviada` é NULA para a empresa — não `false`, que a faria parecer elegível",
    )

    listagem = _exigir(cliente.get("/jobs/vagas", headers=aluna), 200, "listar vagas")
    a_vaga = next(v for v in listagem["itens"] if v["id"] == vaga["id"])
    conferir(
        a_vaga["candidaturaEnviada"] is False,
        "para o aluno o campo vem `false` — é o que faz o botão nascer no estado certo",
    )

    criada = cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=aluna)
    conferir(criada.status_code == 201, f"candidatura criada — veio {criada.status_code}")
    candidatura = criada.json()
    conferir(candidatura["estado"] == "enviada", "com estado `enviada`")
    conferir(candidatura["visualizadaEm"] is None, "e sem data de visualização")

    de_novo = cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=aluna)
    conferir(
        de_novo.status_code == 200 and de_novo.json()["id"] == candidatura["id"],
        "candidatar-se de novo devolve 200 com a MESMA candidatura — idempotente no banco",
    )

    recebidas = _exigir(
        cliente.get(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=empresa),
        200,
        "candidaturas recebidas",
    )
    conferir(
        [c["id"] for c in recebidas["itens"]] == [candidatura["id"]],
        "a empresa VÊ a candidatura",
    )
    conferir(
        recebidas["itens"][0]["estado"] == "enviada",
        "e listar NÃO marca como visualizada — a transição é um PATCH explícito",
    )
    conferir(
        set(recebidas["itens"][0]["candidato"]) == {"id", "nomeCompleto", "username", "fotoUrl"},
        "do candidato ela vê só o resumo: nem CPF, nem telefone, nem e-mail",
    )

    print("\n9. o estado, e a data que não anda")
    marcada = _exigir(
        cliente.patch(
            f"/jobs/candidaturas/{candidatura['id']}",
            json={"estado": "visualizada"},
            headers=empresa,
        ),
        200,
        "marcar visualizada",
    )
    conferir(marcada["estado"] == "visualizada", "a empresa marca como visualizada")

    remarcada = _exigir(
        cliente.patch(
            f"/jobs/candidaturas/{candidatura['id']}",
            json={"estado": "visualizada"},
            headers=empresa,
        ),
        200,
        "marcar de novo",
    )
    conferir(
        remarcada["visualizadaEm"] == marcada["visualizadaEm"],
        "marcar de novo NÃO move a data — ela é a da primeira vez "
        f"({marcada['visualizadaEm']} → {remarcada['visualizadaEm']})",
    )

    volta = cliente.patch(
        f"/jobs/candidaturas/{candidatura['id']}",
        json={"estado": "enviada"},
        headers=empresa,
    )
    conferir(volta.status_code == 422, f"o estado não volta atrás — veio {volta.status_code}")

    minhas = _exigir(
        cliente.get("/jobs/candidaturas/me", headers=aluna), 200, "minhas candidaturas"
    )
    conferir(
        minhas["itens"][0]["estado"] == "visualizada",
        "e o aluno enxerga a mudança — é o que faz o estado existir",
    )
    conferir(
        minhas["itens"][0]["vaga"]["titulo"] == vaga["titulo"],
        "com a vaga inteira: uma lista de 'onde me candidatei' sem o título não é legível",
    )

    print("\n10. quem não é a empresa autora recebe 404, e não 403")
    do_aluno = cliente.get(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=aluna)
    conferir(
        do_aluno.status_code == 404,
        f"o aluno não lista as candidaturas da vaga — 404 esperado, veio {do_aluno.status_code}",
    )
    da_faculdade = cliente.get(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=faculdade)
    conferir(
        da_faculdade.status_code == 404,
        "nem a faculdade — um 403 confirmaria que a vaga existe e tem candidatos",
    )

    recusa_aluno = cliente.post(
        "/jobs/vagas",
        json={
            "titulo": "não",
            "descricao": "não",
            "tipo": "estagio",
            "modalidade": "remoto",
        },
        headers=aluna,
    )
    conferir(recusa_aluno.status_code == 403, "o aluno não publica vaga")

    print("\n11. vaga encerrada: sai da listagem, e quem já se candidatou não perde nada")
    _exigir(
        cliente.patch(f"/jobs/vagas/{vaga['id']}", json={"estado": "fechada"}, headers=empresa),
        200,
        "encerrar vaga",
    )

    abertas = _exigir(cliente.get("/jobs/vagas", headers=aluna), 200, "listar abertas")
    conferir(
        vaga["id"] not in {v["id"] for v in abertas["itens"]},
        "a vaga encerrada sai da listagem padrão",
    )
    detalhe = cliente.get(f"/jobs/vagas/{vaga['id']}", headers=aluna)
    conferir(
        detalhe.status_code == 200,
        "e continua legível por id — senão 'minhas candidaturas' apontaria para 404",
    )

    ainda = _exigir(cliente.get("/jobs/candidaturas/me", headers=aluna), 200, "minhas candidaturas")
    conferir(
        len(ainda["itens"]) == 1,
        "encerrar não apagou candidatura nenhuma: é estado, não remoção",
    )

    nova_tentativa = cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=colega)
    conferir(
        nova_tentativa.status_code == 409 and nova_tentativa.json().get("code") == "vaga_fechada",
        f"quem AINDA não se candidatou recebe 409 vaga_fechada — veio {nova_tentativa.status_code}",
    )
    de_quem_ja = cliente.post(f"/jobs/vagas/{vaga['id']}/candidaturas", headers=aluna)
    conferir(
        de_quem_ja.status_code == 200,
        "e quem JÁ se candidatou continua recebendo a própria candidatura, não um 409",
    )

    print("\n12. a URL de upload é assinada, e os bytes não passam pelos serviços")
    url_avatar = _exigir(
        cliente.post(
            "/users/me/avatar/upload-url",
            json={"contentType": "image/jpeg", "tamanhoBytes": 120_000},
            headers=aluna,
        ),
        201,
        "url de upload do avatar",
    )
    conferir(
        f"avatares/{id_de(aluna)}/" in url_avatar["fotoUrl"],
        "o caminho do objeto é derivado do id de quem pede, não escolhido pelo cliente",
    )
    conferir(
        "X-Amz-Signature" in url_avatar["uploadUrl"],
        "e a URL vem assinada — o serviço não recebe os bytes",
    )

    grande = cliente.post(
        "/users/me/avatar/upload-url",
        json={"contentType": "image/jpeg", "tamanhoBytes": 20_000_000},
        headers=aluna,
    )
    conferir(
        grande.status_code == 422 and "tamanhoBytes" in grande.json().get("fields", {}),
        "acima de 5 MB é 422 nomeando o campo",
    )
    tipo_errado = cliente.post(
        "/feed/posts/imagem/upload-url",
        json={"contentType": "application/pdf", "tamanhoBytes": 1000},
        headers=aluna,
    )
    conferir(
        tipo_errado.status_code == 422 and "contentType" in tipo_errado.json().get("fields", {}),
        "e tipo fora das três imagens também — a validação é do módulo compartilhado",
    )

    print()
    if falhas:
        print(f"== {len(falhas)} FALHA(S) ==")
        for falha in falhas:
            print(f"  - {falha}")
        return 1

    print("== portão do pilar Profissional: todas as conferências passaram ==")
    return 0


if __name__ == "__main__":
    sys.exit(main())
