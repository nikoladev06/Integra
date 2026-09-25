"""O modelo de vínculo, contra um Postgres de verdade.

Aqui moram as regras que definem a v2, e que só o banco pode confirmar: a
separação entre formação e vínculo, a unicidade estrutural do vínculo, e as duas
conferências do CPF.

Os CPFs são **gerados** pelo próprio validador, nunca escritos à mão: um CPF de
cabeça quase sempre tem dígito verificador errado, e um teste que "aceita" um
desses estaria exercitando o caminho de erro achando que exercita o de sucesso.
"""

from uuid import uuid4

import pytest
from sqlalchemy import select

from integra_shared.cpf import formatar, gerar_valido
from integra_shared.errors import AppError
from user_service.models import Curso, TipoConta, Universidade, Vinculo
from user_service.schemas import CriarUsuarioIn
from user_service.services import formacoes, instituicoes, perfis, seguir, vinculos

# Sementes fixas: o mesmo CPF em toda execução, então um teste que falha é
# reproduzível. Faixas distantes para nenhum par colidir por acidente.
CPF_ALUNA = gerar_valido(770_001)
CPF_OUTRO = gerar_valido(880_002)
CPF_SEM_CONTA = gerar_valido(990_003)


async def _instituicoes(sessao):
    unis = (
        (await sessao.execute(select(Universidade).order_by(Universidade.sigla)))
        .unique()
        .scalars()
        .all()
    )
    por_sigla = {u.sigla: u for u in unis}
    if "FATEC RP" not in por_sigla or "USP" not in por_sigla:
        pytest.skip("banco sem seed — rode `python -m user_service.seed` primeiro")

    fatec, usp = por_sigla["FATEC RP"], por_sigla["USP"]
    return (
        fatec,
        (await perfis.listar_cursos(sessao, fatec.id))[0],
        usp,
        (await perfis.listar_cursos(sessao, usp.id))[0],
    )


async def _aluno(sessao, *, username: str, cpf: str, formacao=None):
    uni, curso = formacao if formacao else (None, None)
    return await perfis.criar(
        sessao,
        CriarUsuarioIn(
            id=uuid4(),
            nome_completo=f"Pessoa {username}",
            email=f"{username}@exemplo.com",
            username=username,
            cpf=cpf,
            telefone="(16)99999-0000",
            universidade_id=uni.id if uni else None,
            curso_id=curso.id if curso else None,
        ),
    )


async def _conta_da_faculdade(sessao, universidade):
    """Conta institucional ligada à universidade, como `promover` faz."""
    conta = await perfis.criar(
        sessao,
        CriarUsuarioIn(
            id=uuid4(),
            nome_completo=f"Secretaria {universidade.sigla}",
            email=f"sec-{universidade.sigla.replace(' ', '')}@exemplo.com".lower(),
            username=f"sec_{universidade.sigla.replace(' ', '').lower()}",
            cpf=gerar_valido(hash(universidade.sigla) % 900_000_000),
            tipo=TipoConta.FACULDADE,
        ),
    )
    conta.cpf = None
    universidade.conta_id = conta.id
    await sessao.flush()
    return conta


class TestCadastro:
    async def test_conta_nasce_sem_formacao_e_sem_vinculo(self, sessao):
        """O estado inicial de toda conta, e o que o feed vê nele: nada além de público."""
        aluna = await _aluno(sessao, username="sem_nada", cpf=CPF_ALUNA)

        assert aluna.formacoes == []
        assert aluna.vinculo is None

    async def test_formacao_informada_no_cadastro_nasce_SEM_selo(self, sessao):
        """Declarar não verifica. É o ponto central da mudança da v2.

        Na v1 este mesmo dado concedia acesso aos posts internos da instituição —
        bastava digitar o nome dela.
        """
        fatec, ads, _, _ = await _instituicoes(sessao)
        aluna = await _aluno(sessao, username="declarou", cpf=CPF_ALUNA, formacao=(fatec, ads))

        assert len(aluna.formacoes) == 1
        assert aluna.formacoes[0].verificada_em is None
        assert aluna.formacoes[0].verificada is False
        # E, crucialmente, nenhum vínculo:
        assert aluna.vinculo is None

    async def test_cpf_duplicado_e_conflito(self, sessao):
        await _aluno(sessao, username="primeiro_cpf", cpf=CPF_ALUNA)

        with pytest.raises(AppError) as erro:
            await _aluno(sessao, username="segundo_cpf", cpf=CPF_ALUNA)

        assert erro.value.status_code == 409
        assert erro.value.code == "cpf_ja_cadastrado"


