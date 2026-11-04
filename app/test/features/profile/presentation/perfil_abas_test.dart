import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/features/profile/data/fixtures.dart';

import '../../../helpers/bombear_app.dart';
import '../../../helpers/localizadores.dart';

/// As duas partes do perfil de uma pessoa, e o que saiu dele.
///
/// A divisão é a do perfil da instituição, por um motivo comum: um perfil junta
/// **o que a pessoa publicou** e **quem ela é**, e numa lista única a segunda
/// empurra a primeira para fora da tela.
///
/// O que saiu daqui também tem teste, porque remoção sem asserção volta sozinha na
/// próxima edição: o cartão "Conta" foi para a tela de edição, e as ações de conta
/// foram para o menu do canto.
void main() {
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> abrirPerfil(WidgetTester tester) async {
    await tocar(tester, find.byTooltip('Perfil'));
  }

  group('as duas abas', () {
    testWidgets('abre nas publicações, com o currículo na segunda aba', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfil(tester);

      expect(find.byTooltip('Publicações'), findsOne);
      expect(find.byTooltip('Currículo'), findsOne);

      // A identificação fica acima das abas: ela responde "quem é esta conta", e
      // vale para as duas. `findsWidgets` e não `findsOne` desde a Sprint 5: a aba de
      // publicações lista os posts da própria pessoa, e o cabeçalho de cada card
      // repete o nome dela.
      expect(find.text(Fixtures.perfilDemo.nomeCompleto), findsWidgets);
      expect(find.text('@${Fixtures.perfilDemo.username}'), findsWidgets);

      // Publicações é a aba aberta — o currículo não está na tela ainda.
      expect(find.text('Formação'), findsNothing);
    });

    testWidgets('publicações lista os posts da própria pessoa', (tester) async {
      // Era um vazio honesto até a Sprint 4, quando o `feed-service` não existia.
      // Agora usa `GET /feed/usuarios/{id}/posts` — e **não** o feed: o feed é
      // limitado ao conjunto do leitor, e o próprio perfil não está nele.
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfil(tester);

      expect(find.textContaining('Terminei o projeto integrador'), findsOne);
      // Só os dela: o post da Carla é da mesma universidade e aparece no feed dela,
      // não nesta aba. É a diferença entre a rota do perfil e a do feed.
      expect(find.textContaining('Alguém de Gestão'), findsNothing);
    });

    testWidgets('o currículo traz formação e vínculo, nessa ordem', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfil(tester);
      await tocar(tester, find.byTooltip('Currículo'));

      expect(find.text('Formação'), findsOne);
      expect(find.text('Vínculo institucional'), findsOne);

      // Quem lê de cima para baixo encontra o currículo e só então o que ele
      // concede — que é nada, e o cartão seguinte diz isso.
      final formacao = tester.getCenter(find.text('Formação')).dy;
      final vinculo = tester.getCenter(find.text('Vínculo institucional')).dy;
      expect(formacao, lessThan(vinculo));
    });

    testWidgets('a faculdade vê o próprio perfil de instituição', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirPerfil(tester);

      // Organização não estuda em lugar nenhum, e currículo não é dela. O que ela vê
      // é **o perfil da instituição** — o mesmo que qualquer pessoa abre pela busca,
      // com as três abas por alcance. Antes era uma identificação sem abas e uma
      // frase apontando para uma tela que ela não tinha como abrir: o caminho era a
      // busca, e a busca não devolve a si mesma.
      expect(find.byTooltip('Currículo'), findsNothing);
      // `findsWidgets`: a sigla é o título do perfil e também o cabeçalho de cada
      // card de comunicado na lista.
      expect(find.text(Fixtures.fatecRp.sigla), findsWidgets);
      expect(find.byTooltip('Geral'), findsOne);
      expect(find.byTooltip('Institucional'), findsOne);
      expect(find.byTooltip('Por curso'), findsOne);

      // O menu da **conta** no canto, e não o do vínculo: inserir CPF não existe
      // para quem é a instituição, e sair da conta precisa morar em algum lugar.
      await tocar(tester, find.byTooltip('Opções da conta'));
      expect(find.text('Administração da instituição'), findsOne);
      expect(find.text('Sair da conta'), findsOne);
      expect(find.text('Inserir CPF'), findsNothing);
    });

    testWidgets('a faculdade vê os próprios comunicados em toda aba', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirPerfil(tester);

      // Ela é a autora, e o autor alcança o que escreveu em qualquer alcance — é a
      // primeira linha da matriz de visibilidade, e vale sem vínculo nenhum.
      await tocar(tester, find.byTooltip('Institucional'));
      expect(find.textContaining('biblioteca funcionará em horário reduzido'), findsOne);

      await tocar(tester, find.byTooltip('Por curso'));
      // Sem filtro: a aba nasce com todos os cursos, e o restrito aparece.
      expect(find.textContaining('projeto integrador de ADS'), findsOne);
    });

    testWidgets('o filtro de curso estreita a aba restrita', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirPerfil(tester);
      await tocar(tester, find.byTooltip('Por curso'));

      // O botão só existe nesta aba, e só para a instituição: para o aluno, "por
      // curso" já é o curso dele.
      await tocar(tester, find.byIcon(LucideIcons.graduationCap).first);
      await tocar(
        tester,
        find.descendant(
          of: find.byType(MenuItemButton),
          matching: find.text('Gestão Empresarial'),
        ),
      );

      // O comunicado restrito é de ADS: filtrando por Gestão, a lista fica vazia e
      // o vazio diz por quê, em vez de parecer que ela não publicou nada.
      expect(find.textContaining('projeto integrador de ADS'), findsNothing);
      expect(find.textContaining('Nada restrito a este curso'), findsOne);
    });
  });

  group('o que saiu do perfil', () {
    testWidgets('as informações de conta não aparecem mais aqui', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfil(tester);

      // O cartão "Conta" ocupava o lugar do que o perfil serve para mostrar. Nem na
      // aba de currículo ele volta.
      expect(find.text('Conta'), findsNothing);
      expect(find.textContaining(Fixtures.emailDemo), findsNothing);

      await tocar(tester, find.byTooltip('Currículo'));
      expect(find.text('Conta'), findsNothing);
    });

    testWidgets('o aviso sobre recuperação de senha saiu', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfil(tester);

      // Ele explicava uma ausência que o próprio fluxo já explica: quem abre
      // "trocar senha" encontra o campo de senha atual e entende sem legenda.
      expect(find.textContaining('recuperação de senha'), findsNothing);
    });

    testWidgets('as ações de conta vivem no menu, não no corpo', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirPerfil(tester);

      expect(find.text('Editar perfil'), findsNothing);
      expect(find.text('Trocar senha'), findsNothing);
      expect(find.text('Sair da conta'), findsNothing);

      // No canto direito, no lugar de mensagens: neste perfil a ação é sobre a
      // própria conta, e mandar mensagem para si não existe.
      expect(find.byTooltip('Mensagens'), findsNothing);
      await tocar(tester, find.byTooltip('Opções da conta'));

      expect(find.text('Editar perfil'), findsOne);
      expect(find.text('Trocar senha'), findsOne);
      expect(find.text('Sair da conta'), findsOne);
    });
  });

  group('as informações de conta, na edição', () {
    testWidgets('e-mail e CPF são campos, e explicam a recusa no toque', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirMenuDaConta(tester);
      await tocar(tester, find.text('Editar perfil'));

      // Campos, e não um cartão "Conta" à parte: quem abre esta tela procura o que
      // pode mudar, e dado exibido como texto corrido ele lê como "aqui não tem
      // nada para mim".
      expect(find.text('E-mail'), findsOne);
      expect(find.text('CPF'), findsOne);
      expect(find.text('Conta'), findsNothing);

      // **O motivo não é legenda fixa.** Ele ocuparia espaço permanente para
      // explicar algo que a maioria nunca vai tentar; aparece no toque, que é o
      // momento em que a pergunta existe.
      expect(find.textContaining('não pode ser alterado'), findsNothing);

      await tocar(tester, find.text('E-mail'));
      expect(
        find.textContaining('é a credencial com que você entra'),
        findsOne,
      );

      await tocar(tester, find.text('CPF'));
      expect(
        find.textContaining('assumir a matrícula de outra pessoa'),
        findsOne,
      );
    });

    testWidgets('a conta institucional vê CNPJ em vez de CPF', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailFaculdade);
      await abrirMenuDaConta(tester);
      await tocar(tester, find.text('Editar perfil'));

      expect(find.text('CNPJ'), findsOne);
      // Uma conta nunca tem os dois: um `CheckConstraint` no banco garante isso,
      // porque manter o CPF da pessoa física na conta da faculdade a deixaria
      // elegível a vínculo de aluno.
      expect(find.text('CPF'), findsNothing);

      await tocar(tester, find.text('CNPJ'));
      expect(
        find.textContaining('identifica a organização no Integra'),
        findsOne,
      );
    });

    testWidgets('salvar confirma, e a confirmação sobrevive ao fechar a tela', (
      tester,
    ) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirMenuDaConta(tester);
      await tocar(tester, find.text('Editar perfil'));

      await tester.enterText(campo('Bio'), 'Bio nova');
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Salvar alterações'));

      // **O bug que isto fecha:** a confirmação era um alerta no corpo da tela, e
      // salvar fecha a tela — ela era definida num widget que saía de cena no
      // instante seguinte, então existia no código e nunca aparecia. Toast
      // sobrevive ao `pop`.
      expect(find.text('Salvo'), findsOne);
      expect(find.textContaining('alterações foram gravadas'), findsOne);

      // E fechou mesmo: o formulário não está mais na árvore.
      expect(find.text('Salvar alterações'), findsNothing);
    });

    testWidgets('o telefone continua editável', (tester) async {
      await bombearAppAutenticado(tester, email: Fixtures.emailDemo);
      await abrirMenuDaConta(tester);
      await tocar(tester, find.text('Editar perfil'));

      // Telefone é dado de contato que o usuário mantém, e não credencial nem
      // chave: fica no formulário, e não no cartão dos não editáveis.
      expect(find.text('Telefone'), findsOne);
    });
  });
}
