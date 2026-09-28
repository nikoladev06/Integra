"""A matriz de visibilidade, sem banco e sem HTTP.

Esta é a regra que a Sprint 4 põe à prova, e ela é uma função pura — então o teste
dela também é. Sem banco no caminho, cada caso da matriz é uma linha legível, e a
suíte roda na CI mesmo se o Postgres não subir.

O teste de que a versão SQL concorda com esta mora em `test_regra_integracao.py`:
aqui se verifica *qual* é a regra, lá que as duas escritas dela dizem o mesmo.
"""

from uuid import UUID, uuid4

import pytest

from academic_service.models import Post, Visibilidade
from academic_service.visibilidade import pode_ver
from integra_shared.security import UsuarioAutenticado

FATEC = uuid4()
USP = uuid4()
ADS = uuid4()
GESTAO = uuid4()
CONTA_DA_FATEC = uuid4()


def _post(visibilidade: Visibilidade, *, universidade=FATEC, curso=None, autor=CONTA_DA_FATEC):
    return Post(
        id=uuid4(),
        universidade_id=universidade,
        autor_id=autor,
        visibilidade=visibilidade,
        curso_id=curso,
        conteudo="comunicado",
    )


def _leitor(
    *,
    vinculo_universidade: UUID | None = None,
    vinculo_curso: UUID | None = None,
    tipo="aluno",
    id_=None,
) -> UsuarioAutenticado:
    return UsuarioAutenticado(
        id=id_ or uuid4(),
        tipo=tipo,
        vinculo_universidade_id=vinculo_universidade,
        vinculo_curso_id=vinculo_curso,
    )


# ────────────────────  quem tem vínculo com a instituição  ────────────────────


def test_com_vinculo_ve_publico_institucional_e_o_proprio_curso():
    aluno = _leitor(vinculo_universidade=FATEC, vinculo_curso=ADS)

    assert pode_ver(_post(Visibilidade.PUBLICO), aluno)
    assert pode_ver(_post(Visibilidade.INSTITUCIONAL), aluno)
    assert pode_ver(_post(Visibilidade.CURSO, curso=ADS), aluno)


def test_com_vinculo_nao_ve_post_de_outro_curso_da_mesma_faculdade():
    """A restrição por curso é a única granularidade fina do modelo — e funciona."""
    aluno = _leitor(vinculo_universidade=FATEC, vinculo_curso=ADS)

    assert not pode_ver(_post(Visibilidade.CURSO, curso=GESTAO), aluno)


def test_vinculo_com_outra_faculdade_nao_abre_esta():
    """Ter vínculo não é ter vínculo *aqui*.

    O caso que um `if usuario.tem_vinculo` mal escrito deixaria passar: quem estuda
    na USP lendo o comunicado interno da FATEC.
    """
    aluno_da_usp = _leitor(vinculo_universidade=USP, vinculo_curso=ADS)

    assert pode_ver(_post(Visibilidade.PUBLICO), aluno_da_usp)
    assert not pode_ver(_post(Visibilidade.INSTITUCIONAL), aluno_da_usp)
    # Mesmo com o curso de id igual — o que só acontece em teste, mas prova que a
    # comparação de curso não é usada sozinha.
    assert not pode_ver(_post(Visibilidade.CURSO, curso=ADS), aluno_da_usp)


# ──────────────────  as três coisas que não concedem nada  ──────────────────


def test_sem_vinculo_ve_apenas_os_publicos():
    """Cobre de uma vez seguir, formação declarada e formação verificada antiga.

    Os três têm a mesma assinatura nesta função: **nada**. Nenhum deles aparece em
    `UsuarioAutenticado`, e é isso que os torna impossíveis de confundir com
    vínculo — não é disciplina de quem escreve a consulta, é ausência de campo.
    """
    sem_vinculo = _leitor()

    assert pode_ver(_post(Visibilidade.PUBLICO), sem_vinculo)
    assert not pode_ver(_post(Visibilidade.INSTITUCIONAL), sem_vinculo)
    assert not pode_ver(_post(Visibilidade.CURSO, curso=ADS), sem_vinculo)


def test_o_leitor_sem_vinculo_nao_tem_onde_declarar_formacao():
    """O teste que garante que a regra não *pode* ler formação.

    Se algum dia alguém acrescentar formação ao token, este teste continua
    passando — mas ele documenta o motivo pelo qual hoje não há como a regra
    consultá-la, e falha se o campo de vínculo virar opcional de outro jeito.
    """
    campos = set(UsuarioAutenticado.model_fields)

    assert campos == {"id", "tipo", "vinculo_universidade_id", "vinculo_curso_id"}


# ─────────────────────────  a conta autora do post  ─────────────────────────


def test_a_faculdade_autora_ve_o_que_publicou_em_qualquer_alcance():
    """Conta institucional **não tem vínculo** — vínculo é de aluno.

    Sem esta cláusula a instituição publicava um comunicado restrito a um curso e
    em seguida recebia 404 ao abrir o próprio post.
    """
    faculdade = _leitor(tipo="faculdade", id_=CONTA_DA_FATEC)

    assert pode_ver(_post(Visibilidade.PUBLICO), faculdade)
    assert pode_ver(_post(Visibilidade.INSTITUCIONAL), faculdade)
    assert pode_ver(_post(Visibilidade.CURSO, curso=ADS), faculdade)


def test_outra_faculdade_nao_ve_o_interno_desta():
    """Ser `faculdade` não concede nada: ser **a autora** é que concede."""
    outra = _leitor(tipo="faculdade")

    assert pode_ver(_post(Visibilidade.PUBLICO), outra)
    assert not pode_ver(_post(Visibilidade.INSTITUCIONAL), outra)
    assert not pode_ver(_post(Visibilidade.CURSO, curso=ADS), outra)


# ──────────────────────────  estados degenerados  ──────────────────────────


@pytest.mark.parametrize(
    "visibilidade",
    [Visibilidade.INSTITUCIONAL, Visibilidade.CURSO],
)
def test_post_restrito_com_universidade_de_outra_nunca_vaza(visibilidade):
    """Post de outra instituição, com o curso do leitor. Não basta o curso casar."""
    aluno = _leitor(vinculo_universidade=FATEC, vinculo_curso=ADS)
    post = _post(
        visibilidade, universidade=USP, curso=ADS if visibilidade == Visibilidade.CURSO else None
    )

    assert not pode_ver(post, aluno)


def test_post_restrito_a_curso_sem_curso_nao_e_visivel_a_ninguem():
    """Estado que o `CheckConstraint` do banco impede — e que a regra também recusa.

    Vale testar porque as duas defesas existem por motivos diferentes: a do banco
    impede a linha de ser gravada, esta impede que uma linha vinda de outro lugar
    (uma migração de dados, um `INSERT` manual) apareça para a instituição inteira
    por comparação com `NULL`.
    """
    aluno = _leitor(vinculo_universidade=FATEC, vinculo_curso=ADS)
    post = _post(Visibilidade.CURSO, curso=None, autor=uuid4())

    assert not pode_ver(post, aluno)
