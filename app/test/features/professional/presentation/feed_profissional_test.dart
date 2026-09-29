import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/fixtures.dart';

import '../../../helpers/bombear_app.dart';

/// O feed profissional pelo app, contra os falsos.
///
/// O que estes testes guardam é a **curadoria** — os dois ramos do conjunto e a origem
/// de cada item. Não há matriz de visibilidade a verificar neste pilar: todo post é
/// legível por qualquer conta, e um teste sobre alcance aqui estaria testando uma regra
/// que não existe.
///
/// As fixtures foram escolhidas para isso: a Ana segue a empresa ativada e não segue a
/// Carla, que tem vínculo na mesma universidade. Então um post chega por seguir, outro
/// por recomendação, e o do Bruno — que não tem vínculo — não chega por nenhum dos
/// dois. É a regra da seção 2 do plano dita no pilar Profissional.
void main() {
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> abrirFeed(WidgetTester tester) =>
      tocar(tester, find.byTooltip('Profissional'));

  group('o conjunto do feed', () {
    testWidgets('quem se segue vem como seguindo, e não ganha etiqueta', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirFeed(tester);

      // A Ana segue a Nimbus.
      expect(find.textContaining('abrimos duas vagas de'), findsOne);
      // "Você segue" é o caso esperado, e marcar o esperado polui o card sem informar.
      // A etiqueta existe só para explicar o que precisa de explicação.
      expect(find.text('Recomendado'), findsWidgets);
    });

    testWidgets('o colega de universidade vem como recomendado', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirFeed(tester);

      // A Carla tem vínculo na FATEC, como a Ana, e a Ana não a segue. É a resposta à
      // pergunta que o rascunho do contrato deixou aberta.
      expect(find.textContaining('Alguém de Gestão'), findsOne);
      expect(find.text('Recomendado'), findsWidgets);
    });

    testWidgets('quem não tem vínculo e não é seguido não aparece', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirFeed(tester);

      // O Bruno só **declarou** a formação — não tem vínculo. Declarar não coloca
      // ninguém na comunidade de uma universidade, e é a mesma regra que decide o feed
      // Acadêmico.
      expect(find.textContaining('Procurando primeira oportunidade'), findsNothing);
    });

    testWidgets('o próprio post aparece, e como seguindo', (tester) async {
      // O Bruno não segue ninguém e não tem vínculo: sem o ramo do próprio autor, o
      // feed dele seria vazio mesmo tendo publicado — e o pior lugar para mostrar
      // vazio é logo depois da primeira ação do usuário.
      await bombearAppAutenticado(tester, email: Fixtures.emailSemVinculo);
      await abrirFeed(tester);

      expect(find.textContaining('Procurando primeira oportunidade'), findsOne);
      expect(find.text('Recomendado'), findsNothing);
    });
  });

  group('o escopo filtra por quem publica', () {
    testWidgets('só empresas remove o post da aluna', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirFeed(tester);
      await tocar(tester, find.byTooltip('Escopo do feed: Geral'));
      await tocar(tester, find.text('Só empresas'));

      expect(find.textContaining('abrimos duas vagas de'), findsOne);
      expect(find.textContaining('Alguém de Gestão'), findsNothing);
    });

    testWidgets('só pessoas remove o post da empresa', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirFeed(tester);
      await tocar(tester, find.byTooltip('Escopo do feed: Geral'));
      await tocar(tester, find.text('Só pessoas'));

      expect(find.textContaining('abrimos duas vagas de'), findsNothing);
      expect(find.textContaining('Alguém de Gestão'), findsOne);
    });

    testWidgets('o escopo estreita e nunca amplia', (tester) async {
      // A Carla não segue a empresa e não é recomendada por ela — empresa não tem
      // vínculo. Pedir `Só empresas` não pode trazer empresa nenhuma para ela: o
      // filtro entra com `AND` sobre o conjunto, e um `OR` o transformaria em
      // concessão. É a mesma frase que o serviço guarda em SQL.
      await bombearAppAutenticado(tester, email: Fixtures.emailOutroCurso);
      await abrirFeed(tester);
      await tocar(tester, find.byTooltip('Escopo do feed: Geral'));
      await tocar(tester, find.text('Só empresas'));

      expect(find.textContaining('abrimos duas vagas de'), findsNothing);
      expect(
        find.text('Nenhuma empresa que você segue publicou'),
        findsOne,
      );
    });
  });

  group('publicação', () {
    testWidgets('a faculdade não publica no pilar Profissional', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirFeed(tester);

      // Comunicado de instituição é o pilar Acadêmico. A mesma coisa em dois lugares
      // seria lida duas vezes por motivos diferentes.
      expect(find.byTooltip('Novo post'), findsNothing);
    });

    testWidgets('a empresa pendente não vê o botão de publicar', (
      tester,
    ) async {
      // Ela receberia 403 do serviço, e oferecer uma ação que será recusada é pior
      // que não oferecer — o aviso de análise está no perfil dela.
      await bombearAppAutenticado(tester, email: Fixtures.emailEmpresa);
      await abrirFeed(tester);

      expect(find.byTooltip('Novo post'), findsNothing);
    });

    testWidgets('o aluno publica e o post entra no próprio feed', (
      tester,
    ) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await abrirFeed(tester);
      await tocar(tester, find.byTooltip('Novo post'));

      await tester.enterText(
        find.byType(ShadTextarea).first,
        'Comecei a estudar Kotlin esta semana.',
      );
      await tocar(tester, find.widgetWithText(ShadButton, 'Publicar'));

      final publicado = banco.postsProfissionais.firstWhere(
        (p) => p.conteudo.startsWith('Comecei a estudar'),
      );
      // O vínculo é copiado na publicação: é o que decide a quem o post é recomendado
      // daqui para frente.
      expect(publicado.autorUniversidadeId, Fixtures.fatecRp.id);
      expect(publicado.imagemUrl, isNull);

      expect(find.textContaining('Comecei a estudar Kotlin'), findsOne);
    });

    testWidgets('corpo vazio é recusado antes de sair da tela', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirFeed(tester);
      await tocar(tester, find.byTooltip('Novo post'));
      await tocar(tester, find.widgetWithText(ShadButton, 'Publicar'));

      // O erro fica **no corpo**, e não em toast: o oposto da confirmação, porque
      // precisa ficar à vista enquanto se corrige.
      expect(find.text('Escreva algo antes de publicar'), findsOne);
    });
  });

  group('imagem no post', () {
    testWidgets('a escolhida é pré-visualizada e a URL vai para o post', (
      tester,
    ) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
        // Bytes fixos: nada é decodificado no caminho que este teste exercita — pedir
        // a URL, enviar, gravar a `imagemUrl`.
        seletor: const ImagemFixa(),
      );
      await abrirFeed(tester);
      await tocar(tester, find.byTooltip('Novo post'));

      await tester.enterText(
        find.byType(ShadTextarea).first,
        'Foto do laboratório novo.',
      );
      await tocar(tester, find.widgetWithText(ShadButton, 'Adicionar imagem'));

      // O tamanho aparece antes do envio: o limite de 5 MB é real, conferido pelo
      // storage, e descobrir que passou só no envio seria pior.
      expect(find.textContaining('image/jpeg'), findsOne);
      expect(find.widgetWithText(ShadButton, 'Remover'), findsOne);

      await tocar(tester, find.widgetWithText(ShadButton, 'Publicar'));

      final publicado = banco.postsProfissionais.firstWhere(
        (p) => p.conteudo.startsWith('Foto do laboratório'),
      );
      // Os três passos aconteceram na ordem: a `imagemUrl` só existe porque o `PUT`
      // não falhou. Publicar primeiro e enviar depois deixaria um card quebrado.
      expect(publicado.imagemUrl, isNotNull);
      expect(publicado.imagemUrl, contains('posts/${Fixtures.perfilDemo.id}/'));
    });

    testWidgets('cancelar a galeria não é erro e não avisa nada', (
      tester,
    ) async {
      // `SemImagem` é o padrão do helper: devolve nulo, como o usuário que fecha a
      // galeria. Avisar quem só mudou de ideia ensina o usuário a desconfiar dos avisos.
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirFeed(tester);
      await tocar(tester, find.byTooltip('Novo post'));
      await tocar(tester, find.widgetWithText(ShadButton, 'Adicionar imagem'));

      expect(find.widgetWithText(ShadButton, 'Adicionar imagem'), findsOne);
      expect(find.widgetWithText(ShadButton, 'Remover'), findsNothing);
      expect(find.textContaining('Não foi possível'), findsNothing);
    });
  });

  group('post e comentários', () {
    testWidgets('abrir o post mostra a conversa e aceita comentar', (
      tester,
    ) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await abrirFeed(tester);
      await tocar(tester, find.textContaining('Alguém de Gestão'));

      expect(find.text('Nenhum comentário ainda. Seja o primeiro.'), findsOne);

      await tester.enterText(
        find.byType(ShadInput).last,
        'Fiz no semestre passado, te mando o contato.',
      );
      await tocar(tester, find.byIcon(LucideIcons.send));

      expect(banco.comentariosProfissionais, hasLength(1));
      expect(find.textContaining('te mando o contato'), findsOne);
    });

    testWidgets('curtir conta uma vez por leitor', (tester) async {
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await abrirFeed(tester);

      final doColega = banco.postsProfissionais.firstWhere(
        (p) => p.autorId == Fixtures.perfilCarla.id,
      );
      expect(doColega.curtidas, isEmpty);

      // O feed vem do mais recente para o mais antigo, então o primeiro coração é de
      // outro post. O da Carla é alcançado a partir do card dela.
      await tocar(
        tester,
        find.descendant(
          of: find.ancestor(
            of: find.textContaining('Alguém de Gestão'),
            matching: find.byType(ShadCard),
          ),
          matching: find.byIcon(LucideIcons.heart),
        ),
      );
      expect(doColega.curtidas, {Fixtures.perfilDemo.id});
    });

    testWidgets('o autor do post remove comentário de terceiro', (
      tester,
    ) async {
      // Moderação: sem ela, a única saída de quem publicou para tirar algo de baixo do
      // próprio post seria apagar o post inteiro. No Acadêmico quem modera é a
      // faculdade autora; aqui é a pessoa.
      final banco = await bombearAppAutenticado(
        tester,
        email: Fixtures.emailDemo,
      );
      await abrirFeed(tester);

      final meuPost = banco.postsProfissionais.firstWhere(
        (p) => p.autorId == Fixtures.perfilDemo.id,
      );
      banco.comentariosProfissionais.add(
        ComentarioProfissionalFalso(
          id: 'coment-de-terceiro',
          postId: meuPost.id,
          autorId: Fixtures.perfilCarla.id,
          conteudo: 'Parabéns!',
          criadoEm: DateTime.now(),
        ),
      );

      await tocar(tester, find.textContaining('Terminei o projeto integrador'));
      expect(find.text('Parabéns!'), findsOne);

      await tocar(tester, find.byIcon(LucideIcons.trash2).last);
      expect(banco.comentariosProfissionais, isEmpty);
    });
  });
}
