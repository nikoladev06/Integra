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

import 'package:integra/shared/domain/documentos.dart';

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

/// Formação declarada no cadastro: **os dois campos juntos, ou nenhum deles**.
///
/// Mudou de forma na v2. Na v1 universidade e curso eram obrigatórios e a
/// seleção virava a afiliação que concedia acesso aos posts internos da
/// instituição — declarar bastava. Agora declarar é cosmético, como no
/// LinkedIn, e quem concede acesso é o vínculo, que nasce do CPF conferido
/// contra a lista da faculdade.
///
/// O que sobrou de regra é só a coerência do par: o `auth-service` recusa
/// universidade sem curso com o mesmo critério (`CadastroIn._formacao_completa_ou_ausente`),
/// porque meia formação é uma linha de currículo que nenhuma tela sabe exibir.
/// A tela encadeia os dois combobox — escolher a universidade habilita o de
/// cursos — então só um preenchido significa que o usuário parou no meio.
String? validarFormacaoDeclarada({String? universidadeId, String? cursoId}) {
  final temUniversidade = universidadeId != null && universidadeId.isNotEmpty;
  final temCurso = cursoId != null && cursoId.isNotEmpty;

  if (temUniversidade && !temCurso) return 'Escolha também o curso';
  if (temCurso && !temUniversidade) return 'Escolha também a universidade';
  return null;
}

/// CPF do cadastro de aluno. Obrigatório desde a v2.
///
/// É a chave que liga a conta às matrículas que as faculdades cadastram, e por
/// isso não é editável depois: trocar o próprio CPF pelo de outra pessoa
/// permitiria assumir a matrícula dela.
///
/// A mensagem é a mesma para todos os casos de recusa, porque para quem digitou
/// a ação é sempre "confira o número" — e é a mesma string que o `auth-service`
/// devolve em `fields.cpf`.
String? validarCpf(String? cpf) {
  final valor = cpf?.trim() ?? '';
  if (valor.isEmpty) return 'CPF é obrigatório';
  if (!cpfEValido(valor)) return 'CPF inválido';
  return null;
}

/// CNPJ do cadastro institucional. Obrigatório, e único por conta.
///
/// Validar os dígitos recusa número digitado errado — **não** prova que quem
/// digitou representa aquela organização. É por isso que a conta institucional
/// nasce pendente de ativação, e não porque o número possa ser falso.
String? validarCnpj(String? cnpj) {
  final valor = cnpj?.trim() ?? '';
  if (valor.isEmpty) return 'CNPJ é obrigatório';
  if (!cnpjEValido(valor)) return 'CNPJ inválido';
  return null;
}

/// Nome da instituição, como aparecerá no perfil.
String? validarNomeDaInstituicao(String? nome) {
  final valor = nome?.trim() ?? '';
  if (valor.length < 2) return 'Informe o nome da instituição';
  if (valor.length > 200) return 'Nome muito longo (máximo 200 caracteres)';
  return null;
}
