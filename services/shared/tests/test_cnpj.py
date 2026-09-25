"""Validação de CNPJ.

Mesmo tratamento do CPF: os números são **gerados**, nunca escritos à mão. Um
CNPJ de cabeça quase sempre tem dígito verificador errado, e um teste que o
"aceita" estaria exercitando o caminho de erro achando que exercita o de sucesso.
"""

import pytest
from hypothesis import given
from hypothesis import strategies as st

from integra_shared import cnpj as cnpj_mod
from integra_shared.cnpj import (
    CnpjInvalido,
    e_valido,
    formatar,
    gerar_valido,
    normalizar,
    validar,
)


class TestNormalizacao:
    @pytest.mark.parametrize(
        "entrada",
        [
            "12.345.678/0001-95",
            "12345678000195",
            "12 345 678 0001 95",
            "  12.345.678/0001-95  ",
        ],
    )
    def test_qualquer_pontuacao_cai_nos_mesmos_digitos(self, entrada):
        assert normalizar(entrada) == "12345678000195"

    def test_entrada_vazia_nao_estoura(self):
        assert normalizar("") == ""
        assert normalizar(None) == ""  # type: ignore[arg-type]


class TestValidacao:
    def test_aceita_cnpj_com_digitos_corretos(self):
        valido = gerar_valido(12_345_678)
        assert validar(valido) == valido
        assert validar(formatar(valido)) == valido

    @pytest.mark.parametrize("quantidade", [0, 1, 13, 15, 20])
    def test_recusa_comprimento_diferente_de_14(self, quantidade):
        with pytest.raises(CnpjInvalido, match="CNPJ inválido"):
            validar("1" * quantidade)

    @pytest.mark.parametrize("digito", list("0123456789"))
    def test_recusa_sequencia_de_um_so_digito(self, digito):
        assert not e_valido(digito * 14)

    def test_primeiro_digito_verificador_errado_e_recusado(self):
        valido = gerar_valido(98_765_432)
        errado = valido[:12] + str((int(valido[12]) + 1) % 10) + valido[13]
        assert errado != valido
        assert not e_valido(errado)

    def test_segundo_digito_verificador_errado_e_recusado(self):
        """Separado do primeiro de propósito.

        Uma implementação que calcule só o primeiro verificador passa em todos os
        casos acima. Mutar a checagem do segundo dígito deixaria a suíte verde
        sem este teste.
        """
        valido = gerar_valido(98_765_432)
        errado = valido[:13] + str((int(valido[13]) + 1) % 10)
        assert errado != valido
        assert not e_valido(errado)

    def test_transposicao_de_digitos_e_recusada(self):
        valido = gerar_valido(24_681_357)
        if valido[0] == valido[1]:
            pytest.skip("semente gerou dígitos iniciais iguais")
        trocado = valido[1] + valido[0] + valido[2:]
        assert not e_valido(trocado)

    def test_resto_menor_que_dois_produz_digito_zero(self):
        """O ramo `if resto < 2` do cálculo.

        Sem um caso que o exercite, trocar `< 2` por `< 1` ou remover o ramo
        passaria na suíte. A busca acha uma semente que cai nele.
        """
        com_zero = [gerar_valido(s) for s in range(1, 3000) if gerar_valido(s)[12] == "0"]
        assert com_zero, "nenhuma semente produziu primeiro verificador 0"
        assert all(e_valido(c) for c in com_zero[:20])


class TestPropriedades:
    @given(st.integers(min_value=0, max_value=99_999_999))
    def test_tudo_que_geramos_e_aceito(self, semente):
        gerado = gerar_valido(semente)
        assert len(gerado) == 14
        assert e_valido(gerado), f"gerador produziu CNPJ que o validador recusa: {gerado}"

    @given(st.integers(min_value=0, max_value=99_999_999))
    def test_formatar_e_reversivel(self, semente):
        gerado = gerar_valido(semente)
        assert normalizar(formatar(gerado)) == gerado

    @given(st.text(alphabet="0123456789", min_size=14, max_size=14))
    def test_aceito_implica_verificadores_corretos(self, candidato):
        """A propriedade que define a função, em vez de casos a dedo."""
        if not e_valido(candidato):
            return

        assert int(candidato[12]) == cnpj_mod._digito_verificador(candidato[:12], cnpj_mod._PESOS_1)
        assert int(candidato[13]) == cnpj_mod._digito_verificador(candidato[:13], cnpj_mod._PESOS_2)
        assert candidato != candidato[0] * 14


class TestGerador:
    def test_e_deterministico(self):
        assert gerar_valido(42) == gerar_valido(42)

    def test_sementes_diferentes_dao_cnpjs_diferentes(self):
        assert gerar_valido(1) != gerar_valido(2)

    def test_semente_zero_nao_gera_sequencia_repetida(self):
        assert e_valido(gerar_valido(0))

    def test_filial_e_a_matriz(self):
        assert gerar_valido(777)[8:12] == "0001"
