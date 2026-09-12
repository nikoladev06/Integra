import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/storage/token_storage.dart';
import 'package:integra/features/auth/data/auth_repository.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/data/profile_repository.dart';

/// Estado da sessão. É o que o roteador observa para decidir se o usuário pode
/// ver as telas internas.
sealed class EstadoDaSessao {
  const EstadoDaSessao();
}

/// Enquanto o app checa se existe token guardado, na abertura.
///
/// Existe como estado próprio, e não como "deslogado até provar o contrário",
/// porque sem ele o app mostra a tela de login por um instante a cada abertura
/// e só então pula para dentro — o piscar clássico.
final class SessaoVerificando extends EstadoDaSessao {
  const SessaoVerificando();
}

final class SessaoAusente extends EstadoDaSessao {
  const SessaoAusente({this.motivo});

  /// Preenchido quando a sessão caiu por expiração, para a tela de login poder
  /// dizer por que o usuário voltou para lá.
  final String? motivo;
}

final class SessaoAtiva extends EstadoDaSessao {
  const SessaoAtiva(this.perfil);

  final Perfil perfil;
}

/// Ciclo de vida da sessão: abrir o app, entrar, sair.
class SessaoController extends Notifier<EstadoDaSessao> {
  @override
  EstadoDaSessao build() {
    _tokens = ref.watch(tokenStorageProvider);
    _auth = ref.watch(authRepositoryProvider);
    _perfis = ref.watch(profileRepositoryProvider);
    return const SessaoVerificando();
  }

  late TokenStorage _tokens;
  late AuthRepository _auth;
  late ProfileRepository _perfis;

  /// Chamado uma vez na abertura: existe token guardado que ainda serve?
  Future<void> restaurar() async {
    final token = await _tokens.lerAccessToken();
    if (token == null) {
      state = const SessaoAusente();
      return;
    }
    try {
      state = SessaoAtiva(await _perfis.meuPerfil());
    } on Failure catch (e) {
      await _tokens.limpar();
      state = SessaoAusente(motivo: e.mensagem);
    }
  }

  /// Entra e carrega o perfil. Propaga [Failure] para a tela mostrar o erro no
  /// campo certo — por isso não engole a exceção.
  Future<void> entrar({required String email, required String senha}) async {
    final par = await _auth.entrar(email: email, senha: senha);
    await _tokens.salvar(
      accessToken: par.accessToken,
      refreshToken: par.refreshToken,
    );
    state = SessaoAtiva(await _perfis.meuPerfil());
  }

  Future<void> sair() async {
    final refresh = await _tokens.lerRefreshToken();
    if (refresh != null) {
      try {
        await _auth.sair(refresh);
      } on Failure {
        // Logout é local acima de tudo: se o servidor não responder, o usuário
        // ainda tem que sair do app. O token some daqui de qualquer forma.
      }
    }
    await _tokens.limpar();
    state = const SessaoAusente();
  }

  /// Chamado pelo interceptor quando a renovação falha.
  void expirou() {
    state = const SessaoAusente(
      motivo: 'Sua sessão expirou. Entre novamente.',
    );
  }

  /// Depois de editar o perfil, sem refazer login.
  void atualizarPerfil(Perfil perfil) {
    if (state is SessaoAtiva) state = SessaoAtiva(perfil);
  }
}

final sessaoProvider = NotifierProvider<SessaoController, EstadoDaSessao>(
  SessaoController.new,
);

/// O perfil autenticado, ou nulo. Atalho para as telas não repetirem o `switch`.
final perfilAtualProvider = Provider<Perfil?>((ref) {
  final estado = ref.watch(sessaoProvider);
  return estado is SessaoAtiva ? estado.perfil : null;
});
