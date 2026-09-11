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


def _aluno() -> UsuarioAutenticado:
    return UsuarioAutenticado(
        id=uuid4(),
        tipo="aluno",
        universidade_id=uuid4(),
        curso_id=uuid4(),
    )


def test_token_faz_round_trip_preservando_a_afiliacao(settings):
    original = _aluno()
    recuperado = decodificar_access_token(criar_access_token(original, settings), settings)

    assert recuperado.id == original.id
    assert recuperado.tipo == "aluno"
    # A afiliação viaja no token justamente para o academic-service resolver
    # visibilidade sem consultar o user-service a cada post.
    assert recuperado.universidade_id == original.universidade_id
    assert recuperado.curso_id == original.curso_id


def test_conta_sem_afiliacao_sobrevive_ao_round_trip(settings):
    empresa = UsuarioAutenticado(id=uuid4(), tipo="empresa")
    recuperado = decodificar_access_token(criar_access_token(empresa, settings), settings)

    assert recuperado.tipo == "empresa"
    assert recuperado.universidade_id is None
    assert recuperado.curso_id is None


def test_token_adulterado_e_recusado(settings):
    token = criar_access_token(_aluno(), settings)
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
