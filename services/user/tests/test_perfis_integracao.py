"""Regras de perfil contra um Postgres de verdade.

Aqui moram as regras que só o banco pode confirmar: a validação do par
universidade/curso, a unicidade de username e a busca com `ILIKE`. Um dublê de
banco confirmaria a minha suposição sobre o Postgres, não o Postgres.
"""

from uuid import uuid4

import pytest
from sqlalchemy import select

from integra_shared.errors import AppError
from user_service.models import Universidade
from user_service.schemas import AtualizarPerfilIn, CriarUsuarioIn
from user_service.services import perfis, seguir


async def _instituicoes(sessao):
    """Seed real: FATEC e USP, cada uma com os cursos dela."""
    unis = (await sessao.execute(select(Universidade).order_by(Universidade.sigla))).scalars().all()
    por_sigla = {u.sigla: u for u in unis}
    if "FATEC RP" not in por_sigla or "USP" not in por_sigla:
        pytest.skip("banco sem seed — rode `python -m user_service.seed` primeiro")

    fatec = por_sigla["FATEC RP"]
    usp = por_sigla["USP"]
    cursos_fatec = await perfis.listar_cursos(sessao, fatec.id)
    cursos_usp = await perfis.listar_cursos(sessao, usp.id)
    return fatec, cursos_fatec[0], usp, cursos_usp[0]


async def _criar(sessao, *, username: str, nome: str, uni, curso):
    return await perfis.criar(
        sessao,
        CriarUsuarioIn(
            id=uuid4(),
            nome_completo=nome,
            email=f"{username}@exemplo.com",
            username=username,
            telefone="(16)99999-0000",
            universidade_id=uni.id,
            curso_id=curso.id,
        ),
    )


