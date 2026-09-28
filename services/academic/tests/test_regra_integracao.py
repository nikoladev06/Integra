"""A regra de visibilidade contra um Postgres de verdade.

Dois trabalhos distintos, e o segundo é o que justifica o arquivo existir:

1. **O portão da Sprint 4.** A faculdade publica restrito a um curso; o aluno com
   vínculo naquele curso recebe; o aluno que apenas *declarou* a mesma formação
   não recebe. É a frase do plano, executável.

2. **As duas escritas da regra concordam.** `pode_ver` (Python) e
   `clausula_de_visibilidade` (SQL) são a mesma regra escrita duas vezes, e
   duplicação de regra diverge calada. O teste monta todas as combinações de post
   e leitor, roda a consulta e compara com a função — se uma passar a dizer algo
   que a outra não diz, ele aponta exatamente qual caso.

Nada aqui precisa do schema `user`. `universidade_id`, `curso_id` e `autor_id` são
identificadores **opacos** neste serviço, sem chave estrangeira para o outro lado —
então os testes usam UUID inventado e não dependem de seed nenhum. É consequência
direta da decisão de modelagem, e um bom sinal de que a fronteira está no lugar.
"""

from itertools import product
from uuid import uuid4

import pytest
from sqlalchemy import select

from academic_service.models import Post, Visibilidade
from academic_service.visibilidade import clausula_de_visibilidade, pode_ver
from integra_shared.security import UsuarioAutenticado

FATEC = uuid4()
USP = uuid4()
ADS = uuid4()
GESTAO = uuid4()
CONTA_DA_FATEC = uuid4()
CONTA_DA_USP = uuid4()


def _leitor(*, universidade=None, curso=None, tipo="aluno", id_=None) -> UsuarioAutenticado:
    return UsuarioAutenticado(
        id=id_ or uuid4(),
        tipo=tipo,
        vinculo_universidade_id=universidade,
        vinculo_curso_id=curso,
    )


async def _publicar(sessao, visibilidade, *, universidade=FATEC, curso=None, autor=CONTA_DA_FATEC):
    post = Post(
        universidade_id=universidade,
        autor_id=autor,
        visibilidade=visibilidade,
        curso_id=curso,
        conteudo=f"comunicado {visibilidade.value}",
    )
    sessao.add(post)
    await sessao.flush()
    return post


async def _visiveis(sessao, usuario) -> set:
    """Os ids que a consulta devolve — a regra na forma SQL."""
    consulta = select(Post.id).where(clausula_de_visibilidade(usuario))
    return set((await sessao.execute(consulta)).scalars())


# ─────────────────────────  o portão da Sprint 4  ─────────────────────────


async def test_restrito_a_curso_chega_a_quem_tem_vinculo_naquele_curso(sessao):
    post = await _publicar(sessao, Visibilidade.CURSO, curso=ADS)

    com_vinculo_em_ads = _leitor(universidade=FATEC, curso=ADS)

    assert post.id in await _visiveis(sessao, com_vinculo_em_ads)


async def test_quem_so_declarou_a_formacao_nao_recebe_o_restrito(sessao):
    """**A frase do portão da sprint.**

    Note o que o leitor deste teste é: um aluno sem vínculo nenhum. É exatamente o
    que sobra de quem declarou a formação no perfil — formação declarada não entra
    no token, não chega à consulta, e não concede nada. Na v1 este teste falharia,
    porque o acesso vinha da afiliação que o próprio usuário digitava.
    """
    restrito = await _publicar(sessao, Visibilidade.CURSO, curso=ADS)
    interno = await _publicar(sessao, Visibilidade.INSTITUCIONAL)
    publico = await _publicar(sessao, Visibilidade.PUBLICO)

    so_declarou = _leitor()
    visiveis = await _visiveis(sessao, so_declarou)

    assert restrito.id not in visiveis
    assert interno.id not in visiveis
    assert publico.id in visiveis


async def test_formacao_verificada_sem_vinculo_ativo_tambem_nao_concede(sessao):
    """Quem se formou mantém o selo e volta a ver só os públicos.

    No banco, "formação verificada sem vínculo" e "nunca estudou lá" produzem o
    **mesmo** leitor: token sem vínculo. Que os dois sejam indistinguíveis aqui é
    a garantia — não há como o selo influenciar a consulta, porque ele não chega.
    """
    interno = await _publicar(sessao, Visibilidade.INSTITUCIONAL)

    formado = _leitor()

    assert interno.id not in await _visiveis(sessao, formado)


async def test_seguir_nao_abre_o_conteudo_interno(sessao):
    """Seguir não aparece nesta consulta, e é o ponto.

    A lista de seguidas decide **quais universidades entram no feed**, num parâmetro
    separado (`Post.universidade_id.in_(...)`, em `services.posts.listar`). Aqui não
    há como ela conceder nada, porque não é argumento desta função.
    """
    interno = await _publicar(sessao, Visibilidade.INSTITUCIONAL)

    seguidor_sem_vinculo = _leitor()

    assert interno.id not in await _visiveis(sessao, seguidor_sem_vinculo)


