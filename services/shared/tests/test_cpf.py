"""Validação de CPF.

Os CPFs usados aqui são **gerados**, não inventados à mão: um CPF escrito de
cabeça quase sempre tem dígito verificador errado, e um teste que "aceita" um
desses estaria testando o caminho de erro achando que testa o de sucesso.
"""

import pytest
from hypothesis import given
from hypothesis import strategies as st

from integra_shared import cpf as cpf_mod
from integra_shared.cpf import CpfInvalido, e_valido, formatar, gerar_valido, normalizar, validar


class TestNormalizacao:
    @pytest.mark.parametrize(
        "entrada",
        [
            "123.456.789-09",
            "12345678909",
            "123 456 789 09",
            "  123.456.789-09  ",
            "123/456/789/09",
        ],
    )
    def test_qualquer_pontuacao_cai_nos_mesmos_digitos(self, entrada):
        assert normalizar(entrada) == "12345678909"

    def test_entrada_vazia_nao_estoura(self):
        assert normalizar("") == ""
        assert normalizar(None) == ""  # type: ignore[arg-type]


class TestValidacao:
    def test_aceita_cpf_com_digitos_corretos(self):
        # Gerado, então os verificadores estão certos por construção.
        valido = gerar_valido(123456789)
        assert validar(valido) == valido
        assert validar(formatar(valido)) == valido

    @pytest.mark.parametrize("quantidade", [0, 1, 10, 12, 20])
    def test_recusa_comprimento_diferente_de_11(self, quantidade):
        with pytest.raises(CpfInvalido, match="CPF inválido"):
            validar("1" * quantidade)

    @pytest.mark.parametrize("digito", list("0123456789"))
    def test_recusa_sequencia_de_um_so_digito(self, digito):
        """000..., 111... passam na conta dos verificadores por coincidência.

        São a entrada que todo mundo digita para testar, e sem a checagem
        explícita entrariam no banco como CPF legítimo.
        """
        repetido = digito * 11
        assert not e_valido(repetido)

    def test_primeiro_digito_verificador_errado_e_recusado(self):
        valido = gerar_valido(987654321)
        # Altera só o 10º dígito, mantendo o 11º.
        errado_no_primeiro = valido[:9] + str((int(valido[9]) + 1) % 10) + valido[10]
        assert errado_no_primeiro != valido
        assert not e_valido(errado_no_primeiro)

    def test_segundo_digito_verificador_errado_e_recusado(self):
        """Este é o teste que a maioria das suítes não tem.

        Uma implementação que calcula só o primeiro verificador passa em tudo
        acima. Mutar a checagem do segundo dígito deixa a suíte verde sem este
        caso — foi por isso que ele existe separado do anterior.
        """
        valido = gerar_valido(987654321)
        errado_no_segundo = valido[:10] + str((int(valido[10]) + 1) % 10)
        assert errado_no_segundo != valido
        assert not e_valido(errado_no_segundo)

    def test_transposicao_de_digitos_e_recusada(self):
        """Trocar dois dígitos de lugar é o erro de digitação mais comum."""
        valido = gerar_valido(246813579)
        if valido[0] == valido[1]:
            pytest.skip("semente gerou dígitos iniciais iguais; transposição não muda nada")
        trocado = valido[1] + valido[0] + valido[2:]
        assert not e_valido(trocado)


class TestPropriedades:
    @given(st.integers(min_value=0, max_value=999_999_999))
    def test_tudo_que_geramos_e_aceito(self, semente):
        gerado = gerar_valido(semente)
        assert len(gerado) == 11
        assert e_valido(gerado), f"gerador produziu CPF que o validador recusa: {gerado}"

    @given(st.integers(min_value=0, max_value=999_999_999))
    def test_normalizar_e_idempotente(self, semente):
        gerado = gerar_valido(semente)
        assert normalizar(normalizar(gerado)) == normalizar(gerado)

    @given(st.integers(min_value=0, max_value=999_999_999))
    def test_formatar_e_reversivel(self, semente):
        gerado = gerar_valido(semente)
        assert normalizar(formatar(gerado)) == gerado

    @given(st.text(alphabet="0123456789", min_size=11, max_size=11))
    def test_aceito_implica_verificadores_corretos(self, candidato):
        """A propriedade que define a função, em vez de casos escolhidos a dedo.

        Para qualquer sequência de 11 dígitos: se `validar` aceita, então os dois
        verificadores conferem. Isso pega uma implementação que aceite algo por
        um caminho que os casos de exemplo não cobrem.
        """
        if not e_valido(candidato):
            return

        esperado_1 = cpf_mod._digito_verificador(candidato, ate=9)
        esperado_2 = cpf_mod._digito_verificador(candidato, ate=10)
        assert int(candidato[9]) == esperado_1
        assert int(candidato[10]) == esperado_2
        assert candidato != candidato[0] * 11


class TestGerador:
    def test_e_deterministico(self):
        """Mesma semente, mesmo CPF — para um teste que falha ser reproduzível."""
        assert gerar_valido(42) == gerar_valido(42)

    def test_sementes_diferentes_dao_cpfs_diferentes(self):
        assert gerar_valido(1) != gerar_valido(2)

    def test_evita_gerar_sequencia_repetida(self):
        """A semente 0 produziria 000000000 como base, que é recusada.

        O gerador desvia para a semente seguinte. Sem isso ele produziria um CPF
        que o próprio validador recusa, e todo teste que usasse `gerar_valido(0)`
        falharia por um motivo que não tem nada a ver com o que ele testa.
        """
        assert e_valido(gerar_valido(0))
