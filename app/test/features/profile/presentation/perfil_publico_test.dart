import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/features/profile/data/fixtures.dart';

import '../../../helpers/bombear_app.dart';

/// O perfil visto de fora, e a conta `empresa` vista por dentro.
///
/// Cinco mudanças de alinhamento depois da Sprint 5, e cada grupo aqui é uma:
///
/// 1. **empresa não tem pilar Acadêmico** — nem aba no rodapé, nem rota alcançável;
/// 2. **o perfil da empresa tem posts e vagas**, no lugar de uma frase sobre uma
///    instituição que ela não tem;
/// 3. **o perfil de outra conta é alcançável** pelo feed, pela busca e por uma
///    candidatura;
/// 4. **dá para seguir pessoas e empresas**, e não só universidades;
/// 5. os filtros de vaga saíram para o cabeçalho — esse está em `vagas_test.dart`,
///    junto do resto da área de vagas.
void main() {
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  group('empresa e o pilar Acadêmico', () {
    testWidgets('a conta empresa não tem a aba, e abre no Profissional', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresaAtiva);

      // Empresa não tem vínculo com instituição nenhuma: não existe comunicado
      // dirigido a ela, e a aba levaria a um feed que nunca é dela.
      expect(find.byTooltip('Acadêmico'), findsNothing);

      // As outras três continuam, e ela abre o app já no pilar que é dela.
      expect(find.byTooltip('Profissional'), findsOne);
      expect(find.byTooltip('Publicar'), findsOne);
      expect(find.byTooltip('Perfil'), findsOne);
      expect(find.byTooltip('Feed profissional'), findsOne);
    });

    testWidgets('o aluno continua com a aba', (tester) async {
      // O contraponto: o item some por tipo de conta, e não do rodapé inteiro.
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      expect(find.byTooltip('Acadêmico'), findsOne);
    });
  });

  group('o perfil da empresa', () {
    testWidgets('tem publicações e vagas, e nenhuma frase sobre instituição', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresaAtiva);
      await tocar(tester, find.byTooltip('Perfil'));

      // **O que saiu:** a frase apontava para o perfil público de uma instituição, e
      // uma empresa não administra nenhuma — ela mandava o usuário para uma página
      // que não existe. Fica só para a conta `faculdade`, onde é verdade.
      expect(
        find.text('Seus comunicados ficam no perfil da instituição'),
        findsNothing,
      );

      expect(find.byTooltip('Publicações'), findsOne);
      // Organização não estuda em lugar nenhum: a aba de currículo continua fora.
      expect(find.byTooltip('Currículo'), findsNothing);

      // A aba aberta é a de publicações, com o post dela.
      expect(find.textContaining('Estamos crescendo o time'), findsOne);
    });

    testWidgets('a aba de vagas mostra as abertas e as encerradas', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresaAtiva);
      await tocar(tester, find.byTooltip('Perfil'));
      await tocar(
        tester,
        find.descendant(
          of: find.byType(SliverPersistentHeader),
          matching: find.byTooltip('Vagas'),
        ),
      );

      expect(find.text('Estágio em desenvolvimento back-end'), findsOne);
      expect(find.text('Analista de dados júnior'), findsOne);

      // **A diferença entre esta aba e a área de vagas.** Lá a lista é das abertas,
      // porque uma vaga encerrada é um beco para quem procura trabalho; aqui a
      // pergunta é "o que eu publiquei", e o histórico é parte da resposta.
      expect(find.text('Trainee em produto'), findsOne);
      expect(find.text('Encerrada'), findsOne);
    });
  });

  group('o perfil de outra conta', () {
    testWidgets('o feed profissional leva ao perfil do autor', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Profissional'));

      // A Carla tem vínculo na mesma universidade da Ana: o post dela entra no feed
      // por recomendação. Tocar no nome era um gesto que não levava a lugar nenhum.
      await tocar(tester, find.text(Fixtures.perfilCarla.nomeCompleto));

      expect(find.byTooltip('Currículo'), findsOne);
      // No perfil de outra pessoa o canto direito volta a ser o chat: ali a ação é
      // falar com quem se está vendo, e não administrar a própria conta.
      expect(find.byTooltip('Opções da conta'), findsNothing);
      expect(find.byTooltip('Mensagens'), findsOne);
    });

    testWidgets('a busca leva ao perfil da pessoa', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      // O campo do cabeçalho é um botão com cara de campo: tocar nele abre a tela de
      // busca com o foco já no input.
      await tocar(tester, find.text('Buscar'));

      await tester.enterText(find.byType(ShadInput).first, 'Carla');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tocar(tester, find.text(Fixtures.perfilCarla.nomeCompleto));

      // A linha da universidade já levava ao perfil dela; a da pessoa parava na
      // lista, o que faz a busca parecer um resultado e não um caminho.
      expect(find.byTooltip('Publicações'), findsOne);
      expect(find.text('@${Fixtures.perfilCarla.username}'), findsWidgets);
    });

    testWidgets('a empresa toca no candidato e cai no perfil dele', (
      tester,
    ) async {
      // O caminho só existe depois de alguém se candidatar, então as duas contas
      // passam pelo mesmo banco — como no portão da Sprint 5.
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await tocar(tester, find.byTooltip('Profissional'));
      await tocar(tester, find.byTooltip('Vagas'));
      await tocar(tester, find.text('Estágio em desenvolvimento back-end'));
      await tocar(tester, find.widgetWithText(ShadButton, 'Candidatar-se'));

      await bombearAppAutenticado(
        tester,
        email: Fixtures.emailEmpresaAtiva,
        banco: banco,
      );
      await tocar(tester, find.byTooltip('Vagas'));
      await tocar(tester, find.text('Estágio em desenvolvimento back-end'));
      expect(find.text('Quem se candidatou'), findsOne);

      await tocar(tester, find.text(Fixtures.perfilDemo.nomeCompleto));

      // **O toque segue o assunto do card.** Na lista da empresa o assunto é a
      // pessoa, e voltar para a mesma vaga seria um toque que não leva a nada. O
      // currículo está aqui, e é o que a candidatura deliberadamente não traz.
      expect(find.byTooltip('Currículo'), findsOne);
      expect(find.widgetWithText(ShadButton, 'Seguir'), findsOne);
    });
  });

  group('seguir pessoas e empresas', () {
    testWidgets('o aluno segue outro aluno, e o botão troca', (tester) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await tocar(tester, find.byTooltip('Profissional'));
      await tocar(tester, find.text(Fixtures.perfilCarla.nomeCompleto));

      await tocar(tester, find.widgetWithText(ShadButton, 'Seguir'));

      // Gravou de verdade: o conjunto do feed profissional é "quem eu sigo" mais
      // "quem me é recomendado", e é esta lista que o alimenta.
      expect(
        banco.seguindoUsuarios[Fixtures.perfilDemo.id],
        contains(Fixtures.perfilCarla.id),
      );
      expect(find.widgetWithText(ShadButton, 'Seguindo'), findsOne);

      // E desfaz no mesmo lugar.
      await tocar(tester, find.widgetWithText(ShadButton, 'Seguindo'));
      expect(
        banco.seguindoUsuarios[Fixtures.perfilDemo.id],
        isNot(contains(Fixtures.perfilCarla.id)),
      );
    });

    testWidgets('quem já é seguido abre em "Seguindo"', (tester) async {
      // A Ana segue a Nimbus nas fixtures — é o que faz o post de empresa aparecer
      // no feed dela e não no da Carla.
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Profissional'));
      await tocar(tester, find.text(Fixtures.perfilEmpresaAtiva.nomeCompleto));

      expect(find.widgetWithText(ShadButton, 'Seguindo'), findsOne);
      expect(find.widgetWithText(ShadButton, 'Seguir'), findsNothing);
    });

    testWidgets('o próprio perfil não oferece seguir', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Perfil'));

      // Seguir a si mesmo é 409 no serviço. A tela não chega lá: no próprio perfil o
      // canto direito é o menu da conta, e não há botão.
      expect(find.widgetWithText(ShadButton, 'Seguir'), findsNothing);
      expect(find.byTooltip('Opções da conta'), findsOne);
    });
  });
}
