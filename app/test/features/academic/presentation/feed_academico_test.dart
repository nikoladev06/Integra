import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/features/profile/data/fixtures.dart';

import '../../../helpers/bombear_app.dart';

/// O portão do pilar Acadêmico, pelo app: a faculdade publica restrito a um curso,
/// o aluno com vínculo naquele curso vê, e quem só declarou a mesma formação não.
///
/// Roda contra os falsos, sem servidor — a mesma condição do portão da Sprint 3. O
/// que estes testes provam é a costura: tela → repositório → estado → tela de novo.
/// A regra em si é verificada em `fake_academic_repository_test.dart` e, do lado do
/// servidor, em `services/academic/tests/`.
void main() {
  /// Rola até o alvo e toca. `ensureVisible` em vez de `scrollUntilVisible`: as
  /// telas têm mais de um `Scrollable` na árvore, e o segundo exige que só exista
  /// um.
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  group('feed acadêmico', () {
    testWidgets('o aluno com vínculo em ADS vê os três alcances', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      // Público, interno e restrito a ADS: o feed é a primeira tela do app, então
      // não há navegação antes.
      expect(find.textContaining('Inscrições abertas'), findsOne);
      expect(find.textContaining('biblioteca funcionará'), findsOne);
      expect(find.textContaining('projeto integrador de ADS'), findsOne);
    });

    testWidgets('a etiqueta diz a quem o comunicado restrito vai', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      // Um restrito parece igual a um público se nada disser o contrário, e o
      // aluno precisa saber que aquilo não é público — sobretudo antes de comentar.
      expect(
        find.text('Restrito a Análise e Desenvolvimento de Sistemas'),
        findsOne,
      );
      expect(find.text('Institucional'), findsOne);
      // O público **não** ganha etiqueta: é o alcance esperado, e marcá-lo faria a
      // etiqueta perder o sentido de aviso.
      expect(find.text('Público'), findsNothing);
    });

    testWidgets('quem só declarou a formação vê apenas o público', (
      tester,
    ) async {
      // Bruno declarou ADS na FATEC e não tem vínculo. É a frase do portão da
      // sprint, do lado da tela.
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);

      expect(find.textContaining('Inscrições abertas'), findsNothing);
      expect(find.textContaining('biblioteca funcionará'), findsNothing);
      expect(find.textContaining('projeto integrador de ADS'), findsNothing);

      // Sem seguir ninguém e sem vínculo, o escopo geral é vazio — e o vazio diz
      // o que fazer em vez de deixar concluir que a faculdade não publica nada.
      expect(find.text('Você ainda não tem vínculo'), findsOne);
      expect(
        find.textContaining('declarar a formação no perfil não basta'),
        findsOne,
      );
      expect(find.text('Buscar minha faculdade'), findsOne);
    });

    testWidgets('o vazio sem vínculo leva à busca', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);
      await tocar(tester, find.text('Buscar minha faculdade'));

      // O caminho que cria o vínculo começa na busca: achar a faculdade, abrir o
      // perfil dela, inserir o CPF.
      expect(find.text('Universidades, empresas e pessoas'), findsOne);
    });

    testWidgets('o aluno de outro curso não recebe o restrito', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailOutroCurso);

      expect(find.textContaining('biblioteca funcionará'), findsOne);
      expect(
        find.textContaining('projeto integrador de ADS'),
        findsNothing,
        reason: 'Carla tem vínculo em Gestão, não em ADS',
      );
    });
  });

  group('botão de escopo', () {
    testWidgets('é um ícone só, e o feed começa no escopo geral', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      // A barra que ocupava uma faixa abaixo do cabeçalho saiu: o escopo é uma
      // escolha que a maioria faz uma vez, e custava permanentemente a parte mais
      // valiosa de uma tela de celular.
      expect(find.text('Escopo do feed'), findsNothing);
      expect(find.text('Alterar'), findsNothing);

      // O rótulo do escopo em vigor vive no tooltip, porque o cabeçalho não tem
      // texto. É também o nome que o leitor de tela anuncia.
      expect(find.byTooltip('Escopo do feed: Geral'), findsOne);
    });

    testWidgets('um toque já abre as duas opções', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Escopo do feed: Geral'));

      // Um toque, não dois: a barra antiga exigia abrir e então escolher.
      expect(find.text('Geral'), findsOne);
      expect(find.text('Minha instituição'), findsOne);
      // A descrição vem junto: "geral" e "minha instituição" não dizem sozinhos o
      // que incluem, e a barra que explicava isso saiu.
      expect(find.textContaining('e as que você segue'), findsOne);
    });

    testWidgets('trocar de escopo filtra e o tooltip passa a dizer qual', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Escopo do feed: Geral'));
      await tocar(tester, find.text('Minha instituição'));

      expect(find.byTooltip('Escopo do feed: Minha instituição'), findsOne);
      // A FATEC é a do vínculo, então os comunicados continuam aparecendo.
      expect(find.textContaining('biblioteca funcionará'), findsOne);
    });

    testWidgets('o profissional tem o próprio escopo, por quem publica', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Profissional'));

      // O escopo existe nas duas abas, mas filtra coisas diferentes: no Acadêmico
      // escolhe **instituições**, aqui escolhe **quem publica** — no profissional
      // não há vínculo a consultar, e o que distingue um post é o tipo de conta.
      await tocar(tester, find.byTooltip('Escopo do feed: Geral'));

      expect(find.text('Só empresas'), findsOne);
      expect(find.text('Só pessoas'), findsOne);
    });

    testWidgets('o escopo do profissional persiste e o vazio o repete', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Profissional'));
      await tocar(tester, find.byTooltip('Escopo do feed: Geral'));
      await tocar(tester, find.text('Só empresas'));

      // O serviço só entra na Sprint 5, então não há o que filtrar ainda — mas o
      // vazio repete a escolha. É a diferença entre um controle e uma decoração: o
      // usuário vê que mexer no botão mudou algo.
      expect(find.byTooltip('Escopo do feed: Só empresas'), findsOne);
      expect(
        find.textContaining('Vagas e comunicados de quem contrata'),
        findsOne,
      );

      // E sobrevive à troca de aba, porque mora num provider.
      await tocar(tester, find.byTooltip('Acadêmico'));
      await tocar(tester, find.byTooltip('Profissional'));
      expect(find.byTooltip('Escopo do feed: Só empresas'), findsOne);
    });
  });

  group('cabeçalho', () {
    testWidgets('não tem o nome da tela em nenhuma aba', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      // O título saiu por onde o rótulo das abas já havia saído: escrever
      // "Acadêmico" acima de uma aba de Acadêmico já sublinhada é dizer duas vezes
      // a mesma coisa, e o preço é a faixa mais valiosa da tela.
      expect(find.text('Acadêmico'), findsNothing);

      await tocar(tester, find.byTooltip('Profissional'));
      expect(find.text('Profissional'), findsNothing);

      await tocar(tester, find.byTooltip('Perfil'));
      expect(find.text('Perfil'), findsNothing);
    });

    testWidgets('é baixo: sem título, não precisa da altura de um', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      final campo = tester.getRect(
        find.bySemanticsLabel('Buscar universidades, empresas e pessoas'),
      );

      // A altura padrão de `AppBar` no Material é 56, dimensionada para um título
      // com folga. Sem título, isso virava faixa vazia no topo de toda tela — daí
      // 48. O número está afirmado porque a altura do cabeçalho e a do rodapé já
      // voltaram três vezes; medir é o que impede a quarta.
      expect(
        campo.bottom,
        lessThanOrEqualTo(48),
        reason:
            'o cabeçalho voltou a crescer: a busca termina em ${campo.bottom}',
      );
    });

    testWidgets('o botão de chat leva a uma tela que admite não existir', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Mensagens'));

      // Vazio honesto, não um protótipo de conversa com dados inventados: o botão
      // está no lugar definitivo para não mudar de posição quando o serviço
      // chegar, e a tela diz o que falta.
      expect(find.text('As mensagens ainda não existem'), findsOne);
    });

    testWidgets('recolhe ao rolar para baixo e volta ao rolar para cima', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);

      // Posts suficientes para a lista ser mais alta que a janela do teste.
      for (var i = 0; i < 12; i++) {
        await tocar(tester, find.byIcon(LucideIcons.squarePen));
        await tester.enterText(
          find.byType(EditableText).first,
          'Comunicado número $i',
        );
        await tester.pumpAndSettle();
        await tocar(tester, find.text('Publicar'));
      }

      final busca = find.bySemanticsLabel(
        'Buscar universidades, empresas e pessoas',
      );
      expect(busca, findsOne);

      // Rolar para baixo leva o cabeçalho embora.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(busca, findsNothing);

      // E **qualquer** rolagem para cima o traz de volta inteiro, sem precisar
      // voltar ao topo da lista — é o `snap` do LinkedIn e do Instagram.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(busca, findsOne);
    });
  });

  group('publicação', () {
    // Dois testes e não um: `bombearApp` chama `pumpWidget`, e chamá-lo duas vezes
    // no mesmo caso reconstrói a árvore sobre o estado do anterior.
    testWidgets('o aluno não vê o botão de escrever', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      expect(find.byIcon(LucideIcons.squarePen), findsNothing);
    });

    testWidgets('a faculdade ativada vê o botão de escrever', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);

      expect(find.byIcon(LucideIcons.squarePen), findsOne);
    });

    testWidgets('a conta pendente não vê o botão de escrever', (tester) async {
      // Oferecer uma ação que o servidor vai recusar é pior que não oferecer: o
      // aviso de análise está no perfil dela.
      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresa);

      expect(find.byIcon(LucideIcons.squarePen), findsNothing);
    });

    testWidgets('publicar restrito a curso exige escolher o curso', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await tocar(tester, find.byIcon(LucideIcons.squarePen));

      await tester.enterText(
        find.byType(EditableText).first,
        'Aviso para o pessoal de ADS',
      );
      await tester.pumpAndSettle();

      // `institucional` é a pré-seleção do formulário — o servidor não tem default,
      // porque um default do lado dele faria uma chamada malformada publicar com
      // alcance que ninguém escolheu.
      expect(find.text('Institucional'), findsWidgets);

      await tocar(tester, find.text('Institucional').first);
      await tocar(tester, find.text('Restrito a curso').last);

      await tocar(tester, find.text('Publicar'));

      expect(
        find.text('Escolha o curso a que o comunicado fica restrito'),
        findsOne,
      );
    });

    testWidgets('o comunicado publicado aparece no feed', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await tocar(tester, find.byIcon(LucideIcons.squarePen));

      await tester.enterText(
        find.byType(EditableText).first,
        'Matrículas abertas na secretaria',
      );
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Publicar'));

      // Volta ao feed, que recarrega: sem invalidar o provider, o comunicado só
      // apareceria na próxima abertura do app.
      expect(find.textContaining('Matrículas abertas'), findsOne);
    });
  });

  group('post e comentários', () {
    testWidgets('abrir o comunicado mostra a conversa e aceita comentar', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.textContaining('biblioteca funcionará'));

      expect(find.text('Comunicado'), findsOne);
      expect(find.text('Ninguém comentou ainda.'), findsOne);

      await tester.enterText(
        find.byType(EditableText).last,
        'Obrigada pelo aviso',
      );
      await tester.pumpAndSettle();
      await tocar(tester, find.byIcon(LucideIcons.send));

      expect(find.text('Obrigada pelo aviso'), findsOne);
      expect(find.text('1 comentário'), findsOne);
    });

    testWidgets('curtir atualiza a contagem sem recarregar a lista', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);

      final coracao = find.byIcon(LucideIcons.heart).first;
      await tocar(tester, coracao);

      // O ícone troca e o número sobe: a tela relê o post em vez de somar 1
      // localmente, porque com duas pessoas curtindo a conta local fica errada.
      expect(find.byIcon(LucideIcons.heartHandshake), findsOne);
    });
  });
}