async def test_aluno_de_outro_curso_da_mesma_faculdade_nao_recebe(sessao):
    de_ads = await _publicar(sessao, Visibilidade.CURSO, curso=ADS)
    de_gestao = await _publicar(sessao, Visibilidade.CURSO, curso=GESTAO)

    aluno_de_gestao = _leitor(universidade=FATEC, curso=GESTAO)
    visiveis = await _visiveis(sessao, aluno_de_gestao)

    assert de_gestao.id in visiveis
    assert de_ads.id not in visiveis


async def test_a_faculdade_autora_alcanca_o_que_publicou(sessao):
    """Conta institucional não tem vínculo — quem a autoriza é ser a autora."""
    restrito = await _publicar(sessao, Visibilidade.CURSO, curso=ADS)
    interno = await _publicar(sessao, Visibilidade.INSTITUCIONAL)

    faculdade = _leitor(tipo="faculdade", id_=CONTA_DA_FATEC)
    visiveis = await _visiveis(sessao, faculdade)

    assert {restrito.id, interno.id} <= visiveis


async def test_faculdade_nao_le_o_interno_de_outra(sessao):
    da_usp = await _publicar(
        sessao, Visibilidade.INSTITUCIONAL, universidade=USP, autor=CONTA_DA_USP
    )

    fatec = _leitor(tipo="faculdade", id_=CONTA_DA_FATEC)

    assert da_usp.id not in await _visiveis(sessao, fatec)


# ────────────────  as duas escritas da regra dizem o mesmo  ────────────────


async def test_as_duas_formas_da_regra_concordam(sessao):
    """`pode_ver` (Python) contra `clausula_de_visibilidade` (SQL), em todas as combinações.

    É o teste que paga a duplicação. Sem ele, um `or_` a mais no SQL — ou um
    `return True` antecipado no Python — passaria como melhoria de performance e
    viraria vazamento, porque nenhum caso de uso exercita as duas formas no mesmo
    caminho: o feed usa só o SQL, o detalhe e o comentário usam só o Python.
    """
    alcances = [
        (Visibilidade.PUBLICO, None),
        (Visibilidade.INSTITUCIONAL, None),
        (Visibilidade.CURSO, ADS),
        (Visibilidade.CURSO, GESTAO),
    ]
    instituicoes = [(FATEC, CONTA_DA_FATEC), (USP, CONTA_DA_USP)]

    publicados = [
        await _publicar(sessao, visibilidade, universidade=uni, curso=curso, autor=conta)
        for (visibilidade, curso), (uni, conta) in product(alcances, instituicoes)
    ]

    leitores = {
        "sem vínculo": _leitor(),
        "vínculo FATEC/ADS": _leitor(universidade=FATEC, curso=ADS),
        "vínculo FATEC/Gestão": _leitor(universidade=FATEC, curso=GESTAO),
        "vínculo USP/ADS": _leitor(universidade=USP, curso=ADS),
        "conta da FATEC": _leitor(tipo="faculdade", id_=CONTA_DA_FATEC),
        "conta da USP": _leitor(tipo="faculdade", id_=CONTA_DA_USP),
        "empresa": _leitor(tipo="empresa"),
    }

    for rotulo, leitor in leitores.items():
        pelo_sql = await _visiveis(sessao, leitor)
        pelo_python = {p.id for p in publicados if pode_ver(p, leitor)}

        # Só os posts deste teste entram na comparação: a transação é desfeita ao
        # fim, mas outros casos do mesmo arquivo podem ter gravado antes dentro
        # dela, e o SQL os enxerga.
        deste_teste = {p.id for p in publicados}

        assert pelo_sql & deste_teste == pelo_python, (
            f"as duas formas da regra divergem para «{rotulo}»: "
            f"só no SQL={sorted((pelo_sql & deste_teste) - pelo_python)}, "
            f"só no Python={sorted(pelo_python - (pelo_sql & deste_teste))}"
        )


async def test_o_check_do_banco_recusa_curso_sem_alcance_de_curso(sessao):
    """A invariante do registro, provada no banco e não no schema Pydantic.

    O validador do Pydantic recusa o mesmo corpo na entrada. Este teste é sobre a
    segunda linha de defesa: uma migração de dados, ou um `INSERT` de script, não
    passa pelo Pydantic — e um post `institucional` com `curso_id` pareceria
    restrito sem ser, enquanto um `curso` sem `curso_id` ficaria invisível para
    todo mundo sem erro nenhum.
    """
    from sqlalchemy.exc import IntegrityError

    # Savepoint: uma violação de constraint aborta a transação no Postgres, e sem
    # o ponto de retorno o rollback do fixture reclamaria de transação já desfeita.
    ponto = await sessao.begin_nested()

    sessao.add(
        Post(
            universidade_id=FATEC,
            autor_id=CONTA_DA_FATEC,
            visibilidade=Visibilidade.INSTITUCIONAL,
            curso_id=ADS,  # sobrando
            conteudo="restrição que não existe",
        )
    )

    with pytest.raises(IntegrityError, match="curso_id_exatamente_quando_restrito_a_curso"):
        await sessao.flush()

    await ponto.rollback()
