/// CPF e CNPJ: normalização, validação estrutural e formatação.
///
/// Porto Dart de `services/shared/src/integra_shared/cpf.py` e `cnpj.py`. Existe
/// um segundo lugar com a mesma regra porque o cliente precisa recusar o número
/// digitado errado **antes** de gastar uma requisição — mas isso é exatamente o
/// tipo de duplicação que diverge em silêncio, então
/// `test/shared/domain/documentos_test.dart` trava os mesmos casos que os testes
/// Python: os dígitos verificadores, as sequências de um só algarismo, e a
/// tolerância à pontuação.
///
/// O que esta validação faz e o que **não** faz: ela confere os dígitos
/// verificadores, o que recusa número digitado errado. Ela **não** verifica
/// identidade, não consulta a Receita e não diz que a pessoa ou a empresa
/// existe. Um CPF matematicamente válido pode não pertencer a ninguém — é por
/// isso que o vínculo ainda depende da lista de matrículas da instituição, e que
/// a conta institucional nasce pendente.
library;

final RegExp _naoDigito = RegExp(r'\D');

// ────────────────────────────────  CPF  ────────────────────────────────

const int cpfComprimento = 11;

/// Devolve apenas os dígitos. Não valida.
String normalizarCpf(String? cpf) => (cpf ?? '').replaceAll(_naoDigito, '');

bool cpfEValido(String? cpf) {
  final digitos = normalizarCpf(cpf);

  if (digitos.length != cpfComprimento) return false;

  // Sequências de um só dígito (00000000000, 11111111111, ...) passam na conta
  // dos verificadores por coincidência aritmética, e são a entrada de teste que
  // todo mundo digita. Recusar explicitamente é o único jeito.
  if (digitos.split('').every((d) => d == digitos[0])) return false;

  if (_verificadorCpf(digitos, ate: 9) != int.parse(digitos[9])) return false;
  if (_verificadorCpf(digitos, ate: 10) != int.parse(digitos[10])) return false;

  return true;
}

/// Soma ponderada com pesos decrescentes a partir de `ate + 1`, módulo 11.
/// Resto 0 ou 1 resulta em dígito 0 — daí o `% 10` no fim, em vez de um `if`.
int _verificadorCpf(String digitos, {required int ate}) {
  final pesoInicial = ate + 1;
  var soma = 0;
  for (var i = 0; i < ate; i++) {
    soma += int.parse(digitos[i]) * (pesoInicial - i);
  }
  return (soma * 10) % 11 % 10;
}

/// `12345678900` → `123.456.789-00`. Para exibição, nunca para armazenamento.
String formatarCpf(String cpf) {
  final d = normalizarCpf(cpf);
  if (d.length != cpfComprimento) return cpf;
  return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}'
      '-${d.substring(9)}';
}

// ────────────────────────────────  CNPJ  ───────────────────────────────

const int cnpjComprimento = 14;

/// Pesos do primeiro dígito verificador. O segundo usa a mesma sequência com um
/// 6 à frente, porque tem um algarismo a mais para ponderar.
const _pesosCnpj1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
const _pesosCnpj2 = [6, ..._pesosCnpj1];

String normalizarCnpj(String? cnpj) => (cnpj ?? '').replaceAll(_naoDigito, '');

bool cnpjEValido(String? cnpj) {
  final digitos = normalizarCnpj(cnpj);

  if (digitos.length != cnpjComprimento) return false;
  if (digitos.split('').every((d) => d == digitos[0])) return false;

  if (_verificadorCnpj(digitos.substring(0, 12), _pesosCnpj1) !=
      int.parse(digitos[12])) {
    return false;
  }
  if (_verificadorCnpj(digitos.substring(0, 13), _pesosCnpj2) !=
      int.parse(digitos[13])) {
    return false;
  }

  return true;
}

/// Soma ponderada módulo 11. Resto menor que 2 resulta em dígito 0.
int _verificadorCnpj(String digitos, List<int> pesos) {
  var soma = 0;
  for (var i = 0; i < digitos.length; i++) {
    soma += int.parse(digitos[i]) * pesos[i];
  }
  final resto = soma % 11;
  return resto < 2 ? 0 : 11 - resto;
}

/// `12345678000199` → `12.345.678/0001-99`. Exibição, nunca armazenamento.
String formatarCnpj(String cnpj) {
  final d = normalizarCnpj(cnpj);
  if (d.length != cnpjComprimento) return cnpj;
  return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}'
      '/${d.substring(8, 12)}-${d.substring(12)}';
}