class TestVinculoPeloCpf:
    async def test_cpf_de_outra_pessoa_e_recusado(self, sessao):
        """A conferência que impede escalada de privilégio.

        O CPF não é segredo no Brasil. Se bastasse constar na lista da faculdade,
        quem soubesse o CPF de um aluno leria os comunicados internos dela.
        """
        fatec, ads, _, _ = await _instituicoes(sessao)
        conta = await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_OUTRO, ads.id)

        # CPF_OUTRO está na lista, mas não é o CPF desta conta.
        atacante = await _aluno(sessao, username="atacante", cpf=CPF_ALUNA)

        with pytest.raises(AppError) as erro:
            await vinculos.criar(sessao, atacante.id, fatec.id, CPF_OUTRO)

        assert erro.value.status_code == 403
        assert erro.value.code == "vinculo_recusado"
        assert await vinculos.obter(sessao, atacante.id) is None
        assert conta is not None

    async def test_cpf_da_conta_fora_da_lista_e_recusado(self, sessao):
        fatec, _, _, _ = await _instituicoes(sessao)
        aluna = await _aluno(sessao, username="nao_matriculada", cpf=CPF_ALUNA)

        with pytest.raises(AppError) as erro:
            await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        assert erro.value.status_code == 404
        assert erro.value.code == "vinculo_recusado"

    async def test_as_duas_recusas_dao_a_MESMA_mensagem(self, sessao):
        """Mensagens diferentes fariam da rota uma sonda da lista da instituição."""
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_OUTRO, ads.id)
        aluna = await _aluno(sessao, username="mensagens", cpf=CPF_ALUNA)

        por_cpf_alheio = await _capturar(vinculos.criar(sessao, aluna.id, fatec.id, CPF_OUTRO))
        por_fora_da_lista = await _capturar(vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA))

        assert por_cpf_alheio.message == por_fora_da_lista.message
        # Os status diferem de propósito: só o CPF da própria conta chega ao
        # segundo passo, então o 404 revela apenas informação sobre si mesmo.
        assert {por_cpf_alheio.status_code, por_fora_da_lista.status_code} == {403, 404}

    async def test_cpf_pontuado_e_aceito(self, sessao):
        """A tela manda com máscara; o banco guarda dígitos."""
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, formatar(CPF_ALUNA), ads.id)
        aluna = await _aluno(sessao, username="pontuado", cpf=CPF_ALUNA)

        vinculo = await vinculos.criar(sessao, aluna.id, fatec.id, formatar(CPF_ALUNA))
        assert vinculo.universidade_id == fatec.id

    async def test_vinculo_cria_formacao_verificada_quando_nao_declarada(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        aluna = await _aluno(sessao, username="sem_declarar", cpf=CPF_ALUNA)

        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        minhas = await formacoes.listar(sessao, aluna.id)
        assert len(minhas) == 1
        assert minhas[0].verificada is True
        assert minhas[0].universidade_id == fatec.id

    async def test_vinculo_estampa_selo_na_formacao_ja_declarada(self, sessao):
        """Não cria linha nova: a formação declarada ganha o selo."""
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        aluna = await _aluno(
            sessao, username="declarou_certo", cpf=CPF_ALUNA, formacao=(fatec, ads)
        )

        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        minhas = await formacoes.listar(sessao, aluna.id)
        assert len(minhas) == 1, "estampar o selo não deve duplicar a formação"
        assert minhas[0].verificada is True


class TestTrocaDeFaculdade:
    async def test_segundo_vinculo_substitui_o_primeiro_e_MANTEM_os_dois_selos(self, sessao):
        """A regra que o produto definiu: um vínculo por vez, dois selos.

        Este teste é o que separa a implementação certa da tentadora — apagar a
        formação antiga junto com o vínculo antigo passaria em qualquer teste que
        só olhasse o vínculo.
        """
        fatec, ads, usp, cc = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await _conta_da_faculdade(sessao, usp)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        await instituicoes.criar_matricula(sessao, usp.id, CPF_ALUNA, cc.id)
        aluna = await _aluno(sessao, username="transferida", cpf=CPF_ALUNA)

        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)
        await vinculos.criar(sessao, aluna.id, usp.id, CPF_ALUNA)

        vinculo = await vinculos.obter(sessao, aluna.id)
        assert vinculo is not None
        assert vinculo.universidade_id == usp.id, "o vínculo deve ter migrado"

        verificadas = {
            f.universidade.sigla for f in await formacoes.listar(sessao, aluna.id) if f.verificada
        }
        assert verificadas == {"FATEC RP", "USP"}, (
            "as duas formações continuam verificadas: ela estudou nas duas"
        )

    async def test_so_existe_uma_linha_de_vinculo_por_usuario(self, sessao):
        """A unicidade é estrutural — `usuario_id` é a chave primária."""
        fatec, ads, usp, cc = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await _conta_da_faculdade(sessao, usp)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        await instituicoes.criar_matricula(sessao, usp.id, CPF_ALUNA, cc.id)
        aluna = await _aluno(sessao, username="uma_linha", cpf=CPF_ALUNA)

        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)
        await vinculos.criar(sessao, aluna.id, usp.id, CPF_ALUNA)

        total = len(
            (await sessao.execute(select(Vinculo).where(Vinculo.usuario_id == aluna.id)))
            .scalars()
            .all()
        )
        assert total == 1


