import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:integra/features/academic/presentation/academico_screen.dart';
import 'package:integra/features/academic/presentation/compor_post_screen.dart';
import 'package:integra/features/academic/presentation/post_screen.dart';
import 'package:integra/features/auth/presentation/cadastro_instituicao_screen.dart';
import 'package:integra/features/auth/presentation/cadastro_screen.dart';
import 'package:integra/features/auth/presentation/login_screen.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/institution/presentation/administracao_screen.dart';
import 'package:integra/features/jobs/presentation/compor_vaga_screen.dart';
import 'package:integra/features/jobs/presentation/vaga_screen.dart';
import 'package:integra/features/professional/presentation/compor_post_profissional_screen.dart';
import 'package:integra/features/professional/presentation/post_profissional_screen.dart';
import 'package:integra/features/messages/presentation/mensagens_screen.dart';
import 'package:integra/features/institution/presentation/perfil_de_universidade_screen.dart';
import 'package:integra/features/professional/presentation/profissional_screen.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/publishing/presentation/publicar_screen.dart';
import 'package:integra/features/profile/presentation/editar_perfil_screen.dart';
import 'package:integra/features/profile/presentation/perfil_screen.dart';
import 'package:integra/features/profile/presentation/trocar_senha_screen.dart';
import 'package:integra/features/search/presentation/busca_screen.dart';
import 'package:integra/shared/widgets/app_shell.dart';
import 'package:integra/shared/widgets/carregando_screen.dart';

/// Caminhos nomeados. Strings soltas no `context.go` são erro de digitação
/// esperando acontecer — o protótipo tinha um mapa de rotas por string e
/// navegava com literais.
abstract final class Rotas {
  static const carregando = '/carregando';
  static const login = '/login';
  static const cadastro = '/cadastro';
  static const cadastroDeFaculdade = '/cadastro/faculdade';
  static const cadastroDeEmpresa = '/cadastro/empresa';

  static const academico = '/academico';
  static const comporPost = '/academico/compor';
  static const posts = '/academico/posts';
  static const profissional = '/profissional';

  /// Compor um post do feed profissional. Fora do shell, como os formulários.
  static const comporPostProfissional = '/profissional/compor';

  /// Publicar uma vaga. Editar reusa a mesma tela, mas por `MaterialPageRoute` a
  /// partir do detalhe — ela precisa da [Vaga] carregada, e passar um objeto por
  /// caminho de URL exigiria serializá-lo ou recarregá-lo do zero.
  static const comporVaga = '/profissional/vagas/nova';

  static const postsProfissionais = '/profissional/posts';
  static const vagas = '/profissional/vagas';
  static const perfil = '/perfil';
  static const editarPerfil = '/perfil/editar';
  static const trocarSenha = '/perfil/senha';

  static const busca = '/busca';
  static const universidades = '/universidades';

  /// Mensagens diretas. **Ainda não existem** — a tela diz isso, e a rota existe
  /// para o botão do cabeçalho não precisar mudar de lugar quando o serviço entrar.
  static const mensagens = '/mensagens';

  /// O hub de publicação, aberto pelo botão central do rodapé. Fora do shell, como
  /// os formulários: é ida e volta.
  static const publicar = '/publicar';
  static const administracao = '/perfil/instituicao';

  static String post(String id) => '$posts/$id';

  static String postProfissional(String id) => '$postsProfissionais/$id';

  static String vaga(String id) => '$vagas/$id';

  static String universidade(String id) => '$universidades/$id';

  /// As telas alcançáveis **sem** sessão. Fora desta lista, tudo exige login.
  ///
  /// Uma lista de permissão, e não de bloqueio: a rota nova que alguém esquecer
  /// de classificar fica protegida por omissão, que é o erro barato. O contrário
  /// deixaria a tela nova aberta sem ninguém notar.
  static const semSessao = {
    login,
    cadastro,
    cadastroDeFaculdade,
    cadastroDeEmpresa,
  };
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
      final aberta = Rotas.semSessao.contains(destino);

