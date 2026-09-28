"""A regra do feed sem banco: os dois ramos, o filtro de tipo e a origem.

Testes de unidade sobre `feed_service.escopo`. O que eles cobrem é o que um teste de
rota cobre por acidente e não afirma: **que o escopo é `AND` e a união é `OR`**.

Não há aqui o equivalente a `test_as_duas_formas_da_regra_concordam` do
academic-service, e a ausência é o ponto: lá a regra existe em Python e em SQL, e o
teste compara as duas. Aqui existe uma forma só — não há pergunta "este leitor
alcança este post?", porque a resposta é sempre sim.
"""

from uuid import uuid4

from feed_service import escopo
from feed_service.models import Post, TipoDeAutor

LEITOR = uuid4()
SEGUIDO = uuid4()
COLEGA = uuid4()
FATEC = uuid4()


def _sql(clausula) -> str:
    return str(clausula.compile(compile_kwargs={"literal_binds": True}))


def test_o_leitor_entra_no_ramo_de_seguidos_mesmo_sem_seguir_ninguem():
    """O que impede o feed de uma conta nova de nascer vazio depois do primeiro post."""
    sql = _sql(escopo.clausula_do_feed(LEITOR, [], []))
    # `literal_binds` renderiza UUID sem hífen, então a comparação é pelo hex.
    assert LEITOR.hex in sql
    # Sem universidades, o ramo de recomendação não é emitido: um `IN ()` vazio
    # funcionaria por acidente, e a próxima negação herdaria uma expressão cujo valor
    # lógico depende de a lista estar vazia.
    assert "autor_universidade_id" not in sql


def test_os_dois_ramos_sao_or_e_nao_and():
    """Seguir OU ser recomendado. Um `AND` aqui exigiria as duas coisas ao mesmo tempo."""
    sql = _sql(escopo.clausula_do_feed(LEITOR, [SEGUIDO], [FATEC]))
    assert " OR " in sql
    assert "autor_id IN" in sql
    assert "autor_universidade_id IN" in sql


def test_geral_nao_filtra_tipo_e_os_outros_dois_filtram():
    assert escopo.clausula_de_tipo("geral") is None
    assert "empresa" in _sql(escopo.clausula_de_tipo("empresas"))
    assert "aluno" in _sql(escopo.clausula_de_tipo("pessoas"))


def test_a_origem_do_proprio_post_e_seguindo():
    """Um rótulo "recomendado" no que a pessoa escreveu seria absurdo na tela."""
    assert escopo.origem(LEITOR, LEITOR, set()) == "seguindo"


def test_a_origem_de_quem_se_segue_e_seguindo_e_a_dos_outros_e_recomendado():
    assert escopo.origem(SEGUIDO, LEITOR, {SEGUIDO}) == "seguindo"
    assert escopo.origem(COLEGA, LEITOR, {SEGUIDO}) == "recomendado"


def test_o_post_de_empresa_nasce_sem_universidade_e_por_isso_nao_e_recomendado():
    """A garantia é o NULL: `NULL IN (...)` nunca é verdadeiro.

    Não é efeito colateral — é o que o contrato promete, e vem de graça em vez de
    precisar de uma cláusula própria excluindo empresa da recomendação.
    """
    post = Post(autor_id=uuid4(), autor_tipo=TipoDeAutor.EMPRESA, conteudo="vaga")
    assert post.autor_universidade_id is None
