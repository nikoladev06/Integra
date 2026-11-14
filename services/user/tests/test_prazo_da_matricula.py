"""O prazo da matrícula, contra um Postgres de verdade.

A regra: a instituição declara a duração do curso em semestres, cadastra o aluno
por CPF, e a contagem começa nessa data. Quando os semestres passam, a matrícula
sai e o vínculo sai com ela — o aluno volta a ver apenas os posts públicos — e
**a formação continua verificada**, que é o selo ao lado do nome da faculdade no
currículo dele.

O tempo não é mockado. Os testes empurram `Matricula.criado_em` para o passado,
que é a única coisa que o relógio real não faz num teste: uma matrícula de três
anos atrás. Mockar `datetime.now` esconderia justamente o que dá errado aqui — a
soma em meses de calendário.
"""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from sqlalchemy import select

from integra_shared.cpf import gerar_valido
from integra_shared.errors import AppError
from user_service.models import Matricula, TipoConta, Universidade, somar_semestres
from user_service.schemas import CriarCursoIn, CriarUsuarioIn
from user_service.services import formacoes, instituicoes, perfis, vinculos

CPF_ALUNA = gerar_valido(660_101)
CPF_COLEGA = gerar_valido(660_202)


async def _fatec(sessao):
    """A FATEC do seed, com uma conta institucional recém-criada administrando-a."""
    uni = (
        (await sessao.execute(select(Universidade).where(Universidade.sigla == "FATEC RP")))
        .unique()
        .scalar_one_or_none()
    )
    if uni is None:
        pytest.skip("banco sem seed — rode `python -m user_service.seed` primeiro")

    sufixo = uuid4().hex[:8]
    conta = await perfis.criar(
        sessao,
        CriarUsuarioIn(
            id=uuid4(),
            nome_completo="Secretaria FATEC",
            email=f"sec-prazo-{sufixo}@exemplo.com",
            username=f"sec_prazo_{sufixo}",
            cpf=gerar_valido(661_303),
            tipo=TipoConta.FACULDADE,
        ),
    )
    conta.cpf = None
    uni.conta_id = conta.id
    await sessao.flush()
    return uni


async def _aluna(sessao, *, cpf: str, username: str):
    return await perfis.criar(
        sessao,
        CriarUsuarioIn(
            id=uuid4(),
            nome_completo=f"Pessoa {username}",
            email=f"{username}@exemplo.com",
            username=username,
            cpf=cpf,
            telefone="(16)99999-0000",
        ),
    )


async def _curso(sessao, universidade, *, semestres: int):
    return await instituicoes.criar_curso(
        sessao,
        universidade.id,
        f"Curso {uuid4().hex[:8]}",
        duracao_semestres=semestres,
    )


async def _envelhecer(sessao, matricula: Matricula, *, semestres: int) -> None:
    """Empurra `criado_em` para trás até o prazo de `semestres` ter vencido ontem."""
    matricula.criado_em = somar_semestres(datetime.now(UTC) - timedelta(days=1), -semestres)
    await sessao.flush()


class TestDuracaoDoCurso:
    def test_curso_novo_exige_duracao(self):
        """O campo não tem padrão: esquecer dá erro de validação, não um prazo torto."""
        with pytest.raises(ValueError):
            CriarCursoIn(nome="Curso Sem Prazo")  # type: ignore[call-arg]

    def test_duracao_fora_da_faixa_e_recusada(self):
        """Dez anos é o teto. Um dígito a mais na tela da secretaria para aqui."""
        for semestres in (0, -3, 21):
            with pytest.raises(ValueError):
                CriarCursoIn(nome="Curso Implausivel", duracao_semestres=semestres)

    async def test_duracao_entra_no_curso_criado(self, sessao):
        fatec = await _fatec(sessao)
        curso = await _curso(sessao, fatec, semestres=4)
        assert curso.duracao_semestres == 4


class TestContagem:
    def test_semestre_e_meio_ano_de_calendario(self):
        """Seis meses por semestre, não 182 dias — e fevereiro não tem dia 31."""
        assert somar_semestres(datetime(2026, 3, 10, tzinfo=UTC), 6) == datetime(
            2029, 3, 10, tzinfo=UTC
        )
        assert somar_semestres(datetime(2026, 8, 31, tzinfo=UTC), 1) == datetime(
            2027, 2, 28, tzinfo=UTC
        )

    async def test_prazo_sai_da_data_do_cadastro_e_da_duracao(self, sessao):
        fatec = await _fatec(sessao)
        curso = await _curso(sessao, fatec, semestres=8)
        matricula = await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso.id)

        assert matricula.expira_em == somar_semestres(matricula.criado_em, 8)
        assert matricula.vencida is False

    async def test_curso_sem_duracao_declarada_nao_vence(self, sessao):
        """As linhas que existiam antes da regra. Sem prazo inventado para elas."""
        fatec = await _fatec(sessao)
        curso = await _curso(sessao, fatec, semestres=6)
        curso.duracao_semestres = None
        await sessao.flush()

        matricula = await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso.id)
        await _envelhecer(sessao, matricula, semestres=20)

        assert matricula.expira_em is None
        assert matricula.vencida is False
        assert await instituicoes.expirar_matriculas_vencidas(sessao, universidade_id=fatec.id) == 0