class TestCriacaoDePerfil:
    async def test_cria_com_afiliacao_completa(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        usuario = await _criar(
            sessao, username="ana_teste", nome="Ana Paula Souza", uni=fatec, curso=ads
        )

        assert usuario.universidade_id == fatec.id
        assert usuario.curso_id == ads.id
        assert usuario.email == "ana_teste@exemplo.com"

    async def test_curso_de_outra_universidade_e_recusado(self, sessao):
        fatec, _, _, curso_da_usp = await _instituicoes(sessao)

        # As duas chaves estrangeiras são válidas isoladamente, então o banco
        # aceitaria o par. Sem esta checagem o aluno ficaria afiliado a um curso
        # de outra instituição e o filtro do pilar Acadêmico quebraria em
        # silêncio — nada falharia, só o feed viria errado.
        with pytest.raises(AppError) as erro:
            await _criar(
                sessao,
                username="errado",
                nome="Par Invalido",
                uni=fatec,
                curso=curso_da_usp,
            )

        assert erro.value.status_code == 422
        assert erro.value.fields is not None
        assert "cursoId" in erro.value.fields

    async def test_username_duplicado_e_conflito(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _criar(sessao, username="repetido", nome="Primeiro Nome", uni=fatec, curso=ads)

        with pytest.raises(AppError) as erro:
            await perfis.criar(
                sessao,
                CriarUsuarioIn(
                    id=uuid4(),
                    nome_completo="Segundo Nome",
                    email="outro@exemplo.com",
                    username="repetido",
                    telefone="(16)98888-0000",
                    universidade_id=fatec.id,
                    curso_id=ads.id,
                ),
            )

        # 409 e 422 são coisas diferentes para o cliente: "já existe" e "formato
        # inválido" levam a reações distintas na tela.
        assert erro.value.status_code == 409


class TestBusca:
    async def test_casa_no_meio_da_palavra(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        await _criar(
            sessao, username="bruno_lima", nome="Bruno Carvalho Lima", uni=fatec, curso=ads
        )

        # O protótipo usava `isLessThan: '${termo}z'`, que só casava PREFIXO:
        # buscar "carvalho" não achava "Bruno Carvalho Lima". O ILIKE com
        # curinga dos dois lados acha.
        achados = await perfis.buscar(sessao, "carvalho")
        assert any(u.username == "bruno_lima" for u in achados)

    async def test_termo_curto_nao_consulta(self, sessao):
        assert await perfis.buscar(sessao, "a") == []
        assert await perfis.buscar(sessao, "") == []

    async def test_filtra_por_universidade(self, sessao):
        fatec, ads, usp, cc = await _instituicoes(sessao)
        await _criar(sessao, username="xyz_fatec", nome="Pessoa Fatec", uni=fatec, curso=ads)
        await _criar(sessao, username="xyz_usp", nome="Pessoa Usp", uni=usp, curso=cc)

        so_fatec = await perfis.buscar(sessao, "xyz", universidade_id=fatec.id)
        assert [u.username for u in so_fatec] == ["xyz_fatec"]


class TestAtualizacao:
    async def test_campos_omitidos_ficam_inalterados(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        usuario = await _criar(
            sessao, username="para_editar", nome="Nome Original", uni=fatec, curso=ads
        )

        atualizado = await perfis.atualizar(sessao, usuario.id, AtualizarPerfilIn(bio="Nova bio"))

        assert atualizado.bio == "Nova bio"
        assert atualizado.nome_completo == "Nome Original"
        assert atualizado.alterado_em is not None

    async def test_trocar_universidade_e_curso_juntos(self, sessao):
        fatec, ads, usp, cc = await _instituicoes(sessao)
        usuario = await _criar(
            sessao, username="vai_trocar", nome="Vai Trocar", uni=fatec, curso=ads
        )

        atualizado = await perfis.atualizar(
            sessao,
            usuario.id,
            AtualizarPerfilIn(universidade_id=usp.id, curso_id=cc.id),
        )

        assert atualizado.universidade_id == usp.id
        assert atualizado.curso_id == cc.id

    async def test_trocar_so_o_curso_para_um_de_outra_universidade_falha(self, sessao):
        fatec, ads, _, curso_da_usp = await _instituicoes(sessao)
        usuario = await _criar(
            sessao, username="curso_solto", nome="Curso Solto", uni=fatec, curso=ads
        )

        with pytest.raises(AppError) as erro:
            await perfis.atualizar(sessao, usuario.id, AtualizarPerfilIn(curso_id=curso_da_usp.id))
        assert erro.value.status_code == 422


class TestSeguir:
    async def test_a_propria_universidade_sempre_consta(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        usuario = await _criar(sessao, username="seguidor", nome="Segue Tudo", uni=fatec, curso=ads)

        seguidas = await seguir.listar_universidades(sessao, usuario.id)

        # Mesmo sem nunca ter seguido: o vínculo não é opcional, e deixá-lo fora
        # faria o escopo "geral" do feed excluir a instituição do próprio aluno.
        assert [u.sigla for u in seguidas] == ["FATEC RP"]
        assert seguidas[0].propria is True

    async def test_seguir_e_idempotente(self, sessao):
        fatec, ads, usp, _ = await _instituicoes(sessao)
        usuario = await _criar(sessao, username="idem", nome="Idem Potente", uni=fatec, curso=ads)

        await seguir.seguir_universidade(sessao, usuario.id, usp.id)
        await seguir.seguir_universidade(sessao, usuario.id, usp.id)

        seguidas = await seguir.listar_universidades(sessao, usuario.id)
        assert sorted(u.sigla for u in seguidas) == ["FATEC RP", "USP"]

    async def test_nao_deixa_de_seguir_a_propria(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        usuario = await _criar(sessao, username="teimoso", nome="Nao Sai", uni=fatec, curso=ads)

        with pytest.raises(AppError) as erro:
            await seguir.deixar_de_seguir_universidade(sessao, usuario.id, fatec.id)

        assert erro.value.status_code == 409
        assert erro.value.code == "universidade_propria"

    async def test_nao_segue_a_si_mesmo(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        usuario = await _criar(sessao, username="narciso", nome="Nao Da", uni=fatec, curso=ads)

        with pytest.raises(AppError) as erro:
            await seguir.seguir_usuario(sessao, usuario.id, usuario.id)
        assert erro.value.status_code == 409

    async def test_segue_e_deixa_de_seguir_usuario(self, sessao):
        fatec, ads, _, _ = await _instituicoes(sessao)
        a = await _criar(sessao, username="segue_a", nome="Pessoa A", uni=fatec, curso=ads)
        b = await _criar(sessao, username="segue_b", nome="Pessoa B", uni=fatec, curso=ads)

        await seguir.seguir_usuario(sessao, a.id, b.id)
        assert [u.username for u in await seguir.listar_usuarios(sessao, a.id)] == ["segue_b"]

        await seguir.deixar_de_seguir_usuario(sessao, a.id, b.id)
        assert await seguir.listar_usuarios(sessao, a.id) == []
