import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/features/jobs/data/models/vaga.dart';
import 'package:integra/features/profile/data/fixtures.dart';

import '../../../helpers/bombear_app.dart';

/// A área de vagas pelo app, contra os falsos.
///
/// O teste que importa é o primeiro: **o portão da Sprint 5 atravessado pelas telas**.
/// O portão do backend (`services/jobs/tests`) prova que as rotas se encaixam; este
/// prova que as telas leram o contrato igual — que é o que o débito 1 do plano cobra do
/// lado do cliente.
///
/// O que ele **não** prova é a costura contra o serviço real: os dois lados continuam
/// sendo verificados separadamente, e fechar isso exige subir a stack e repetir com
/// `--dart-define=API_BASE_URL`. É o que `infra/portao_profissional.py` faz pelo
/// servidor.
void main() {
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> abrirVagas(WidgetTester tester) async {
    await tocar(tester, find.byTooltip('Profissional'));
    await tocar(tester, find.byTooltip('Vagas'));
  }

  group('o portão da Sprint 5', () {
    testWidgets('empresa publica, aluno se candidata, empresa vê', (
      tester,
    ) async {
      // ── 1. a empresa publica
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailEmpresaAtiva,
      );
      await abrirVagas(tester);
      await tocar(tester, find.byTooltip('Nova vaga'));

      await tester.enterText(
        find.byType(ShadInput).first,
        'Estágio em QA',
      );
      await tester.enterText(
        find.byType(ShadTextarea).first,
        'Escrever e manter os testes de uma API em Python.',
      );
      await tocar(tester, find.text('Remoto'));
      await tocar(tester, find.widgetWithText(ShadButton, 'Publicar vaga'));

      final publicada = banco.vagas.firstWhere((v) => v.titulo == 'Estágio em QA');
      expect(publicada.empresaId, Fixtures.perfilEmpresaAtiva.id);
      // Remoto **limpa** o local. A invariante é do banco e do serviço, nos dois
      // sentidos — e o formulário nem mostra o campo.
      expect(publicada.local, isNull);
      expect(publicada.estado, EstadoDaVaga.aberta);

      // ── 2. o aluno se candidata, na mesma sessão de teste e no mesmo banco
      banco.usuarioAtualId = Fixtures.perfilDemo.id;
      await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
        banco: banco,
      );
      await abrirVagas(tester);
      await tocar(tester, find.text('Estágio em QA'));

      expect(find.widgetWithText(ShadButton, 'Candidatar-se'), findsOne);
      await tocar(tester, find.widgetWithText(ShadButton, 'Candidatar-se'));

      final candidatura = banco.candidaturaDe(
        publicada.id,
        Fixtures.perfilDemo.id,
      );
      expect(candidatura, isNotNull);
      expect(candidatura!.estado, EstadoDaCandidatura.enviada);
      // O botão sai de cena e o estado toma o lugar dele: a tela não oferece uma
      // ação que o servidor recusaria.
      expect(find.widgetWithText(ShadButton, 'Candidatar-se'), findsNothing);
      expect(find.text('Candidatura enviada'), findsOne);

      // ── 3. a empresa vê a candidatura
      banco.usuarioAtualId = Fixtures.perfilEmpresaAtiva.id;
      await bombearAppAutenticado(
        tester,
        email: Fixtures.emailEmpresaAtiva,
        banco: banco,
      );
      await abrirVagas(tester);
      await tocar(tester, find.text('Estágio em QA'));

      expect(find.text('Quem se candidatou'), findsOne);
      expect(find.text(Fixtures.perfilDemo.nomeCompleto), findsOne);
      // Listar **não** marca como visualizada: a transição é um toque explícito.
      expect(banco.candidaturaPorId(candidatura.id)!.estado,
          EstadoDaCandidatura.enviada);

      await tocar(
        tester,
        find.widgetWithText(ShadButton, 'Marcar como visualizada'),
      );
      expect(
        banco.candidaturaPorId(candidatura.id)!.estado,
        EstadoDaCandidatura.visualizada,
      );
    });
  });

  group('quem pode o quê', () {
    testWidgets('o aluno não vê o botão de publicar vaga', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirVagas(tester);

      expect(find.byTooltip('Nova vaga'), findsNothing);
    });

    testWidgets('a empresa autora não se candidata: vê quem se candidatou', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresaAtiva);
      await abrirVagas(tester);
      // A própria empresa publicou as vagas semeadas: para ela, o que aparece é a
      // contagem de candidaturas, não um botão.
      await tocar(tester, find.text('Estágio em desenvolvimento back-end'));

      expect(find.widgetWithText(ShadButton, 'Candidatar-se'), findsNothing);
      expect(find.text('Quem se candidatou'), findsOne);
    });

    testWidgets('a faculdade lê a vaga mas não se candidata', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirVagas(tester);
      await tocar(tester, find.text('Estágio em desenvolvimento back-end'));

      // Nem botão nem contagem: ela não é a autora e não é aluna. A tela explica em
      // vez de mostrar um botão desabilitado sem motivo.
      expect(find.text('Só alunos se candidatam'), findsOne);
    });
  });

  group('vaga encerrada', () {
    testWidgets('sai da listagem e continua legível por id', (tester) async {
      // A terceira vaga semeada nasce encerrada, e é para este caso que ela existe.
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await abrirVagas(tester);

      expect(find.text('Trainee em produto'), findsNothing);

      // Alcançada por id: é o caminho de quem chega por "minhas candidaturas".
      final fechada = banco.vagas.firstWhere(
        (v) => v.estado == EstadoDaVaga.fechada,
      );
      expect(fechada.titulo, 'Trainee em produto');
    });

    testWidgets('o filtro de encerradas é só da empresa', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirVagas(tester);
      expect(find.widgetWithText(ShadButton, 'Encerradas'), findsNothing);

      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresa);
      await abrirVagas(tester);
      expect(find.widgetWithText(ShadButton, 'Encerradas'), findsOne);

      // Ligar o filtro troca a lista: uma vaga encerrada aparece, as abertas somem.
      await tocar(tester, find.widgetWithText(ShadButton, 'Encerradas'));
      expect(find.text('Trainee em produto'), findsOne);
      expect(find.text('Estágio em desenvolvimento back-end'), findsNothing);
    });
  });

  group('filtros', () {
    testWidgets('o filtro de tipo estreita a lista e o vazio o admite', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirVagas(tester);

      expect(find.text('Estágio em desenvolvimento back-end'), findsOne);
      expect(find.text('Analista de dados júnior'), findsOne);

      await tocar(tester, find.widgetWithText(ShadButton, 'Tipo'));
      // "Júnior" aparece também na etiqueta do card, então o toque tem que ser no
      // item do menu — `find.text` sozinho é ambíguo.
      await tocar(
        tester,
        find.descendant(
          of: find.byType(MenuItemButton),
          matching: find.text('Júnior'),
        ),
      );

      expect(find.text('Estágio em desenvolvimento back-end'), findsNothing);
      expect(find.text('Analista de dados júnior'), findsOne);
    });

    testWidgets('com filtro ativo, o vazio é do filtro e não da área', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirVagas(tester);

      // Trainee só existe encerrado, e o filtro padrão lista abertas.
      await tocar(tester, find.widgetWithText(ShadButton, 'Tipo'));
      await tocar(
        tester,
        find.descendant(
          of: find.byType(MenuItemButton),
          matching: find.text('Trainee'),
        ),
      );

      // Dizer "nenhuma vaga publicada" aqui seria mentir: há vagas, nenhuma casa.
      expect(find.text('Nenhuma vaga com esses filtros'), findsOne);
      await tocar(tester, find.widgetWithText(ShadButton, 'Limpar filtros'));
      expect(find.text('Estágio em desenvolvimento back-end'), findsOne);
    });
  });

  group('minhas candidaturas', () {
    testWidgets('a aba existe para o aluno e não para a empresa', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await tocar(tester, find.byTooltip('Profissional'));
      expect(find.byTooltip('Minhas candidaturas'), findsOne);

      // Empresa não se candidata a nada, e uma aba vazia por definição é pior que
      // aba nenhuma — a mesma regra que tirou o currículo do perfil institucional.
      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresa);
      await tocar(tester, find.byTooltip('Profissional'));
      expect(find.byTooltip('Minhas candidaturas'), findsNothing);
    });

    testWidgets('mostra a vaga inteira, e o estado muda quando a empresa vê', (
      tester,
    ) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await abrirVagas(tester);
      await tocar(tester, find.text('Estágio em desenvolvimento back-end'));
      await tocar(tester, find.widgetWithText(ShadButton, 'Candidatar-se'));

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tocar(tester, find.byTooltip('Minhas candidaturas'));

      // A lista é de "onde me candidatei": sem o título da vaga, a linha não é
      // legível.
      expect(find.text('Estágio em desenvolvimento back-end'), findsOne);
      expect(find.text('Enviada'), findsOne);

      // A empresa abre, e o aluno enxerga a mudança. É o que faz o estado existir.
      final candidatura = banco.candidaturas.first;
      candidatura.estado = EstadoDaCandidatura.visualizada;
      candidatura.visualizadaEm = DateTime.now();

      await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
        banco: banco,
      );
      await tocar(tester, find.byTooltip('Profissional'));
      await tocar(tester, find.byTooltip('Minhas candidaturas'));
      expect(find.text('Visualizada'), findsOne);
    });
  });
}
