/// Regras de validação de credenciais e de cadastro.
///
/// Extraídas do protótipo — `controller/cadastrar_controller.dart` e
/// `controller/login_controller.dart`, preservados em `reference/legacy_app/`.
/// São a única lógica de negócio que atravessou a reconstrução, e valem como
/// especificação: o schema Pydantic do `auth-service` deve reproduzir estas
/// mesmas regras com estas mesmas mensagens.
///
/// Cada função retorna `null` quando o valor é válido, ou a mensagem de erro em
/// português — a assinatura que `TextFormField.validator` espera.
library;

/// Comprimento mínimo de senha aceito no cadastro e na troca de senha.
const int senhaComprimentoMinimo = 6;

/// O protótipo tinha duas expressões diferentes para e-mail: uma permissiva em
/// `cadastrar_controller` e esta, mais estrita, em `login_controller`. Um
/// e-mail aceito no cadastro e recusado no login é um usuário sem acesso, então
/// a estrita passa a valer nos dois fluxos.
final RegExp _formatoEmail = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

final RegExp _formatoUsername = RegExp(r'^[a-zA-Z0-9_]+$');

/// Aceita `(16)99999-9999`, `16 99999-9999`, `16999999999` e variações com
/// oito dígitos no número.
final RegExp _formatoTelefone = RegExp(r'^\(?\d{2}\)?[\s-]?\d{4,5}-?\d{4}$');

String? validarEmail(String? email) {
  final valor = email?.trim() ?? '';
  if (valor.isEmpty) {
    return 'E-mail não pode ficar em branco';
  }
  if (!_formatoEmail.hasMatch(valor)) {
    return 'Insira um e-mail válido (ex: usuario@exemplo.com)';
  }
  return null;
}

String? validarSenha(String? senha) {
  final valor = senha ?? '';
  if (valor.isEmpty) {
    return 'Senha não pode ficar em branco';
  }
  if (valor.length < senhaComprimentoMinimo) {
    return 'Senha deve ter no mínimo $senhaComprimentoMinimo caracteres';
  }
  return null;
}

String? validarConfirmacaoSenha(String? senha, String? confirmacao) {
  if (senha != confirmacao) {
    return 'As senhas não correspondem';
  }
  return null;
}

String? validarNomeCompleto(String? nomeCompleto) {
  final valor = nomeCompleto?.trim() ?? '';
  if (valor.isEmpty || valor.split(RegExp(r'\s+')).length < 2) {
    return 'Nome completo deve ter pelo menos 2 nomes';
  }
  return null;
}

String? validarUsername(String? username) {
  final valor = username?.trim() ?? '';
  if (valor.length < 3) {
    return 'Username deve ter pelo menos 3 caracteres';
  }
  if (!_formatoUsername.hasMatch(valor)) {
    return 'Username pode conter apenas letras, números e underscore';
  }
  return null;
}

String? validarTelefone(String? telefone) {
  final valor = telefone?.trim() ?? '';
  if (valor.isEmpty || !_formatoTelefone.hasMatch(valor)) {
    return 'Telefone inválido. Use o formato (XX)XXXXX-XXXX ou XXXXXXXXXXX';
  }
  return null;
}

/// No protótipo, universidade e curso eram texto livre. Na arquitetura nova são
/// seleções de `universidades` e `cursos` servidas pelo `user-service`, e a
/// validação passa a ser sobre o identificador escolhido.
String? validarUniversidadeSelecionada(String? universidadeId) {
  if (universidadeId == null || universidadeId.isEmpty) {
    return 'Universidade é obrigatória';
  }
  return null;
}

String? validarCursoSelecionado(String? cursoId) {
  if (cursoId == null || cursoId.isEmpty) {
    return 'Curso é obrigatório';
  }
  return null;
}
