import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/fixtures.dart';

import '../../helpers/bombear_app.dart';

/// A barra de navegação inferior: quatro itens e a altura dela.
///
/// A altura tem teste porque errou duas vezes. O sintoma relatado foi sempre o
/// mesmo — "a base dos ícones fica distante do final da tela" —, e a causa tinha
/// duas partes: `padding` simétrico para carregar um ícone e um traço de 2 px, e o
/// `SafeArea`, que some em tela sem recorte e volta em celular com barra de gesto.
/// Um número afirmado aqui é o que impede a folga de crescer de novo sem ninguém
/// perceber.
void main() {
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  /// A distância entre a base do ícone e a base da barra.
  ///
  /// É o que o olho percebe como "espaço sobrando embaixo" — e não a altura da
  /// barra, que também cresce quando o ícone cresce.
  double folgaAbaixoDoIcone(WidgetTester tester) {
    final barra = tester.getRect(find.byKey(const ValueKey('barra-inferior')));
    final icone = tester.getRect(find.byIcon(LucideIcons.user));
    return barra.bottom - icone.bottom;
  }

  group('altura da barra', () {
    testWidgets('em tela sem recorte, a folga abaixo do ícone é mínima', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      final folga = folgaAbaixoDoIcone(tester);

      // O que fica abaixo do ícone: 3 px de respiro, 2 px de traço e 2 px de folga.
      expect(
        folga,
        lessThanOrEqualTo(8),
        reason: 'sobrou espaço abaixo dos ícones: $folga px',
      );
    });

    testWidgets('com barra de gesto, o recorte não vira faixa vazia', (
      tester,
    ) async {
      // **O caso que escapou duas vezes.** Em tela sem recorte a barra sempre
      // pareceu certa; num celular com barra de gesto de 48 px o `SafeArea`
      // repassava o recorte inteiro para baixo dos ícones, a faixa ia a 85 px e
      // sobravam 55 px embaixo. Os ícones pareciam colados no topo do rodapé.
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);

      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      final folga = folgaAbaixoDoIcone(tester);

      // Metade do recorte, com teto de 12: o ícone fica livre da pílula de gesto
      // sem doar a faixa toda. O teto é o que o número afirma.
      expect(
        folga,
        lessThanOrEqualTo(20),
        reason: 'o recorte do sistema voltou a virar faixa vazia: $folga px',
      );
    });

    testWidgets('a folga cresce com o recorte, mas só até o teto', (
      tester,
    ) async {
      double folgaCom(double recorte) =>
          recorte > 0 ? (recorte / 2).clamp(2.0, 12.0) : 2.0;

      // A conta que `_BarraInferior` faz, afirmada aqui para a intenção ficar
      // legível sem ler o widget: sem recorte é o mínimo; com recorte pequeno
      // acompanha; com recorte grande para no teto.
      expect(folgaCom(0), 2.0);
      expect(folgaCom(16), 8.0);
      expect(folgaCom(48), 12.0);
    });
  });

  group('os quatro itens', () {
    testWidgets('publicar fica entre Profissional e Perfil', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      final academico = tester.getCenter(find.byTooltip('Acadêmico')).dx;
      final profissional = tester.getCenter(find.byTooltip('Profissional')).dx;
      final publicar = tester.getCenter(find.byTooltip('Publicar')).dx;
      final perfil = tester.getCenter(find.byTooltip('Perfil')).dx;

      expect(academico, lessThan(profissional));
      expect(profissional, lessThan(publicar));
      expect(publicar, lessThan(perfil));
    });

    testWidgets('publicar é ação, não aba: não fica selecionado', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Publicar'));

      // Empilha por cima da casca. Se fosse um ramo, `currentIndex` passaria a
      // contar quatro e o Perfil deixaria de casar com a posição na barra.
      expect(find.text('Publicar'), findsWidgets);
      expect(find.text('Comunicado da instituição'), findsOne);
    });
  });

  group('o hub de publicação', () {
    testWidgets('a faculdade ativada alcança o comunicado', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await tocar(tester, find.byTooltip('Publicar'));

      await tocar(tester, find.text('Comunicado da instituição'));

      expect(find.text('Novo comunicado'), findsOne);
    });

    testWidgets('o aluno vê a opção e o motivo de não poder', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Publicar'));

      // Esmaecida e explicada, não escondida: a opção informa o que o produto tem,
      // e o texto diz por que não é para esta conta.
      expect(find.text('Comunicado da instituição'), findsOne);
      expect(find.textContaining('Só contas de faculdade publicam'), findsOne);

      await tocar(tester, find.text('Comunicado da instituição'));
      expect(
        find.text('Novo comunicado'),
        findsNothing,
        reason: 'tocar numa opção indisponível não abre o formulário',
      );
    });

    testWidgets('a empresa lê que comunicado institucional não é dela', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresa);
      await tocar(tester, find.byTooltip('Publicar'));

      // Empresa é conta institucional, mas comunicado acadêmico é de `faculdade`:
      // a checagem de **tipo** vem antes da de ativação, na mesma ordem do serviço.
      expect(find.textContaining('Só contas de faculdade publicam'), findsOne);
    });

    testWidgets('a faculdade pendente lê que está em análise', (tester) async {
      // Nenhuma fixture tem faculdade pendente — a FATEC nasce ativada para o
      // resto da demonstração funcionar. Aqui o estado é montado no banco, porque
      // é o estado em que **toda** conta institucional nasce, e o que a tela diz
      // nele é o que separa "não é para você" de "ainda não".
      final banco = BancoFalso();
      banco.salvar(Fixtures.perfilFatec.copyWith(ativadaEm: null));

      await bombearAppAutenticado(
        tester,
        email: Fixtures.emailFaculdade,
        banco: banco,
      );
      await tocar(tester, find.byTooltip('Publicar'));

      expect(find.textContaining('está em análise'), findsOne);

      await tocar(tester, find.text('Comunicado da instituição'));
      expect(
        find.text('Novo comunicado'),
        findsNothing,
        reason: 'pendente não alcança o formulário — o serviço responderia 403',
      );
    });

    testWidgets('as três opções aparecem, cada uma com o seu impedimento', (
      tester,
    ) async {
      // A aposta da Sprint 4 era que a tela não mudaria de forma quando os serviços
      // entrassem, e não mudou: as três opções continuam nas mesmas posições. O que
      // mudou é **de onde vem o impedimento** — era "entra na Sprint 5" para duas
      // delas, e agora é o tipo de conta e a ativação, que são as regras do servidor.
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Publicar'));

      expect(find.text('Comunicado da instituição'), findsOne);
      expect(find.text('Post no feed profissional'), findsOne);
      expect(find.text('Vaga'), findsOne);

      // A Ana é aluna: publica post, e não publica comunicado nem vaga. Cada recusa
      // diz o **seu** motivo — "indisponível" sem motivo manda o usuário adivinhar.
      expect(
        find.textContaining('Só contas de faculdade publicam'),
        findsOne,
      );
      expect(find.textContaining('Só contas de empresa publicam'), findsOne);
      expect(find.textContaining('entra na Sprint 5'), findsNothing);
    });
  });
}
