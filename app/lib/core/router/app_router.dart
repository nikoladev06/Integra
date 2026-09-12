import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:integra/features/academic/presentation/academico_screen.dart';
import 'package:integra/features/auth/presentation/login_screen.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/professional/presentation/profissional_screen.dart';
import 'package:integra/features/profile/presentation/perfil_screen.dart';
import 'package:integra/shared/widgets/app_shell.dart';
import 'package:integra/shared/widgets/carregando_screen.dart';

/// Caminhos nomeados. Strings soltas no `context.go` são erro de digitação
/// esperando acontecer — o protótipo tinha um mapa de rotas por string e
/// navegava com literais.
abstract final class Rotas {
  static const carregando = '/carregando';
  static const login = '/login';
  static const academico = '/academico';
  static const profissional = '/profissional';
  static const perfil = '/perfil';
}

/// Ponte entre o Riverpod e o `refreshListenable` do go_router, que só entende
/// `Listenable`. Sem ela, mudar a sessão não reavalia o `redirect`.
class _SessaoListenable extends ChangeNotifier {
  _SessaoListenable(Ref ref) {
    ref.listen(sessaoProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final escuta = _SessaoListenable(ref);
  ref.onDispose(escuta.dispose);

  return GoRouter(
    initialLocation: Rotas.carregando,
    refreshListenable: escuta,
    debugLogDiagnostics: kDebugMode,

    /// A guarda de autenticação.
    ///
    /// No protótipo o mapa de rotas não tinha guarda nenhuma: dava para navegar
    /// até a tela principal sem sessão. Aqui é o roteador que decide, num lugar
    /// só, em vez de cada tela checar por conta própria — e esquecer.
    redirect: (context, estadoDaRota) {
      final sessao = ref.read(sessaoProvider);
      final destino = estadoDaRota.matchedLocation;

      return switch (sessao) {
        // Ainda checando o token guardado: segura na tela de carregamento para
        // o login não piscar antes de entrar.
        SessaoVerificando() =>
          destino == Rotas.carregando ? null : Rotas.carregando,

        // Sem sessão: só o login é alcançável.
        SessaoAusente() => destino == Rotas.login ? null : Rotas.login,

        // Com sessão: login e carregamento não fazem mais sentido.
        SessaoAtiva() =>
          destino == Rotas.login || destino == Rotas.carregando
              ? Rotas.academico
              : null,
      };
    },

    routes: [
      GoRoute(
        path: Rotas.carregando,
        builder: (_, _) => const CarregandoScreen(),
      ),
      GoRoute(path: Rotas.login, builder: (_, _) => const LoginScreen()),

      // Uma pilha de navegação por aba: entrar num perfil pelo feed e trocar de
      // aba preserva as duas posições, em vez de resetar a que saiu.
      StatefulShellRoute.indexedStack(
        builder: (_, _, navegacao) => AppShell(navegacao: navegacao),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rotas.academico,
                builder: (_, _) => const AcademicoScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rotas.profissional,
                builder: (_, _) => const ProfissionalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rotas.perfil,
                builder: (_, _) => const PerfilScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
