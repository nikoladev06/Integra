import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/features/profile/data/fixtures.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

import '../../../helpers/bombear_app.dart';
import '../../../helpers/localizadores.dart';

void main() {
  /// CPF estruturalmente válido e ausente da base semeada.
  const cpfNovo = '24611680320';

  Future<void> irParaOCadastro(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ShadButton, 'Criar conta'));
    await tester.pumpAndSettle();
  }

  Future<void> preencher(
    WidgetTester tester, {
    String cpf = cpfNovo,
    String email = 'novo@exemplo.com',
  }) async {
    await tester.enterText(campo('Nome completo'), 'Diego Santos Alves');
    await tester.enterText(campo('E-mail'), email);
    await tester.enterText(campo('Nome de usuário'), 'diegosa');
    await tester.enterText(campo('CPF'), cpf);
    await tester.enterText(campo('Telefone'), '(16)99999-0000');
    await tester.enterText(campo('Senha'), 'segredo1');
    await tester.enterText(campo('Confirme a senha'), 'segredo1');
    await tester.pumpAndSettle();
  }

  /// Rola até o alvo e toca nele.
  ///
  /// `ensureVisible` em vez de `scrollUntilVisible`: a tela tem mais de um
  /// `Scrollable` na árvore — o formulário e os popovers dos combobox — e o
  /// segundo exige que só exista um.
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> enviar(WidgetTester tester) =>
      tocar(tester, find.widgetWithText(ShadButton, 'Criar conta'));

  group('cadastro de aluno', () {
    testWidgets('o login leva ao cadastro sem sessão', (tester) async {
      await bombearApp(tester);
      await irParaOCadastro(tester);

      // A guarda do roteador libera o cadastro sem sessão — e só ele e o login.
      expect(find.text('Conta de aluno'), findsOne);
    });

    testWidgets('cria a conta sem declarar formação', (tester) async {
      final banco = await bombearApp(tester);
      await irParaOCadastro(tester);
      await preencher(tester);
      await enviar(tester);

      final criado = banco.usuarios.values.firstWhere(
        (u) => u.email == 'novo@exemplo.com',
      );
      expect(criado.nomeCompleto, 'Diego Santos Alves');
      expect(criado.cpf, cpfNovo);
      // Universidade e curso em branco é resposta válida desde a v2: declarar
      // formação não concede nada, e exigir no cadastro só produzia currículo
      // escolhido a esmo.
      expect(criado.formacoes, isEmpty);
      expect(criado.vinculo, isNull);
    });

    testWidgets('não faz login automático: volta ao login com o aviso', (
      tester,
    ) async {
      await bombearApp(tester);
      await irParaOCadastro(tester);
      await preencher(tester);
      await enviar(tester);

      expect(find.widgetWithText(ShadButton, 'Entrar'), findsOne);
      expect(
        find.text('Conta criada. Entre com seu e-mail e senha.'),
        findsOne,
      );
    });

    testWidgets('a conta criada consegue entrar em seguida', (tester) async {
      await bombearApp(tester);
      await irParaOCadastro(tester);
      await preencher(tester);
      await enviar(tester);

      await tester.enterText(campo('E-mail'), 'novo@exemplo.com');
      await tester.enterText(campo('Senha'), 'segredo1');
      await tester.tap(find.widgetWithText(ShadButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Acadêmico'), findsOne);
    });

    testWidgets('CPF inválido para no cliente, sem requisição', (tester) async {
      final banco = await bombearApp(tester);
      final antes = banco.usuarios.length;

      await irParaOCadastro(tester);
      await preencher(tester, cpf: '11111111111');
      await enviar(tester);

      expect(find.text('CPF inválido'), findsOne);
      expect(banco.usuarios, hasLength(antes));
    });

    testWidgets('e-mail já cadastrado mostra o conflito do repositório', (
      tester,
    ) async {
      await bombearApp(tester);
      await irParaOCadastro(tester);
      await preencher(tester, email: Fixtures.emailDemo);
      await enviar(tester);

      expect(find.text('Email já cadastrado'), findsOne);
    });
  });

  group('cadastro institucional', () {
    Future<void> irParaFaculdade(WidgetTester tester) =>
        tocar(tester, find.widgetWithText(ShadButton, 'Sou faculdade'));

    testWidgets('a tela avisa que a conta entra em análise', (tester) async {
      await bombearApp(tester);
      await irParaOCadastro(tester);
      await irParaFaculdade(tester);

      // O aviso não é cortesia: é o que explica por que a conta não publica de
      // imediato, e evita o suporte que a ausência dele geraria.
      expect(find.text('A conta entra em análise'), findsOne);
      // Só a faculdade tem sigla — é o rótulo curto da universidade que ela
      // reivindica ou cria.
      expect(find.text('Sigla (opcional)'), findsOne);
    });

    testWidgets('a conta de faculdade nasce pendente', (tester) async {
      final banco = await bombearApp(tester);
      await irParaOCadastro(tester);
      await irParaFaculdade(tester);

      await tester.enterText(campo('Nome da instituição'), 'Instituto Exemplo');
      await tester.enterText(campo('Sigla (opcional)'), 'IEX');
      await tester.enterText(campo('CNPJ'), '11222333000181');
      await tester.enterText(campo('E-mail'), 'contato@iex.edu.br');
      await tester.enterText(campo('Nome de usuário'), 'iex_oficial');
      await tester.enterText(campo('Telefone'), '(16)3333-1111');
      await tester.enterText(campo('Senha'), 'segredo1');
      await tester.enterText(campo('Confirme a senha'), 'segredo1');
      await tester.pumpAndSettle();

      await tocar(tester, find.widgetWithText(ShadButton, 'Criar conta'));

      final conta = banco.usuarios.values.firstWhere(
        (u) => u.email == 'contato@iex.edu.br',
      );
      expect(conta.tipo, TipoConta.faculdade);
      expect(conta.cnpj, '11222333000181');
      // `ativadaEm` nulo é o estado pendente — a peça que impede alguém de
      // distribuir formações "verificadas" em nome de uma instituição cujo
      // CNPJ, sendo público, qualquer um consulta.
      expect(conta.ativadaEm, isNull);

      // A universidade nova entra no catálogo, já marcada como administrada.
      final nova = banco.universidades.firstWhere((u) => u.sigla == 'IEX');
      expect(nova.temConta, isTrue);
    });
  });
}
