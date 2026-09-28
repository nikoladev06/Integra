import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:integra/features/profile/data/fixtures.dart';

import '../../../helpers/bombear_app.dart';

/// As três abas do perfil da instituição.
///
/// Elas separam os comunicados por **alcance**, no formato que o Instagram usa para
/// separar posts, reels e marcações: geral, institucional e por curso. A ordem vai
/// do mais aberto para o mais fechado, e isso não é arrumação — é o que faz a tela
/// ensinar o modelo. Quem abre o perfil sem vínculo vê a primeira aba cheia e as
/// outras duas explicando o que falta, o que é uma frase sobre vínculo dita pela
/// própria tela.
///
/// O que estes testes protegem, além do layout: **o filtro por alcance não concede
/// nada.** Pedir a aba "por curso" sem vínculo naquele curso devolve vazio, não os
/// restritos — do lado do servidor isso é
/// `test_o_filtro_de_alcance_nao_concede_nada`, e aqui é a mesma frase pela tela.
void main() {
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  /// Chega ao perfil da FATEC pelo caminho real: busca do cabeçalho.
  Future<void> abrirPerfilDaFatec(WidgetTester tester) async {
    await tocar(
      tester,
      find.bySemanticsLabel('Buscar universidades, empresas e pessoas'),
    );
    await tester.enterText(find.byType(EditableText).first, 'fatec');
    // A busca é debounced: sem avançar o relógio, nenhuma consulta sai.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tocar(tester, find.text('FATEC RP'));
  }

  group('cabeçalho e identificação', () {
    testWidgets('não tem a palavra "Instituição"; a sigla identifica', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfilDaFatec(tester);

      // O título saiu junto com os das abas. Quem chegou aqui pela busca precisa
      // saber onde chegou, e "FATEC RP" diz isso melhor que "Instituição".
      expect(find.text('Instituição'), findsNothing);
      // Mais de uma: o cabeçalho do perfil e o de cada card de comunicado, que
      // também traz a sigla de quem publicou.
      expect(find.text('FATEC RP'), findsWidgets);
      expect(
        find.text('Faculdade de Tecnologia de Ribeirão Preto'),
        findsOne,
        reason: 'o nome inteiro aparece só na identificação do perfil',
      );
    });

    testWidgets('a busca fica, e o menu ocupa o lugar do chat', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfilDaFatec(tester);

      expect(
        find.bySemanticsLabel('Buscar universidades, empresas e pessoas'),
        findsOne,
      );
      // **O menu ocupa o canto direito, no lugar do chat.** Aqui ele é a ação da
      // tela — é por ele que o vínculo nasce —, e mensagens está a um toque em
      // qualquer aba.
      expect(find.byTooltip('Mensagens'), findsNothing);
      expect(find.byTooltip('Opções da instituição'), findsOne);

      // Sem botão de escopo: o perfil da instituição tem as próprias abas, e um
      // seletor de escopo do feed aqui não filtraria nada.
      expect(find.byTooltip('Escopo do feed: Geral'), findsNothing);
    });
  });

  group('as três abas', () {
    testWidgets('existem, e Geral começa selecionada', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfilDaFatec(tester);

      // Só ícones: o nome de cada aba saiu da tela e virou o que o leitor de tela
      // anuncia e o que o tooltip mostra — a mesma regra da navegação inferior.
      expect(find.text('Geral'), findsNothing);
      expect(find.byTooltip('Geral'), findsOne);
      expect(find.byTooltip('Institucional'), findsOne);
      expect(find.byTooltip('Por curso'), findsOne);

      // A aba aberta é a dos públicos — o único alcance que todo mundo alcança.
      expect(find.textContaining('Inscrições abertas'), findsOne);
      expect(find.textContaining('biblioteca funcionará'), findsNothing);
    });

    testWidgets('com vínculo, cada aba traz o alcance dela', (tester) async {
      // Ana tem vínculo na FATEC, em ADS.
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfilDaFatec(tester);

      await tocar(tester, find.byTooltip('Institucional'));
      expect(find.textContaining('biblioteca funcionará'), findsOne);
      expect(
        find.textContaining('Inscrições abertas'),
        findsNothing,
        reason: 'o público é da aba anterior — as abas não se misturam',
      );

      await tocar(tester, find.byTooltip('Por curso'));
      expect(find.textContaining('projeto integrador de ADS'), findsOne);
      expect(find.textContaining('biblioteca funcionará'), findsNothing);
    });
  });

  group('sem vínculo, o vazio explica o que falta', () {
    testWidgets('a aba Geral funciona: público é para todos', (tester) async {
      // Bruno declarou ADS na FATEC e não tem vínculo.
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);
      await abrirPerfilDaFatec(tester);

      // É o caminho de quem chegou pela busca sem seguir nem ter vínculo: o feed
      // não mostraria este post, e o perfil da instituição mostra.
      expect(find.textContaining('Inscrições abertas'), findsOne);
    });

    testWidgets('a aba Institucional diz que declarar a formação não basta', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);
      await abrirPerfilDaFatec(tester);
      await tocar(tester, find.byTooltip('Institucional'));

      // **O filtro não concede nada:** pedir o alcance não abre o alcance.
      expect(find.textContaining('biblioteca funcionará'), findsNothing);

      // E o vazio não é genérico: ele diz por que está vazio, e o que fazer. É a
      // regra da v2 dita pela tela, no momento em que ela importa.
      expect(
        find.textContaining('Declarar a formação no perfil não basta'),
        findsOne,
      );
      expect(find.textContaining('informe seu CPF'), findsOne);
    });

    testWidgets('a aba Por curso também, e com o texto do caso dela', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);
      await abrirPerfilDaFatec(tester);
      await tocar(tester, find.byTooltip('Por curso'));

      expect(find.textContaining('projeto integrador de ADS'), findsNothing);
      expect(find.textContaining('vínculo ativo naquele curso'), findsOne);
    });

    testWidgets('as três abas aparecem mesmo para quem não alcança duas', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);
      await abrirPerfilDaFatec(tester);

      // Esconder as restritas deixaria o aluno sem saber que existe conteúdo que
      // ele não alcança — e é justamente isso que o leva a informar o CPF.
      expect(find.byTooltip('Institucional'), findsOne);
      expect(find.byTooltip('Por curso'), findsOne);
    });
  });

  group('vínculo em outro curso', () {
    testWidgets(
      'a aba Por curso fica vazia, e diz que é por ser de outro curso',
      (tester) async {
        // Carla tem vínculo na FATEC, em Gestão Empresarial.
        await bombearAppAutenticado(tester, email: Fixtures.emailOutroCurso);
        await abrirPerfilDaFatec(tester);

        // O interno ela vê: o vínculo é com esta instituição.
        await tocar(tester, find.byTooltip('Institucional'));
        expect(find.textContaining('biblioteca funcionará'), findsOne);

        // O restrito a ADS, não — e o texto distingue "nada publicado" de "não é do
        // seu curso", que é a diferença que a granularidade por curso produz.
        await tocar(tester, find.byTooltip('Por curso'));
        expect(find.textContaining('projeto integrador de ADS'), findsNothing);
        expect(find.textContaining('Comunicados de outros cursos'), findsOne);
      },
    );
  });
}
