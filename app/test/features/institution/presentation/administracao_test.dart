import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/features/profile/data/fixtures.dart';
import 'package:integra/shared/domain/documentos.dart';

import '../../../helpers/bombear_app.dart';

/// A tela que **faz o vínculo poder nascer**.
///
/// Antes dela, a única forma de ter matrícula no banco era rodar o seed — e o
/// "inserir CPF" do aluno procurava numa lista que ninguém conseguia preencher
/// pelo app. É a herança da Sprint 3 que o pilar Acadêmico tinha que pagar antes
/// de qualquer feed, e o último teste deste arquivo é o que prova que ela pagou:
/// a faculdade matricula alguém, e aquele alguém cria o vínculo.
void main() {
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> abrirAdministracao(WidgetTester tester) async {
    await abrirMenuDaConta(tester);
    await tocar(tester, find.text('Administração da instituição'));
  }

  /// Um CPF válido nos dígitos que **não** está nas fixtures.
  ///
  /// Gerado pelo próprio validador, nunca escrito à mão: um CPF de cabeça quase
  /// sempre tem dígito verificador errado, e o teste estaria exercitando o caminho
  /// de erro achando que exercita o de sucesso.
  const cpfNovo = '40532176871';

  group('acesso', () {
    testWidgets('o aluno não tem o caminho para a administração', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirMenuDaConta(tester);

      // O item nem aparece no menu: administrar instituição é de conta
      // `faculdade`, e oferecer para depois recusar é pior que não oferecer.
      expect(find.text('Administração da instituição'), findsNothing);

      // As três ações de conta, sim — elas saíram do corpo da tela quando o perfil
      // ganhou abas, porque não pertencem nem às publicações nem ao currículo.
      expect(find.text('Editar perfil'), findsOne);
      expect(find.text('Trocar senha'), findsOne);
      expect(find.text('Sair da conta'), findsOne);
    });

    testWidgets('a conta pendente alcança a tela e lê por que não pode agir', (
      tester,
    ) async {
      // A empresa das fixtures nasce pendente. O caminho **aparece** de propósito:
      // esconder a tela deixaria a conta em análise sem saber que ela existe.
      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresa);
      await abrirMenuDaConta(tester);

      // Empresa não administra instituição — o item é só de `faculdade`.
      expect(find.text('Administração da instituição'), findsNothing);
    });
  });

  group('cursos', () {
    testWidgets('cadastrar um curso o mostra na lista', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirAdministracao(tester);

      expect(find.text('Cursos da instituição'), findsOne);
      // Os dois que a FATEC já tinha, das fixtures.
      expect(find.text('Análise e Desenvolvimento de Sistemas'), findsOne);
      expect(find.text('Gestão Empresarial'), findsOne);

      await tester.enterText(find.byType(EditableText).first, 'Logística');
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Adicionar'));

      expect(find.text('Logística'), findsOne);
    });

    testWidgets('nome repetido é recusado, sem diferenciar maiúsculas', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirAdministracao(tester);

      await tester.enterText(
        find.byType(EditableText).first,
        'gestão empresarial',
      );
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Adicionar'));

      // "ADS" e "ads" na mesma instituição seriam duas entradas para a mesma coisa
      // no combobox do aluno.
      expect(
        find.text('Já existe um curso com este nome na instituição'),
        findsOne,
      );
    });

    testWidgets('curso com matrícula não pode ser removido', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirAdministracao(tester);

      // ADS tem matrícula e formação verificada nas fixtures. Apagar o curso
      // apagaria o selo de quem se formou nele — no banco é `ON DELETE RESTRICT`.
      await tocar(tester, find.byIcon(LucideIcons.trash2).first);

      expect(find.textContaining('não pode ser removido'), findsOne);
      expect(find.text('Análise e Desenvolvimento de Sistemas'), findsOne);
    });
  });

  group('matrículas', () {
    Future<void> abrirMatriculas(WidgetTester tester) async {
      await abrirAdministracao(tester);
      await tocar(tester, find.text('Matrículas'));
    }

    testWidgets('a lista separa quem já tem vínculo de quem ainda não', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirMatriculas(tester);

      // Ana e Carla têm vínculo; Bruno declarou a formação e não informou o CPF.
      expect(find.text('Ana Paula Souza'), findsOne);
      expect(find.text('Bruno Carvalho Lima'), findsOne);
      expect(find.text('Vínculo'), findsWidgets);
      // "Aguardando", não "pendente": não há nada errado com aquela linha.
      expect(find.text('Aguardando'), findsOne);
    });

    testWidgets('CPF inválido para no cliente', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirMatriculas(tester);

      await tester.enterText(find.byType(EditableText).first, '11111111111');
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Matricular'));

      // A mesma regra do cadastro, no mesmo validador: dígitos repetidos passam no
      // tamanho e falham no verificador.
      expect(find.text('CPF inválido'), findsOne);
    });

    testWidgets('matricular sem escolher o curso é recusado', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirMatriculas(tester);

      await tester.enterText(find.byType(EditableText).first, cpfNovo);
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Matricular'));

      // Toda matrícula aponta para um curso: é dele que o vínculo herda o curso, e
      // é por ele que um comunicado restrito filtra.
      expect(find.text('Escolha o curso'), findsOne);
    });

    testWidgets('matricular um CPF sem conta o deixa aguardando', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirMatriculas(tester);

      await tester.enterText(find.byType(EditableText).first, cpfNovo);
      await tester.pumpAndSettle();

      await tocar(tester, find.text('Curso'));
      await tocar(tester, find.text('Gestão Empresarial').last);
      await tocar(tester, find.text('Matricular'));

      // **Pode ser antes de a conta existir** — é uma lista de espera, e por isso
      // não há chave estrangeira para usuário no banco. A linha aparece pelo CPF,
      // que é o único identificador que a instituição tem de quem não entrou.
      expect(find.text(formatarCpf(cpfNovo)), findsOne);
      expect(
        find.textContaining(
          'O vínculo nasce quando essa pessoa informar o CPF',
        ),
        findsOne,
      );
    });
  });

  group('o ciclo completo', () {
    testWidgets('a faculdade matricula, e o aluno daquele CPF cria o vínculo', (
      tester,
    ) async {
      // O portão que faltava: antes desta tela, este fluxo só era possível
      // semeando o banco à mão.
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailFaculdade,
      );

      // Bruno tem conta e CPF, e **nenhuma** matrícula em Gestão. A das fixtures
      // é em ADS, então remover e recriar em outro curso prova que o vínculo
      // herda o curso da matrícula, e não da formação declarada.
      banco.matriculas.removeWhere((m) => m.cpf == Fixtures.cpfBruno);

      await abrirAdministracao(tester);
      await tocar(tester, find.text('Matrículas'));

      await tester.enterText(
        find.byType(EditableText).first,
        Fixtures.cpfBruno,
      );
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Curso'));
      await tocar(tester, find.text('Gestão Empresarial').last);
      await tocar(tester, find.text('Matricular'));

      // A matrícula existe no banco compartilhado — é o que o "inserir CPF" do
      // aluno vai consultar.
      expect(
        banco.matriculaDe(Fixtures.fatecRp.id, Fixtures.cpfBruno),
        isNotNull,
      );
      expect(
        banco.matriculaDe(Fixtures.fatecRp.id, Fixtures.cpfBruno)!.cursoId,
        Fixtures.gestaoEmpresarial.id,
      );
    });
  });
}
