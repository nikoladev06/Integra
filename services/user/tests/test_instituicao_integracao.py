"""Cadastro institucional: reivindicação por CNPJ e o estado de ativação.

Duas regras nascem aqui, e as duas existem para o **selo de verificado** continuar
significando algo:

1. o CNPJ decide qual universidade a conta administra, então não aparecem duas
   FATEC na busca com os alunos divididos entre elas;
2. a conta nasce pendente, então consultar o CNPJ público de uma faculdade não
   basta para distribuir formações verificadas no nome dela.
"""

from uuid import uuid4

import pytest
from sqlalchemy import select

from integra_shared.cnpj import formatar as formatar_cnpj
from integra_shared.cnpj import gerar_valido as gerar_cnpj
from integra_shared.cpf import gerar_valido as gerar_cpf
from integra_shared.errors import AppError
from user_service.models import TipoConta, Universidade
from user_service.schemas import CriarInstituicaoIn, CriarUsuarioIn
from user_service.services import instituicoes, perfis

# Uma para a universidade que o teste catalogá e outra para a que ele cria do
# zero. Sementes fixas, então o CNPJ é o mesmo em toda execução.
CNPJ_CATALOGO = gerar_cnpj(27_182_818)
CNPJ_NOVO = gerar_cnpj(31_415_926)
CPF_ALUNA = gerar_cpf(660_001)


async def _catalogada(sessao, cnpj: str, sigla: str = "CAT") -> Universidade:
    """Universidade no catálogo, **sem conta**, criada pelo próprio teste.

    Não usa a FATEC do seed de propósito. Depender dela faria o teste ler estado
    que não criou: qualquer cadastro feito à mão contra o mesmo banco a deixa com
    dono, e a partir daí a reivindicação falha por um motivo que não tem nada a
    ver com o que o teste verifica. Foi exatamente o que aconteceu.
    """
    universidade = Universidade(nome=f"Instituicao {sigla} {cnpj[:6]}", sigla=sigla, cnpj=cnpj)
    sessao.add(universidade)
    await sessao.flush()
    return universidade


def _dados(
    cnpj: str, *, tipo=TipoConta.FACULDADE, sufixo="x", nome="Instituto Exemplo", sigla=None
):
    return CriarInstituicaoIn(
        id=uuid4(),
        tipo=tipo,
        nome=nome,
        cnpj=cnpj,
        email=f"conta_{sufixo}@exemplo.com",
        username=f"conta_{sufixo}",
        telefone="(16)3333-0000",
        sigla=sigla,
    )


class TestReivindicacao:
    async def test_cnpj_conhecido_reivindica_a_linha_existente(self, sessao):
        """Não cria uma segunda linha: assume a que os alunos já seguem."""
        catalogada = await _catalogada(sessao, CNPJ_CATALOGO)
        antes = len((await sessao.execute(select(Universidade))).unique().scalars().all())

        conta = await instituicoes.criar_conta(sessao, _dados(CNPJ_CATALOGO, sufixo="reivindica"))

        depois = len((await sessao.execute(select(Universidade))).unique().scalars().all())
        assert depois == antes, "reivindicar não deve criar universidade nova"

        await sessao.refresh(catalogada)
        assert catalogada.conta_id == conta.id
        assert catalogada.tem_conta is True

    async def test_cnpj_desconhecido_cria_universidade_nova(self, sessao):
        """O controle do teste acima.

        Sem ele, uma implementação que NUNCA criasse — só reivindicasse — passaria
        igual, e uma faculdade fora do catálogo não conseguiria se cadastrar.
        """
        antes = len((await sessao.execute(select(Universidade))).unique().scalars().all())

        conta = await instituicoes.criar_conta(
            sessao,
            _dados(CNPJ_NOVO, sufixo="nova", nome="Centro Universitario Exemplo", sigla="CUE"),
        )

        depois = len((await sessao.execute(select(Universidade))).unique().scalars().all())
        assert depois == antes + 1

        nova = (
            await sessao.execute(select(Universidade).where(Universidade.cnpj == CNPJ_NOVO))
        ).scalar_one()
        assert nova.conta_id == conta.id
        assert nova.sigla == "CUE"

    async def test_sem_sigla_usa_as_iniciais_do_nome(self, sessao):
        await instituicoes.criar_conta(
            sessao,
            _dados(CNPJ_NOVO, sufixo="iniciais", nome="Centro Universitario Exemplo"),
        )
        nova = (
            await sessao.execute(select(Universidade).where(Universidade.cnpj == CNPJ_NOVO))
        ).scalar_one()
        assert nova.sigla == "CUE"

    async def test_universidade_ja_administrada_e_conflito(self, sessao):
        """O caso do impostor: o CNPJ é público, mas a linha já tem dono."""
        await _catalogada(sessao, CNPJ_CATALOGO)
        await instituicoes.criar_conta(sessao, _dados(CNPJ_CATALOGO, sufixo="primeira"))

        with pytest.raises(AppError) as erro:
            await instituicoes.criar_conta(
                sessao, _dados(formatar_cnpj(CNPJ_CATALOGO), sufixo="segunda")
            )

        # 409 e não 422: o valor está correto, o que falta é disponibilidade.
        assert erro.value.status_code == 409
        assert erro.value.code in {"cnpj_ja_cadastrado", "universidade_ja_administrada"}

    async def test_cnpj_pontuado_reivindica_igual(self, sessao):
        catalogada = await _catalogada(sessao, CNPJ_CATALOGO)
        conta = await instituicoes.criar_conta(
            sessao, _dados(formatar_cnpj(CNPJ_CATALOGO), sufixo="pontuado")
        )
        await sessao.refresh(catalogada)
        assert conta.cnpj == CNPJ_CATALOGO
        assert catalogada.conta_id == conta.id

    async def test_cnpj_invalido_e_recusado(self, sessao):
        with pytest.raises(AppError) as erro:
            await instituicoes.criar_conta(sessao, _dados("11111111111111", sufixo="ruim"))
        assert erro.value.status_code == 422
        assert erro.value.fields is not None
        assert erro.value.fields["cnpj"] == ["CNPJ inválido"]

    async def test_empresa_nao_cria_universidade(self, sessao):
        antes = len((await sessao.execute(select(Universidade))).unique().scalars().all())

        conta = await instituicoes.criar_conta(
            sessao, _dados(CNPJ_NOVO, tipo=TipoConta.EMPRESA, sufixo="empresa", nome="Acme")
        )

        depois = len((await sessao.execute(select(Universidade))).unique().scalars().all())
        assert depois == antes, "empresa não é instituição de ensino"
        assert conta.tipo == TipoConta.EMPRESA
        assert conta.cnpj is not None