class TestFimDoVinculo:
    async def test_aluno_encerra_e_o_selo_permanece(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        aluna = await _aluno(sessao, username="saiu_sozinha", cpf=CPF_ALUNA)
        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        await vinculos.encerrar(sessao, aluna.id)

        assert await vinculos.obter(sessao, aluna.id) is None
        assert all(f.verificada for f in await formacoes.listar(sessao, aluna.id))

    async def test_encerrar_e_idempotente(self, sessao):
        aluna = await _aluno(sessao, username="sem_vinculo_sai", cpf=CPF_ALUNA)
        await vinculos.encerrar(sessao, aluna.id)
        await vinculos.encerrar(sessao, aluna.id)

    async def test_faculdade_remove_matricula_corta_acesso_e_mantem_selo(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        matricula = await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        aluna = await _aluno(sessao, username="removida", cpf=CPF_ALUNA)
        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        await instituicoes.remover_matricula(sessao, fatec.id, matricula.id)

        assert await vinculos.obter(sessao, aluna.id) is None
        selos = [
            f.universidade.sigla for f in await formacoes.listar(sessao, aluna.id) if f.verificada
        ]
        assert selos == ["FATEC RP"]

    async def test_remover_matricula_antiga_nao_derruba_vinculo_novo(self, sessao):
        """O caso que uma implementação ingênua quebra.

        A aluna migrou para a USP. A FATEC, arrumando a casa, remove a matrícula
        antiga. Isso **não** pode encerrar o vínculo com a USP — e só um `DELETE`
        que filtra por universidade evita isso.
        """
        fatec, ads, usp, cc = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await _conta_da_faculdade(sessao, usp)
        m_fatec = await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        await instituicoes.criar_matricula(sessao, usp.id, CPF_ALUNA, cc.id)
        aluna = await _aluno(sessao, username="migrou", cpf=CPF_ALUNA)

        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)
        await vinculos.criar(sessao, aluna.id, usp.id, CPF_ALUNA)
        await instituicoes.remover_matricula(sessao, fatec.id, m_fatec.id)

        vinculo = await vinculos.obter(sessao, aluna.id)
        assert vinculo is not None, "o vínculo com a USP não devia cair"
        assert vinculo.universidade_id == usp.id


class TestFormacaoDeclarada:
    async def test_declarada_pode_ser_removida(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        aluna = await _aluno(sessao, username="apaga_declarada", cpf=CPF_ALUNA)
        formacao = await formacoes.declarar(sessao, aluna.id, fatec.id, ads.id)

        await formacoes.remover(sessao, aluna.id, formacao.id)
        assert await formacoes.listar(sessao, aluna.id) == []

    async def test_verificada_NAO_pode_ser_removida(self, sessao):
        """O selo é afirmação da instituição, não do usuário."""
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        aluna = await _aluno(sessao, username="apaga_selo", cpf=CPF_ALUNA)
        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        formacao = (await formacoes.listar(sessao, aluna.id))[0]
        with pytest.raises(AppError) as erro:
            await formacoes.remover(sessao, aluna.id, formacao.id)

        assert erro.value.status_code == 409
        assert erro.value.code == "formacao_verificada"

    async def test_declarar_a_mesma_duas_vezes_e_conflito(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        aluna = await _aluno(sessao, username="declara_2x", cpf=CPF_ALUNA)
        await formacoes.declarar(sessao, aluna.id, fatec.id, ads.id)

        with pytest.raises(AppError) as erro:
            await formacoes.declarar(sessao, aluna.id, fatec.id, ads.id)
        assert erro.value.status_code == 409

    async def test_curso_de_outra_universidade_e_recusado(self, sessao):
        """As duas chaves estrangeiras são válidas isoladamente."""
        fatec, _, _, curso_da_usp = await _instituicoes(sessao)
        aluna = await _aluno(sessao, username="par_errado", cpf=CPF_ALUNA)

        with pytest.raises(AppError) as erro:
            await formacoes.declarar(sessao, aluna.id, fatec.id, curso_da_usp.id)
        assert erro.value.status_code == 422
        assert erro.value.fields is not None
        assert "cursoId" in erro.value.fields


class TestMatriculas:
    async def test_pode_cadastrar_antes_de_a_conta_existir(self, sessao):
        """A lista de espera: sem isso a secretaria só cadastraria quem já baixou o app."""
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)

        await instituicoes.criar_matricula(sessao, fatec.id, CPF_SEM_CONTA, ads.id)

        linhas = await instituicoes.listar_matriculas(sessao, fatec.id)
        pendente = [(m, u) for m, u in linhas if m.cpf == CPF_SEM_CONTA]
        assert len(pendente) == 1
        assert pendente[0][1] is None, "sem conta ainda, então sem dono"

    async def test_cpf_invalido_e_recusado_na_matricula(self, sessao):
        """Validado aqui também, não só no cadastro do aluno.

        Um CPF impossível na lista nunca casaria com conta alguma, e o erro
        apareceria meses depois como "o vínculo não funciona".
        """
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)

        with pytest.raises(AppError) as erro:
            await instituicoes.criar_matricula(sessao, fatec.id, "11111111111", ads.id)
        assert erro.value.status_code == 422
        assert erro.value.fields is not None
        assert erro.value.fields["cpf"] == ["CPF inválido"]

    async def test_mesmo_cpf_duas_vezes_na_mesma_instituicao_e_conflito(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)

        with pytest.raises(AppError) as erro:
            await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        assert erro.value.status_code == 409

    async def test_curso_de_outra_instituicao_e_recusado(self, sessao):
        fatec, _, _, curso_da_usp = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)

        with pytest.raises(AppError) as erro:
            await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso_da_usp.id)
        assert erro.value.status_code == 422

    async def test_curso_em_uso_nao_pode_ser_removido(self, sessao):
        fatec, _, _, _ = await _instituicoes(sessao)
        conta = await _conta_da_faculdade(sessao, fatec)
        curso = await instituicoes.criar_curso(sessao, fatec.id, "Curso Temporario")
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, curso.id)

        with pytest.raises(AppError) as erro:
            await instituicoes.remover_curso(sessao, fatec.id, curso.id)
        assert erro.value.status_code == 409
        assert conta is not None

    async def test_curso_sem_uso_pode_ser_removido(self, sessao):
        """O controle da mutação acima: sem este teste, um guarda que recusasse
        SEMPRE a remoção passaria igual."""
        fatec, _, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        curso = await instituicoes.criar_curso(sessao, fatec.id, "Curso Sem Uso")

        await instituicoes.remover_curso(sessao, fatec.id, curso.id)

        # `select` e não `sessao.get`: o `get` responde do cache de identidade da
        # sessão e devolveria o objeto mesmo depois de apagado.
        restou = (
            await sessao.execute(select(Curso).where(Curso.id == curso.id))
        ).scalar_one_or_none()
        assert restou is None


