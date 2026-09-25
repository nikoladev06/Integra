import 'package:flutter_test/flutter_test.dart';

import 'package:integra/shared/domain/documentos.dart';

/// Os mesmos casos de `services/shared/tests/test_cpf.py` e `test_cnpj.py`.
///
/// Existe porque a regra está escrita duas vezes — uma em Python, para os
/// serviços, outra em Dart, para o cliente recusar antes de gastar requisição —
/// e duplicação de regra diverge em silêncio. A divergência apareceria como um
/// CPF que o app aceita e o servidor recusa, ou pior: um que o app recusa e que
/// existia numa lista de matrículas, deixando um aluno sem conseguir se vincular
/// sem nenhuma mensagem que explicasse por quê.
void main() {
  group('CPF', () {
    test('aceita número válido, com e sem pontuação', () {
      expect(cpfEValido('39046350851'), isTrue);
      expect(cpfEValido('390.463.508-51'), isTrue);
      expect(cpfEValido(' 390 463 508 51 '), isTrue);
    });

    test('recusa dígito verificador errado', () {
      expect(cpfEValido('39046350852'), isFalse);
      expect(cpfEValido('39046350841'), isFalse);
    });

    test('recusa comprimento errado, vazio e nulo', () {
      expect(cpfEValido('3904635085'), isFalse);
      expect(cpfEValido('390463508510'), isFalse);
      expect(cpfEValido(''), isFalse);
      expect(cpfEValido(null), isFalse);
    });

    test('recusa sequências de um só dígito', () {
      // Passam na conta dos verificadores por coincidência aritmética, e são a
      // entrada de teste que todo mundo digita. Recusar explicitamente é o
      // único jeito.
      for (var d = 0; d <= 9; d++) {
        expect(cpfEValido('$d' * 11), isFalse, reason: 'esperava recusar $d×11');
      }
    });

    test('normaliza para dígitos', () {
      expect(normalizarCpf('390.463.508-51'), '39046350851');
      expect(normalizarCpf(null), '');
    });

    test('formata para exibição', () {
      expect(formatarCpf('39046350851'), '390.463.508-51');
      // Entrada que não dá para formatar volta como veio, em vez de virar uma
      // máscara mentirosa com o número errado dentro.
      expect(formatarCpf('123'), '123');
    });
  });

  group('CNPJ', () {
    test('aceita número válido, com e sem pontuação', () {
      expect(cnpjEValido('46395000000139'), isTrue);
      expect(cnpjEValido('46.395.000/0001-39'), isTrue);
    });

    test('recusa dígito verificador errado', () {
      expect(cnpjEValido('46395000000138'), isFalse);
      expect(cnpjEValido('46395000000129'), isFalse);
    });

    test('recusa comprimento errado, vazio e nulo', () {
      expect(cnpjEValido('4639500000013'), isFalse);
      expect(cnpjEValido(''), isFalse);
      expect(cnpjEValido(null), isFalse);
    });

    test('recusa sequências de um só dígito', () {
      for (var d = 0; d <= 9; d++) {
        expect(cnpjEValido('$d' * 14), isFalse, reason: 'esperava recusar $d×14');
      }
    });

    test('formata para exibição', () {
      expect(formatarCnpj('46395000000139'), '46.395.000/0001-39');
      expect(formatarCnpj('123'), '123');
    });
  });
}