class TestAtivacao:
    async def test_conta_institucional_nasce_pendente(self, sessao):
        """A regra que preserva o sentido do selo."""
        conta = await instituicoes.criar_conta(sessao, _dados(CNPJ_NOVO, sufixo="pendente"))

        assert conta.ativada_em is None
        assert conta.ativa is False

    async def test_conta_de_aluno_nasce_ATIVA(self, sessao):
        """O controle do teste acima.

        Sem ele, uma implementação que deixasse TODA conta pendente passaria — e
        nenhum aluno conseguiria usar o app.
        """
        aluna = await perfis.criar(
            sessao,
            CriarUsuarioIn(
                id=uuid4(),
                nome_completo="Ana Paula Souza",
                email="aluna_ativa@exemplo.com",
                username="aluna_ativa",
                cpf=CPF_ALUNA,
                telefone="(16)99999-0000",
            ),
        )
        assert aluna.ativada_em is not None
        assert aluna.ativa is True

    async def test_ativar_libera_a_conta(self, sessao):
        conta = await instituicoes.criar_conta(sessao, _dados(CNPJ_NOVO, sufixo="ativa"))
        assert conta.ativa is False

        ativada = await instituicoes.ativar(sessao, conta.email)
        assert ativada.ativa is True
        assert ativada.ativada_em is not None

    async def test_ativar_conta_de_aluno_e_recusado(self, sessao):
        aluna = await perfis.criar(
            sessao,
            CriarUsuarioIn(
                id=uuid4(),
                nome_completo="Ana Paula Souza",
                email="aluna_ativar@exemplo.com",
                username="aluna_ativar",
                cpf=CPF_ALUNA,
            ),
        )
        with pytest.raises(AppError) as erro:
            await instituicoes.ativar(sessao, aluna.email)
        assert erro.value.status_code == 409

    async def test_ativar_email_inexistente_responde_404(self, sessao):
        with pytest.raises(AppError) as erro:
            await instituicoes.ativar(sessao, "ninguem@exemplo.com")
        assert erro.value.status_code == 404


class TestCpfEcnpjSaoExclusivos:
    async def test_conta_institucional_nao_tem_cpf(self, sessao):
        """Manter o CPF da pessoa física na conta institucional a deixaria
        elegível a vínculo de aluno — e uma faculdade não estuda em si mesma."""
        conta = await instituicoes.criar_conta(sessao, _dados(CNPJ_NOVO, sufixo="sem_cpf"))
        assert conta.cpf is None
        assert conta.cnpj is not None

    async def test_conta_de_aluno_nao_tem_cnpj(self, sessao):
        aluna = await perfis.criar(
            sessao,
            CriarUsuarioIn(
                id=uuid4(),
                nome_completo="Ana Paula Souza",
                email="aluna_sem_cnpj@exemplo.com",
                username="aluna_sem_cnpj",
                cpf=CPF_ALUNA,
            ),
        )
        assert aluna.cnpj is None
        assert aluna.cpf is not None