      return switch (sessao) {
        // Ainda checando o token guardado: segura na tela de carregamento para
        // o login não piscar antes de entrar.
        SessaoVerificando() =>
          destino == Rotas.carregando ? null : Rotas.carregando,

        // Sem sessão: só login e os cadastros são alcançáveis.
        SessaoAusente() => aberta ? null : Rotas.login,

        // Com sessão: login, cadastro e carregamento não fazem mais sentido.
        SessaoAtiva() =>
          aberta || destino == Rotas.carregando ? Rotas.academico : null,
      };
    },

    routes: [
      GoRoute(
        path: Rotas.carregando,
        builder: (_, _) => const CarregandoScreen(),
      ),
      GoRoute(path: Rotas.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Rotas.cadastro, builder: (_, _) => const CadastroScreen()),

      // Uma tela por tipo, e não uma com parâmetro na URL: o `tipo` decide o que
      // o formulário pede e o que o aviso promete, e um valor inesperado na URL
      // não deveria conseguir produzir uma tela meio faculdade meio empresa.
      GoRoute(
        path: Rotas.cadastroDeFaculdade,
        builder: (_, _) =>
            const CadastroInstituicaoScreen(tipo: TipoConta.faculdade),
      ),
      GoRoute(
        path: Rotas.cadastroDeEmpresa,
        builder: (_, _) =>
            const CadastroInstituicaoScreen(tipo: TipoConta.empresa),
      ),

      // Fora do shell, e por isso empilhadas por cima dele: são destinos de ida
      // e volta, alcançáveis de qualquer aba, e manter a barra inferior num
      // formulário convida a sair dele pela metade.
      GoRoute(
        path: Rotas.editarPerfil,
        builder: (_, _) => const EditarPerfilScreen(),
      ),
      GoRoute(
        path: Rotas.trocarSenha,
        builder: (_, _) => const TrocarSenhaScreen(),
      ),
      GoRoute(path: Rotas.busca, builder: (_, _) => const BuscaScreen()),
      GoRoute(
        path: Rotas.mensagens,
        builder: (_, _) => const MensagensScreen(),
      ),
      GoRoute(path: Rotas.publicar, builder: (_, _) => const PublicarScreen()),
      GoRoute(
        path: Rotas.administracao,
        builder: (_, _) => const AdministracaoScreen(),
      ),

      // Fora do shell, como os formulários: compor um comunicado é ida e volta, e
      // manter a barra inferior convida a sair pela metade. A ordem importa —
      // `/academico/compor` antes de `/academico/posts/:id` não colide, mas os
      // dois precisam vir antes do `StatefulShellRoute`, senão o ramo do
      // Acadêmico captura o prefixo e abre o feed.
      GoRoute(
        path: Rotas.comporPost,
        builder: (_, _) => const ComporPostScreen(),
      ),
      GoRoute(
        path: '${Rotas.posts}/:id',
        builder: (_, estado) =>
            PostScreen(postId: estado.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Rotas.universidades}/:id',
        builder: (_, estado) => PerfilDeUniversidadeScreen(
          universidadeId: estado.pathParameters['id']!,
        ),
      ),

      // Pilar Profissional, Sprint 5. Fora do shell, pelo mesmo motivo das do
      // Academico: sao destinos de ida e volta.
      //
      // A ORDEM IMPORTA, e mais aqui que no Academico: `/profissional/vagas/nova`
      // tem que vir antes de `/profissional/vagas/:id`, senao a parametrizada
      // captura "nova" como identificador e a tela de detalhe pede uma vaga que
      // nao existe. E o mesmo cuidado que `/users/interno/resumos` exigiu no
      // user-service, do outro lado do contrato.
      GoRoute(
        path: Rotas.comporPostProfissional,
        builder: (_, _) => const ComporPostProfissionalScreen(),
      ),
      GoRoute(
        path: Rotas.comporVaga,
        builder: (_, _) => const ComporVagaScreen(),
      ),
      GoRoute(
        path: '${Rotas.postsProfissionais}/:id',
        builder: (_, estado) =>
            PostProfissionalScreen(postId: estado.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Rotas.vagas}/:id',
        builder: (_, estado) => VagaScreen(vagaId: estado.pathParameters['id']!),
      ),

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
