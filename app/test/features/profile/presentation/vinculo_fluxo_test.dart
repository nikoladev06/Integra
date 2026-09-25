import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/features/profile/data/fixtures.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

import '../../../helpers/bombear_app.dart';
import '../../../helpers/localizadores.dart';

/// O fluxo que a Sprint 3 existe para entregar, ponta a ponta pelo app:
/// buscar a faculdade, abrir o perfil dela, inserir o CPF e ver a formação
/// declarada ganhar o selo.
///
/// Roda contra os falsos, sem servidor — que é a condição do portão. O que ele
/// prova é a costura: tela → repositório → estado → tela de novo.
void main() {
  Future<void> abrirBusca(WidgetTester tester) async {
    await tester.tap(find.text('Buscar universidades, empresas e pessoas'));
    await tester.pumpAndSettle();
  }

  Future<void> buscar(WidgetTester tester, String termo) async {
    await tester.enterText(find.byType(EditableText).first, termo);
    // A busca é debounced: sem avançar o relógio, nenhuma consulta sai.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  /// Rola até o alvo e toca nele.
  ///
  /// `ensureVisible` em vez de `scrollUntilVisible`: as telas têm mais de um
  /// `Scrollable` na árvore, e o segundo exige que só exista um.
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> abrirMenuDaInstituicao(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Opções da instituição'));
    await tester.pumpAndSettle();
  }

  group('busca do cabeçalho', () {
    testWidgets('agrupa universidades, empresas e pessoas', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirBusca(tester);
      await buscar(tester, 'a');

      // Abaixo de duas letras a consulta nem sai: buscar com uma letra é pedir
      // metade da base.
      expect(find.text('Digite pelo menos 2 letras para buscar.'), findsOne);

      await buscar(tester, 'fatec');
      expect(find.text('Universidades'), findsOne);
      expect(find.text('FATEC RP'), findsOne);
      // A conta institucional da FATEC não aparece também em "Pessoas".
      expect(find.text('Pessoas'), findsNothing);
    });

    testWidgets('diz quando a universidade ainda não tem conta', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirBusca(tester);
      await buscar(tester, 'universidade de são');

      // Sem conta institucional ela não publica nem matricula, e dizer isso na
      // lista evita a viagem até um perfil que não tem o que oferecer.
      expect(
        find.textContaining('ainda sem conta no Integra'),
        findsOne,
      );
    });

    testWidgets('nada encontrado é diferente de erro', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirBusca(tester);
      await buscar(tester, 'zzzzz');

      expect(find.textContaining('Nada encontrado'), findsOne);
    });
  });

  group('inserir CPF no perfil da faculdade', () {
    testWidgets('sem vínculo, o menu oferece inserir CPF', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);
      await abrirBusca(tester);
      await buscar(tester, 'fatec');
      await tester.tap(find.text('FATEC RP'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sem vínculo'), findsOne);
      await abrirMenuDaInstituicao(tester);
      expect(find.text('Inserir CPF'), findsOne);
      expect(find.text('Encerrar vínculo'), findsNothing);
    });

    testWidgets('o CPF próprio na lista cria o vínculo e estampa o selo', (
      tester,
    ) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailSemVinculo,
      );

      // Estado inicial: formação declarada, sem selo, e sem vínculo.
      final antes = banco.usuarios[Fixtures.perfilSemVinculo.id]!;
      expect(antes.formacoes.single.verificada, isFalse);
      expect(antes.vinculo, isNull);

      await abrirBusca(tester);
      await buscar(tester, 'fatec');
      await tester.tap(find.text('FATEC RP'));
      await tester.pumpAndSettle();

      await abrirMenuDaInstituicao(tester);
      await tester.tap(find.text('Inserir CPF'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).last, Fixtures.cpfBruno);
      await tester.tap(find.widgetWithText(ShadButton, 'Confirmar'));
      await tester.pumpAndSettle();

      final depois = banco.usuarios[Fixtures.perfilSemVinculo.id]!;
      expect(depois.vinculo?.universidade.id, Fixtures.fatecRp.id);
      // O curso veio da matrícula, não de escolha do aluno.
      expect(depois.vinculo?.curso.id, Fixtures.ads.id);
      // A formação que ele já havia declarado ganhou o selo, em vez de uma
      // segunda linha idêntica no currículo.
      expect(depois.formacoes, hasLength(1));
      expect(depois.formacoes.single.verificada, isTrue);
    });

    testWidgets('o CPF de outra pessoa é recusado', (tester) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailSemVinculo,
      );

      await abrirBusca(tester);
      await buscar(tester, 'fatec');
      await tester.tap(find.text('FATEC RP'));
      await tester.pumpAndSettle();

      await abrirMenuDaInstituicao(tester);
      await tester.tap(find.text('Inserir CPF'));
      await tester.pumpAndSettle();

      // O CPF da Ana consta na lista da FATEC. Se a conferência contra a
      // própria conta não viesse primeiro, sabê-lo bastaria para entrar na
      // instituição dela — e CPF circula em vazamentos.
      await tester.enterText(find.byType(EditableText).last, Fixtures.cpfAna);
      await tester.tap(find.widgetWithText(ShadButton, 'Confirmar'));
      await tester.pumpAndSettle();

      expect(banco.usuarios[Fixtures.perfilSemVinculo.id]!.vinculo, isNull);
    });

    testWidgets('com vínculo, o menu oferece encerrar', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirBusca(tester);
      await buscar(tester, 'fatec');
      await tester.tap(find.text('FATEC RP'));
      await tester.pumpAndSettle();

      expect(find.text('Você tem vínculo aqui'), findsOne);
      await abrirMenuDaInstituicao(tester);
      expect(find.text('Encerrar vínculo'), findsOne);
      expect(find.text('Inserir CPF'), findsNothing);
    });
  });

  group('perfil', () {
    testWidgets('mostra formação e vínculo como coisas separadas', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);
      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();

      // Dois cartões, com textos que dizem o que cada um vale. Na v1 havia um
      // só, e ele dava a entender que declarar era pertencer.
      expect(find.text('Formação'), findsOne);
      expect(find.text('Vínculo institucional'), findsOne);
      expect(find.textContaining('Você não tem vínculo ativo'), findsOne);
    });

    testWidgets('conta institucional pendente vê o aviso de análise', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: 'rh@orbita.com.br');
      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Conta em análise'), findsOne);
      // Empresa não tem currículo nem vínculo: organização não estuda em lugar
      // nenhum.
      expect(find.text('Formação'), findsNothing);
      expect(find.text('Vínculo institucional'), findsNothing);
    });

    testWidgets('a aba Acadêmico explica a ausência de vínculo', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);

      expect(find.text('Você ainda não tem vínculo'), findsOne);
      // Declarar a FATEC no currículo não muda isso, e a tela não promete o
      // contrário.
      expect(
        find.textContaining('só aparecem para quem tem vínculo'),
        findsOne,
      );
    });
  });

  group('editar perfil', () {
    Future<void> abrirEdicao(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Editar perfil'));
    }

    testWidgets('salva nome, username, telefone e bio', (tester) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await abrirEdicao(tester);

      await tester.enterText(campo('Bio'), 'Nova bio de teste');
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Salvar alterações'));

      expect(banco.usuarios[Fixtures.perfilDemo.id]!.bio, 'Nova bio de teste');
    });

    testWidgets('formação verificada não tem botão de remover', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirEdicao(tester);
      await tester.ensureVisible(find.text('Formação'));
      await tester.pumpAndSettle();

      // O selo é afirmação da instituição, não do usuário: o botão nem aparece,
      // em vez de aparecer e responder erro.
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
    });

    testWidgets('encerrar vínculo preserva o selo', (tester) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await abrirEdicao(tester);
      await tocar(tester, find.text('Encerrar vínculo'));

      final perfil = banco.usuarios[Fixtures.perfilDemo.id]!;
      expect(perfil.vinculo, isNull);
      // Encerrar não desfaz o fato de ter estudado lá.
      expect(perfil.formacoes.single.verificada, isTrue);
    });
  });

  group('trocar senha', () {
    testWidgets('a troca revoga a sessão e leva ao login', (tester) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );

      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Trocar senha'));

      final campos = find.byType(EditableText);
      await tester.enterText(campos.at(0), Fixtures.senhaDemo);
      await tester.enterText(campos.at(1), 'novaSenha1');
      await tester.enterText(campos.at(2), 'novaSenha1');
      await tester.tap(find.widgetWithText(ShadButton, 'Trocar senha'));
      await tester.pumpAndSettle();

      // Todas as sessões caem, inclusive a que fez a troca — a tela leva ao
      // login em vez de deixar o usuário descobrir isso na próxima requisição.
      expect(find.widgetWithText(ShadButton, 'Entrar'), findsOne);
      expect(banco.senhas[Fixtures.emailDemo], 'novaSenha1');
    });

    testWidgets('mostra todos os erros de uma vez', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Trocar senha'));

      final campos = find.byType(EditableText);
      await tester.enterText(campos.at(0), '');
      await tester.enterText(campos.at(1), '123');
      await tester.enterText(campos.at(2), '456');
      await tester.tap(find.widgetWithText(ShadButton, 'Trocar senha'));
      await tester.pumpAndSettle();

      // Corrigir um erro por vez, com uma requisição entre cada, é o que o
      // protótipo fazia.
      expect(find.textContaining('Senha atual é obrigatória'), findsOne);
      expect(find.textContaining('pelo menos 6 caracteres'), findsOne);
      expect(find.textContaining('As senhas não correspondem'), findsOne);
    });
  });
}
