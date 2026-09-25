"""Recusa do user-service não deixa credencial órfã.

O cadastro grava a credencial **antes** de chamar o user-service para criar o
perfil. Se a segunda etapa recusar — CPF ou CNPJ já cadastrado, username em uso —
a credencial não pode sobreviver: o e-mail daquela tentativa ficaria preso, e a
pessoa veria "Email já cadastrado" ao tentar de novo com o CPF certo. Um beco sem
saída, e sem nada no banco explicando o motivo.

O user-service é substituído por um dublê HTTP (`respx`); o banco é o Postgres de
verdade, pela fixture compartilhada. A integração entre os dois serviços foi
conferida contra a stack rodando — o que estes testes fixam é a compensação, que
é lógica deste serviço.
"""

from uuid import uuid4

import httpx
import pytest
import respx
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth_service.models import Credencial
from auth_service.schemas import CadastroIn, CadastroInstituicaoIn
from auth_service.services import registro
from auth_service.settings import settings
from integra_shared.cnpj import gerar_valido as gerar_cnpj
from integra_shared.cpf import gerar_valido as gerar_cpf
from integra_shared.errors import AppError

CPF = gerar_cpf(120_001)
CNPJ = gerar_cnpj(120_002)

# E-mails só destes testes, para as asserções não cruzarem com dados de
# outros testes nem com cadastros feitos à mão contra o mesmo banco.
EMAIL_ALUNA = "compensacao-aluna@teste.integra"
EMAIL_EMPRESA = "compensacao-empresa@teste.integra"

URL_PERFIL = f"{settings.user_service_url}/users/interno"
URL_CONTA = f"{settings.user_service_url}/universidades/interno/conta"


# A sessão vem da fixture compartilhada em `services/conftest.py`: Postgres de
# verdade, numa transação desfeita ao fim do teste.
#
# A primeira versão disto usava SQLite em memória e removia o schema `auth` dos
# metadados para caber — duas coisas erradas. Mutar `Base.metadata` é estado
# global que vaza para qualquer teste que rode depois, e trocar de banco
# contradiz o motivo pelo qual o resto da suíte usa Postgres: schema, ON CONFLICT
# e UUID nativo não existem lá, então o teste passaria contra outro banco.


async def _existe_credencial(sessao: AsyncSession, email: str) -> bool:
    """Existe credencial para ESTE e-mail.

    Contar o total do banco seria asserção sobre estado compartilhado: qualquer
    cadastro feito à mão contra o mesmo Postgres muda o número, e o teste falha
    por um motivo que não tem nada a ver com o que ele verifica. Foi o que
    aconteceu na primeira versão.
    """
    total = (
        await sessao.execute(
            select(func.count()).select_from(Credencial).where(Credencial.email == email)
        )
    ).scalar_one()
    return bool(total)


def _cadastro_de_aluno() -> CadastroIn:
    return CadastroIn(
        nome_completo="Ana Paula Souza",
        email=EMAIL_ALUNA,
        username="ana_souza",
        senha="integra123",
        telefone="(16)99999-1234",
        cpf=CPF,
    )


def _cadastro_de_instituicao() -> CadastroInstituicaoIn:
    return CadastroInstituicaoIn(
        tipo="empresa",
        nome="Acme Ltda",
        cnpj=CNPJ,
        email=EMAIL_EMPRESA,
        username="acme",
        senha="integra123",
        telefone="(16)3333-0000",
    )


class TestCpfDuplicado:
    @respx.mock
    async def test_recusa_propaga_a_mensagem_do_user_service(self, sessao):
        respx.post(URL_PERFIL).mock(
            return_value=httpx.Response(
                409, json={"code": "cpf_ja_cadastrado", "message": "CPF já cadastrado"}
            )
        )

        with pytest.raises(AppError) as erro:
            await registro.cadastrar(sessao, _cadastro_de_aluno())

        # A mensagem vem do user-service, não é reescrita aqui: só ele sabe que o
        # conflito foi de CPF, e traduzir para algo genérico esconderia do usuário
        # qual campo corrigir.
        assert erro.value.status_code == 409
        assert erro.value.code == "cpf_ja_cadastrado"
        assert erro.value.message == "CPF já cadastrado"

    @respx.mock
    async def test_recusa_nao_deixa_credencial(self, sessao):
        """O teste que importa: o e-mail tem que voltar a estar livre."""
        respx.post(URL_PERFIL).mock(
            return_value=httpx.Response(
                409, json={"code": "cpf_ja_cadastrado", "message": "CPF já cadastrado"}
            )
        )

        with pytest.raises(AppError):
            await registro.cadastrar(sessao, _cadastro_de_aluno())

        assert not await _existe_credencial(sessao, EMAIL_ALUNA)

    @respx.mock
    async def test_sucesso_DEIXA_a_credencial(self, sessao):
        """O controle.

        Sem este teste, uma compensação que apagasse a credencial SEMPRE passaria
        no teste acima — e ninguém conseguiria criar conta.
        """
        respx.post(URL_PERFIL).mock(return_value=httpx.Response(201, json={}))

        usuario_id = await registro.cadastrar(sessao, _cadastro_de_aluno())

        assert await _existe_credencial(sessao, EMAIL_ALUNA)
        guardada = await sessao.get(Credencial, usuario_id)
        assert guardada is not None
        assert guardada.email == EMAIL_ALUNA
        # A senha nunca é guardada em claro.
        assert "integra123" not in guardada.senha_hash

    @respx.mock
    async def test_user_service_fora_do_ar_tambem_compensa(self, sessao):
        """Falha de rede é diferente de recusa, e as duas precisam compensar."""
        respx.post(URL_PERFIL).mock(side_effect=httpx.ConnectError("sem rota"))

        with pytest.raises(AppError) as erro:
            await registro.cadastrar(sessao, _cadastro_de_aluno())

        assert erro.value.status_code == 503
        assert erro.value.code == "cadastro_indisponivel"
        assert not await _existe_credencial(sessao, EMAIL_ALUNA)

    @respx.mock
    async def test_resposta_inesperada_vira_502_e_compensa(self, sessao):
        """Um 500 do user-service não é culpa do usuário, e não é 409 nem 422."""
        respx.post(URL_PERFIL).mock(return_value=httpx.Response(500, text="boom"))

        with pytest.raises(AppError) as erro:
            await registro.cadastrar(sessao, _cadastro_de_aluno())

        assert erro.value.status_code == 502
        assert not await _existe_credencial(sessao, EMAIL_ALUNA)