class TestSeguir:
    async def test_lista_vazia_para_conta_sem_vinculo(self, sessao):
        """O estado normal de quem acabou de se cadastrar, não um erro."""
        aluna = await _aluno(sessao, username="nao_segue", cpf=CPF_ALUNA)
        assert await seguir.listar_universidades(sessao, aluna.id) == []

    async def test_universidade_do_vinculo_aparece_como_propria(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        aluna = await _aluno(sessao, username="com_vinculo", cpf=CPF_ALUNA)
        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        seguidas = await seguir.listar_universidades(sessao, aluna.id)
        assert [(u.sigla, u.propria) for u in seguidas] == [("FATEC RP", True)]

    async def test_nao_deixa_de_seguir_a_universidade_do_vinculo(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _conta_da_faculdade(sessao, fatec)
        await instituicoes.criar_matricula(sessao, fatec.id, CPF_ALUNA, ads.id)
        aluna = await _aluno(sessao, username="teimosa", cpf=CPF_ALUNA)
        await vinculos.criar(sessao, aluna.id, fatec.id, CPF_ALUNA)

        with pytest.raises(AppError) as erro:
            await seguir.deixar_de_seguir_universidade(sessao, aluna.id, fatec.id)
        assert erro.value.code == "universidade_do_vinculo"

    async def test_deixa_de_seguir_uma_sem_vinculo(self, sessao):
        """O controle: o 409 acima não pode virar "nunca deixa de seguir nada"."""
        _, _, usp, _ = await _instituicoes(sessao)
        aluna = await _aluno(sessao, username="segue_usp", cpf=CPF_ALUNA)
        await seguir.seguir_universidade(sessao, aluna.id, usp.id)
        assert len(await seguir.listar_universidades(sessao, aluna.id)) == 1

        await seguir.deixar_de_seguir_universidade(sessao, aluna.id, usp.id)
        assert await seguir.listar_universidades(sessao, aluna.id) == []


async def _capturar(corrotina) -> AppError:
    """Roda a corrotina e devolve o AppError que ela levanta."""
    try:
        await corrotina
    except AppError as erro:
        return erro
    raise AssertionError("esperava AppError e nada foi levantado")
