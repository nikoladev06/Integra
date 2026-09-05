/// Regras da troca de senha feita pelo usuário já autenticado.
///
/// Extraídas de `UserProfileController.atualizarSenha` no protótipo
/// (`reference/legacy_app/controller/userprofile_controller.dart`).
///
/// Este é o único caminho de mudança de senha no escopo atual: **não há
/// recuperação de senha por e-mail**. O `auth-service` expõe uma rota
/// autenticada que exige a senha atual, e não emite token de reset.
library;

import 'package:integra/features/auth/domain/auth_validators.dart';

/// Erros da troca de senha, na ordem em que devem ser apresentados ao usuário.
/// Vazio significa que o formulário pode ser enviado.
List<String> validarTrocaDeSenha({
  required String senhaAtual,
  required String novaSenha,
  required String confirmacao,
}) {
  final erros = <String>[];

  if (senhaAtual.isEmpty) {
    erros.add('Senha atual é obrigatória');
  }

  if (novaSenha.isEmpty || novaSenha.length < senhaComprimentoMinimo) {
    erros.add(
      'Nova senha deve ter pelo menos $senhaComprimentoMinimo caracteres',
    );
  }

  if (novaSenha != confirmacao) {
    erros.add('As senhas não correspondem');
  }

  if (senhaAtual.isNotEmpty && senhaAtual == novaSenha) {
    erros.add('A nova senha deve ser diferente da atual');
  }

  return erros;
}