class TestCnpjDuplicado:
    @respx.mock
    async def test_recusa_propaga_a_mensagem_e_nao_deixa_credencial(self, sessao):
        respx.post(URL_CONTA).mock(
            return_value=httpx.Response(
                409, json={"code": "cnpj_ja_cadastrado", "message": "CNPJ já cadastrado"}
            )
        )

        with pytest.raises(AppError) as erro:
            await registro.cadastrar_instituicao(sessao, _cadastro_de_instituicao())

        assert erro.value.status_code == 409
        assert erro.value.code == "cnpj_ja_cadastrado"
        assert erro.value.message == "CNPJ já cadastrado"
        assert not await _existe_credencial(sessao, EMAIL_EMPRESA)

    @respx.mock
    async def test_instituicao_ja_administrada_tambem_compensa(self, sessao):
        respx.post(URL_CONTA).mock(
            return_value=httpx.Response(
                409,
                json={
                    "code": "universidade_ja_administrada",
                    "message": "Esta instituição já tem uma conta cadastrada",
                },
            )
        )

        with pytest.raises(AppError) as erro:
            await registro.cadastrar_instituicao(sessao, _cadastro_de_instituicao())

        assert erro.value.code == "universidade_ja_administrada"
        assert not await _existe_credencial(sessao, EMAIL_EMPRESA)

    @respx.mock
    async def test_sucesso_DEIXA_a_credencial(self, sessao):
        respx.post(URL_CONTA).mock(return_value=httpx.Response(201, json={}))

        conta_id = await registro.cadastrar_instituicao(sessao, _cadastro_de_instituicao())

        assert await _existe_credencial(sessao, EMAIL_EMPRESA)
        assert await sessao.get(Credencial, conta_id) is not None


class TestValidacaoAntesDeGravar:
    @respx.mock
    async def test_cpf_invalido_nem_chama_o_user_service(self, sessao):
        """Validação local primeiro: não faz sentido gastar uma chamada de rede
        para descobrir que o CPF tem dígito verificador errado."""
        rota = respx.post(URL_PERFIL).mock(return_value=httpx.Response(201, json={}))

        dados = _cadastro_de_aluno()
        dados.cpf = "11111111111"

        with pytest.raises(AppError) as erro:
            await registro.cadastrar(sessao, dados)

        assert erro.value.status_code == 422
        assert erro.value.fields is not None
        assert erro.value.fields["cpf"] == ["CPF inválido"]
        assert not rota.called, "não deveria ter chamado o user-service"
        assert not await _existe_credencial(sessao, EMAIL_ALUNA)

    @respx.mock
    async def test_cnpj_invalido_nem_chama_o_user_service(self, sessao):
        rota = respx.post(URL_CONTA).mock(return_value=httpx.Response(201, json={}))

        dados = _cadastro_de_instituicao()
        dados.cnpj = "11111111111111"

        with pytest.raises(AppError) as erro:
            await registro.cadastrar_instituicao(sessao, dados)

        assert erro.value.status_code == 422
        assert erro.value.fields is not None
        assert erro.value.fields["cnpj"] == ["CNPJ inválido"]
        assert not rota.called
        assert not await _existe_credencial(sessao, EMAIL_EMPRESA)

    @respx.mock
    async def test_email_duplicado_para_antes_da_rede(self, sessao):
        rota = respx.post(URL_PERFIL).mock(return_value=httpx.Response(201, json={}))
        sessao.add(Credencial(id=uuid4(), email=EMAIL_ALUNA, senha_hash="irrelevante"))
        await sessao.flush()

        with pytest.raises(AppError) as erro:
            await registro.cadastrar(sessao, _cadastro_de_aluno())

        assert erro.value.code == "email_ja_cadastrado"
        assert not rota.called
