from datetime import UTC, datetime, timedelta
from uuid import uuid4

import jwt
import pytest

from integra_shared.errors import AppError
from integra_shared.security import (
    UsuarioAutenticado,
    criar_access_token,
    decodificar_access_token,
)


def _aluno_com_vinculo() -> UsuarioAutenticado:
    return UsuarioAutenticado(
        id=uuid4(),
        tipo="aluno",
        vinculo_universidade_id=uuid4(),
        vinculo_curso_id=uuid4(),
    )


def test_token_faz_round_trip_preservando_o_vinculo(settings):
    original = _aluno_com_vinculo()
    recuperado = decodificar_access_token(criar_access_token(original, settings), settings)

    assert recuperado.id == original.id
    assert recuperado.tipo == "aluno"
    # O vínculo viaja no token justamente para o academic-service resolver
    # visibilidade sem consultar o user-service a cada post.
    assert recuperado.vinculo_universidade_id == original.vinculo_universidade_id
    assert recuperado.vinculo_curso_id == original.vinculo_curso_id
    assert recuperado.tem_vinculo is True


def test_conta_sem_vinculo_sobrevive_ao_round_trip(settings):
    """Vínculo nulo é o estado NORMAL de toda conta recém-criada.

    Não é caso de borda: quem nunca informou o CPF numa instituição não tem
    vínculo, e o token precisa representar isso sem falhar.
    """
    sem_vinculo = UsuarioAutenticado(id=uuid4(), tipo="aluno")
    recuperado = decodificar_access_token(criar_access_token(sem_vinculo, settings), settings)

    assert recuperado.tipo == "aluno"
    assert recuperado.vinculo_universidade_id is None
    assert recuperado.vinculo_curso_id is None
    assert recuperado.tem_vinculo is False


def test_claim_da_v1_nao_e_lido_como_vinculo(settings):
    """Um token da v1 trazia `universidadeId` significando afiliação DECLARADA.

    Ler aquele claim com a semântica nova concederia acesso pelo que o usuário
    digitou sozinho — exatamente o furo que a v2 fechou. O token v1 tem
    assinatura válida, então só a ausência de `tipo`/formato novo o barra: aqui o
    teste prova que ele não vira um vínculo.
    """
    forjado = jwt.encode(
        {
            "sub": str(uuid4()),
            "tipo": "aluno",
            "universidadeId": str(uuid4()),
            "cursoId": str(uuid4()),
        },
        settings.jwt_secret,
        algorithm=settings.jwt_algoritmo,
    )

    recuperado = decodificar_access_token(forjado, settings)
    assert recuperado.tem_vinculo is False, (
        "claim da v1 não deve ser interpretado como vínculo verificado"
    )


def test_tem_vinculo_com_compara_a_universidade_certa(settings):
    usuario = _aluno_com_vinculo()
    assert usuario.tem_vinculo_com(usuario.vinculo_universidade_id) is True
    assert usuario.tem_vinculo_com(uuid4()) is False


def test_token_adulterado_e_recusado(settings):
    token = criar_access_token(_aluno_com_vinculo(), settings)
    cabecalho, payload, assinatura = token.split(".")
    adulterado = f"{cabecalho}.{payload[:-4]}AAAA.{assinatura}"

    with pytest.raises(AppError) as erro:
        decodificar_access_token(adulterado, settings)
    assert erro.value.status_code == 401


def test_token_assinado_com_outro_segredo_e_recusado(settings):
    forjado = jwt.encode(
        {"sub": str(uuid4()), "tipo": "faculdade"},
        "outro-segredo-completamente-diferente",
        algorithm="HS256",
    )
    with pytest.raises(AppError):
        decodificar_access_token(forjado, settings)


def test_token_expirado_e_recusado(settings):
    passado = datetime.now(UTC) - timedelta(hours=1)
    expirado = jwt.encode(
        {"sub": str(uuid4()), "tipo": "aluno", "iat": passado, "exp": passado},
        settings.jwt_secret,
        algorithm=settings.jwt_algoritmo,
    )
    with pytest.raises(AppError):
        decodificar_access_token(expirado, settings)


def test_token_alg_none_e_recusado(settings):
    """Confusão de algoritmo: `alg: none` só passa se aceitarmos o header do token."""
    inseguro = jwt.encode({"sub": str(uuid4()), "tipo": "aluno"}, key="", algorithm="none")

    with pytest.raises(AppError):
        decodificar_access_token(inseguro, settings)


def test_assinatura_valida_com_payload_incompleto_e_recusada(settings):
    """Token de uma versão anterior do serviço não deve virar 500 mais adiante."""
    sem_tipo = jwt.encode(
        {"sub": str(uuid4())},
        settings.jwt_secret,
        algorithm=settings.jwt_algoritmo,
    )
    with pytest.raises(AppError) as erro:
        decodificar_access_token(sem_tipo, settings)
    assert erro.value.code == "nao_autenticado"
