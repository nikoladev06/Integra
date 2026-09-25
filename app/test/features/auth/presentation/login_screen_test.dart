
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/storage/token_storage.dart';
import 'package:integra/features/profile/data/fixtures.dart';

import '../../../helpers/bombear_app.dart';
import '../../../helpers/localizadores.dart';

void main() {
  Future<void> preencherEEnviar(
    WidgetTester tester, {
    required String email,
    required String senha,
  }) async {
    await tester.enterText(campo('E-mail'), email);
    await tester.enterText(campo('Senha'), senha);
    await tester.tap(find.widgetWithText(ShadButton, 'Entrar'));
    await tester.pumpAndSettle();
  }

  group('LoginScreen', () {
    testWidgets('sem sessão, o app abre no login', (tester) async {
      await bombearApp(tester);

      // A guarda do roteador levou para o login sozinha, sem nenhuma tela
      // navegar à mão. No protótipo não havia guarda: dava para alcançar a tela
      // principal sem sessão.
      expect(find.widgetWithText(ShadButton, 'Entrar'), findsOne);
      expect(find.byTooltip('Acadêmico'), findsNothing);
    });

    testWidgets('e-mail inválido para antes de chamar o repositório', (
      tester,
    ) async {
      await bombearApp(tester);
      await preencherEEnviar(tester, email: 'a@b.c', senha: 'integra123');

      // 'a@b.c' passava no regex de cadastro do protótipo e falhava no de login:
      // o usuário cadastrava e depois não conseguia entrar. A regra unificada
      // na Sprint 0 recusa já aqui.
      expect(
        find.text('Insira um e-mail válido (ex: usuario@exemplo.com)'),
        findsOne,
      );
      expect(find.byTooltip('Acadêmico'), findsNothing);
    });

    testWidgets('senha curta mostra a mensagem do domínio', (tester) async {
      await bombearApp(tester);
      await preencherEEnviar(tester, email: Fixtures.emailDemo, senha: '123');

      expect(find.text('Senha deve ter no mínimo 6 caracteres'), findsOne);
    });

    testWidgets('credencial errada mostra o erro do repositório', (
      tester,
    ) async {
      await bombearApp(tester);
      await preencherEEnviar(
        tester,
        email: Fixtures.emailDemo,
        senha: 'senhaerrada',
      );

      // Mensagem genérica de propósito, como o contrato manda: distinguir
      // "e-mail não existe" de "senha errada" entregaria uma sonda de contas.
      expect(find.text('E-mail ou senha incorretos'), findsOne);
    });

    testWidgets('credencial correta entra e a guarda leva ao Acadêmico', (
      tester,
    ) async {
      await bombearApp(tester);
      await preencherEEnviar(
        tester,
        email: Fixtures.emailDemo,
        senha: Fixtures.senhaDemo,
      );

      // As abas são só ícone. O nome continua no widget — como tooltip e rótulo
      // semântico — e é por ele que o teste as encontra, que é também como um
      // leitor de tela as encontraria.
      expect(find.byTooltip('Acadêmico'), findsOne);
      expect(find.byTooltip('Profissional'), findsOne);
      expect(find.byTooltip('Perfil'), findsOne);
    });

    testWidgets('entrar carrega o perfil de QUEM entrou', (tester) async {
      await bombearApp(tester);
      await preencherEEnviar(
        tester,
        email: Fixtures.emailSemVinculo,
        senha: Fixtures.senhaSemVinculo,
      );

      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();

      // Antes de os dois falsos compartilharem estado, o perfil vinha de uma
      // fixture fixa: entrar como o Bruno mostrava o nome da Ana.
      expect(find.text(Fixtures.perfilSemVinculo.nomeCompleto), findsOne);
    });

    testWidgets('a credencial de exemplo aparece no modo de fixtures', (
      tester,
    ) async {
      await bombearApp(tester);

      expect(find.text('Modo de demonstração'), findsOne);
      expect(find.textContaining(Fixtures.emailDemo), findsOne);
    });

    testWidgets('token guardado abre direto no app, sem passar pelo login', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      expect(find.byTooltip('Acadêmico'), findsOne);
      expect(find.widgetWithText(ShadButton, 'Entrar'), findsNothing);
    });

    testWidgets('token guardado sem conta correspondente cai no login', (
      tester,
    ) async {
      // É o que acontece com uma sessão velha: o token existe, o perfil não
      // vem, e o app precisa voltar ao login em vez de quebrar na abertura.
      await bombearApp(
        tester,
        tokens: TokenStorageEmMemoria(
          accessToken: 'token-de-sessao-velha',
          refreshToken: 'refresh-velho',
        ),
      );

      expect(find.widgetWithText(ShadButton, 'Entrar'), findsOne);
      expect(find.text('Sessão expirada. Entre novamente.'), findsOne);
    });

    testWidgets('sair da conta volta para o login', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();

      // O perfil veio do repositório, atravessando sessão → repositório → banco
      // → tela. É esta asserção que prova a costura ponta a ponta.
      expect(find.text(Fixtures.perfilDemo.nomeCompleto), findsOne);
      expect(find.text('Vínculo institucional'), findsOne);

      // O botão está no fim de um ListView, e item fora da viewport não é
      // construído — daí rolar em vez de procurar direto.
      await tester.ensureVisible(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ShadButton, 'Entrar'), findsOne);
    });
  });
}