class TestExpiracao:
    async def test_prazo_vencido_apaga_matricula_e_vinculo_e_MANTEM_o_selo(self, sessao):
        """A regra inteira numa passada. O selo é a metade que se perde fácil."""
        fatec = await _fatec(sessao)
        curso = await _curso(sessao, fatec, semestres=2)
        matricula = await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso.id)
        aluna = await _aluna(sessao, cpf=CPF_ALUNA, username=f"formanda_{uuid4().hex[:6]}")
        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)
        assert await vinculos.obter(sessao, aluna.id) is not None

        await _envelhecer(sessao, matricula, semestres=2)
        removidas = await instituicoes.expirar_matriculas_vencidas(sessao, usuario_id=aluna.id)

        assert removidas == 1
        assert await vinculos.obter(sessao, aluna.id) is None, "sem vínculo, sem post privado"
        restou = (
            await sessao.execute(select(Matricula).where(Matricula.id == matricula.id))
        ).scalar_one_or_none()
        assert restou is None

        selos = [
            f.universidade.sigla for f in await formacoes.listar(sessao, aluna.id) if f.verificada
        ]
        assert selos == ["FATEC RP"], "o verificado fica no currículo"

    async def test_dentro_do_prazo_nada_e_apagado(self, sessao):
        """O controle: sem ele, uma varredura que apagasse TUDO passaria igual."""
        fatec = await _fatec(sessao)
        curso = await _curso(sessao, fatec, semestres=8)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso.id)
        aluna = await _aluna(sessao, cpf=CPF_ALUNA, username=f"cursando_{uuid4().hex[:6]}")
        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        assert await instituicoes.expirar_matriculas_vencidas(sessao, usuario_id=aluna.id) == 0
        assert await vinculos.obter(sessao, aluna.id) is not None

    async def test_varredura_de_um_aluno_nao_toca_na_matricula_de_outro(self, sessao):
        """O escopo por usuário serve a rota do token; não pode vazar para o resto."""
        fatec = await _fatec(sessao)
        curso = await _curso(sessao, fatec, semestres=2)
        minha = await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso.id)
        da_colega = await instituicoes.criar_matricula(sessao, fatec.id, CPF_COLEGA, curso.id)
        aluna = await _aluna(sessao, cpf=CPF_ALUNA, username=f"minha_{uuid4().hex[:6]}")
        await _envelhecer(sessao, minha, semestres=2)
        await _envelhecer(sessao, da_colega, semestres=2)

        assert await instituicoes.expirar_matriculas_vencidas(sessao, usuario_id=aluna.id) == 1

        restante = (
            await sessao.execute(select(Matricula).where(Matricula.id == da_colega.id))
        ).scalar_one_or_none()
        assert restante is not None, "a matrícula da colega não é desta varredura"

    async def test_conta_institucional_nao_tem_o_que_vencer(self, sessao):
        """CPF nulo por construção: a varredura responde 0 em vez de casar com NULL."""
        fatec = await _fatec(sessao)
        assert fatec.conta_id is not None
        vencidas = await instituicoes.expirar_matriculas_vencidas(sessao, usuario_id=fatec.conta_id)
        assert vencidas == 0

    async def test_lista_da_instituicao_varre_antes_de_mostrar(self, sessao):
        """A tela da secretaria é um dos dois relógios da regra."""
        fatec = await _fatec(sessao)
        curso = await _curso(sessao, fatec, semestres=2)
        matricula = await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso.id)
        await _envelhecer(sessao, matricula, semestres=2)

        linhas = await instituicoes.listar_matriculas(sessao, fatec.id)

        assert matricula.id not in {m.id for m, _ in linhas}


class TestReentrada:
    async def test_inserir_o_cpf_de_novo_depois_do_prazo_e_recusado(self, sessao):
        """O guarda que importa.

        Sem ele, uma matrícula vencida que a varredura ainda não alcançou
        devolveria acesso completo a quem inserisse o CPF.
        """
        fatec = await _fatec(sessao)
        curso = await _curso(sessao, fatec, semestres=2)
        matricula = await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso.id)
        aluna = await _aluna(sessao, cpf=CPF_ALUNA, username=f"voltou_{uuid4().hex[:6]}")
        await _envelhecer(sessao, matricula, semestres=2)

        with pytest.raises(AppError) as erro:
            await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        assert erro.value.code == "matricula_vencida"
        assert erro.value.status_code == 409
        assert await vinculos.obter(sessao, aluna.id) is None

    async def test_a_recusa_nao_apaga_nada(self, sessao):
        """A recusa levanta, e a dependência de sessão faz rollback em exceção.

        Apagar a matrícula ali seria perder metade da operação — a outra metade é
        o vínculo, e o rollback desfaria as duas.
        """
        fatec = await _fatec(sessao)
        curso = await _curso(sessao, fatec, semestres=2)
        matricula = await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso.id)
        aluna = await _aluna(sessao, cpf=CPF_ALUNA, username=f"intacta_{uuid4().hex[:6]}")
        await _envelhecer(sessao, matricula, semestres=2)

        with pytest.raises(AppError):
            await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        ainda_la = (
            await sessao.execute(select(Matricula).where(Matricula.id == matricula.id))
        ).scalar_one_or_none()
        assert ainda_la is not None
