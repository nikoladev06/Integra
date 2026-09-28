import 'package:flutter_test/flutter_test.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/features/academic/data/fake_academic_repository.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/fake_profile_repository.dart';
import 'package:integra/features/profile/data/fixtures.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// A matriz de visibilidade, no lado do cliente.
///
/// Estes testes existem por um motivo específico, que o plano nomeia: **o falso
/// pode mentir de um jeito que a API não mente.** As telas do pilar Acadêmico são
/// escritas contra este repositório, e se ele entregasse tudo elas aprenderiam um
/// mundo sem restrição — o erro só apareceria contra o servidor.
///
/// Os casos aqui são os **mesmos** de `services/academic/tests/test_visibilidade.py`
/// e `test_regra_integracao.py`, de propósito. A regra passou a existir em três
/// lugares (SQL, Python e Dart), e duplicação de regra diverge calada: o que
/// segura é ter os três com a mesma lista de casos.
void main() {
  late BancoFalso banco;
  late FakeAcademicRepository academico;
  late FakeProfileRepository perfis;

  void autenticarComo(String perfilId) => banco.usuarioAtualId = perfilId;

  setUp(() {
    banco = BancoFalso();
    academico = FakeAcademicRepository(banco, latencia: Duration.zero);
    perfis = FakeProfileRepository(banco, latencia: Duration.zero);
  });

  /// Os ids visíveis no escopo pedido.
  Future<Set<String>> idsDoFeed({
    EscopoDoFeed escopo = EscopoDoFeed.geral,
  }) async =>
      (await academico.feed(escopo: escopo)).itens.map((p) => p.id).toSet();

  Future<Post> porAlcance(Visibilidade alcance) async {
    final pagina = await academico.feed();
    return pagina.itens.firstWhere((p) => p.visibilidade == alcance);
  }

  group('matriz de visibilidade', () {
    test(
      'com vínculo em ADS vê público, interno e o restrito ao próprio curso',
      () async {
        autenticarComo(Fixtures.perfilDemo.id); // Ana: vínculo FATEC/ADS

        final alcances = (await academico.feed()).itens
            .map((p) => p.visibilidade)
            .toSet();

        expect(alcances, {
          Visibilidade.publico,
          Visibilidade.institucional,
          Visibilidade.curso,
        });
      },
    );

    test('vínculo em outro curso não recebe o restrito a ADS', () async {
      autenticarComo(Fixtures.perfilCarla.id); // Carla: vínculo FATEC/Gestão

      final itens = (await academico.feed()).itens;

      expect(
        itens.map((p) => p.visibilidade),
        containsAll([Visibilidade.publico, Visibilidade.institucional]),
      );
      expect(
        itens.where((p) => p.visibilidade == Visibilidade.curso),
        isEmpty,
        reason: 'o comunicado de ADS não é de quem tem vínculo em Gestão',
      );
    });

    test('quem só DECLAROU a formação vê apenas o público', () async {
      // Bruno declarou ADS na FATEC e **não** tem vínculo. É o portão da sprint,
      // do lado do cliente: na v1 ele leria tudo, porque o acesso vinha da
      // afiliação que o próprio usuário digitava.
      autenticarComo(Fixtures.perfilSemVinculo.id);
      await perfis.seguirUniversidade(Fixtures.fatecRp.id, seguir: true);

      final itens = (await academico.feed()).itens;

      expect(itens.map((p) => p.visibilidade).toSet(), {Visibilidade.publico});
    });

    test('seguir não abre o conteúdo interno', () async {
      autenticarComo(Fixtures.perfilSemVinculo.id);
      final semSeguir = await idsDoFeed();

      await perfis.seguirUniversidade(Fixtures.fatecRp.id, seguir: true);
      final seguindo = await idsDoFeed();

      // Seguir muda **quais** instituições entram no feed, não o que se vê dentro
      // delas: aqui a FATEC já entrava pela formação? Não — entra ao seguir, e
      // mesmo assim só o público aparece.
      expect(semSeguir, isEmpty);
      expect(seguindo, isNotEmpty);
      expect(
        (await academico.feed()).itens.map((p) => p.visibilidade).toSet(),
        {Visibilidade.publico},
      );
    });

    test('formação verificada sem vínculo ativo não concede nada', () async {
      autenticarComo(Fixtures.perfilDemo.id);
      await perfis.seguirUniversidade(Fixtures.fatecRp.id, seguir: true);

      // Ana tem o selo e o vínculo. Encerrar o vínculo **mantém o selo**, e é
      // exatamente o caso que a v2 existe para distinguir.
      await perfis.encerrarVinculo();
      final perfil = await perfis.meuPerfil();

      expect(
        perfil.formacoesVerificadas,
        isNotEmpty,
        reason: 'o selo é permanente — quem se formou realmente estudou lá',
      );
      expect(
        (await academico.feed()).itens.map((p) => p.visibilidade).toSet(),
        {Visibilidade.publico},
        reason: 'sem vínculo ativo, volta a ver só os públicos',
      );
    });

    test(
      'a faculdade autora alcança o que publicou, em qualquer alcance',
      () async {
        autenticarComo(Fixtures.perfilFatec.id);

        // Conta institucional **não tem vínculo** — vínculo é de aluno. Sem a
        // cláusula do autor, ela publicaria um comunicado restrito e em seguida
        // levaria 404 no próprio post.
        final alcances = (await academico.feed()).itens
            .map((p) => p.visibilidade)
            .toSet();

        expect(alcances, {
          Visibilidade.publico,
          Visibilidade.institucional,
          Visibilidade.curso,
        });
      },
    );

    test('post fora do alcance responde igual a post inexistente', () async {
      autenticarComo(Fixtures.perfilDemo.id);
      final restrito = await porAlcance(Visibilidade.curso);

      autenticarComo(Fixtures.perfilSemVinculo.id);

      final foraDoAlcance = await academico
          .post(restrito.id)
          .then<Object?>((_) => null, onError: (Object e) => e);
      final inexistente = await academico
          .post('post-que-nunca-existiu')
          .then<Object?>((_) => null, onError: (Object e) => e);

      // A mesma classe e a mesma mensagem: distinguir os dois confirmaria que
      // existe um comunicado restrito naquele id, e a rota viraria sonda.
      expect(foraDoAlcance, isA<FalhaNaoEncontrado>());
      expect(inexistente, isA<FalhaNaoEncontrado>());
      expect(
        (foraDoAlcance as Failure).mensagem,
        (inexistente as Failure).mensagem,
      );
    });
  });

  group('escopo', () {
    test('minha instituição sem vínculo responde vazio, sem erro', () async {
      autenticarComo(Fixtures.perfilSemVinculo.id);

      // Não é erro: é o estado de quem ainda não informou o CPF em nenhuma
      // instituição, e a tela mostra o caminho em vez de um vazio genérico.
      expect(await idsDoFeed(escopo: EscopoDoFeed.minha), isEmpty);
    });

    test('geral inclui a do vínculo mesmo sem seguir', () async {
      autenticarComo(Fixtures.perfilDemo.id);

      // Ana nunca clicou em "seguir" a FATEC. A universidade do vínculo entra no
      // escopo de qualquer forma — sem isso o feed excluiria justamente a
      // instituição da aluna.
      expect(await idsDoFeed(), isNotEmpty);
    });

    test(
      'o perfil da universidade mostra os públicos a quem não tem vínculo',
      () async {
        autenticarComo(Fixtures.perfilSemVinculo.id);

        final pagina = await academico.postsDaUniversidade(Fixtures.fatecRp.id);

        // O caminho de quem chegou pela busca: não segue, não tem vínculo, e ainda
        // assim tem direito aos públicos. O feed não os mostraria.
        expect(pagina.itens.map((p) => p.visibilidade).toSet(), {
          Visibilidade.publico,
        });
      },
    );
  });

  group('o filtro das abas do perfil da instituição', () {
    /// Os alcances visíveis numa aba.
    Future<Set<Visibilidade>> aba(Visibilidade alcance) async =>
        (await academico.postsDaUniversidade(
          Fixtures.fatecRp.id,
          visibilidade: alcance,
        )).itens.map((p) => p.visibilidade).toSet();

    test('cada aba traz só o alcance dela', () async {
      autenticarComo(Fixtures.perfilDemo.id); // vínculo FATEC/ADS

      expect(await aba(Visibilidade.publico), {Visibilidade.publico});
      expect(await aba(Visibilidade.institucional), {
        Visibilidade.institucional,
      });
      expect(await aba(Visibilidade.curso), {Visibilidade.curso});
    });

    test('o filtro NÃO concede nada', () async {
      // **O teste que justifica o parâmetro poder vir da tela.** O filtro estreita
      // o que a matriz de visibilidade já autorizou, e nunca amplia: se ele fosse
      // aplicado em lugar da regra — e não junto dela —, pedir a aba "por curso"
      // sem vínculo devolveria os restritos.
      //
      // É o mesmo caso de `test_o_filtro_de_alcance_nao_concede_nada`, do lado do
      // serviço. A regra vive em três lugares, e o que segura a divergência é os
      // três terem a mesma lista de casos.
      autenticarComo(Fixtures.perfilSemVinculo.id);

      expect(await aba(Visibilidade.publico), {Visibilidade.publico});
      expect(await aba(Visibilidade.institucional), isEmpty);
      expect(await aba(Visibilidade.curso), isEmpty);
    });

    test('vínculo em outro curso não abre a aba do curso alheio', () async {
      autenticarComo(Fixtures.perfilCarla.id); // vínculo FATEC/Gestão

      // O interno ela alcança; o restrito a ADS, não.
      expect(await aba(Visibilidade.institucional), {
        Visibilidade.institucional,
      });
      expect(await aba(Visibilidade.curso), isEmpty);
    });

    test('sem o filtro, a rota devolve todos os alcances visíveis', () async {
      autenticarComo(Fixtures.perfilDemo.id);

      final todos = await academico.postsDaUniversidade(Fixtures.fatecRp.id);

      expect(todos.itens.map((p) => p.visibilidade).toSet(), {
        Visibilidade.publico,
        Visibilidade.institucional,
        Visibilidade.curso,
      });
    });
  });

  group('publicação', () {
    test('aluno não publica', () async {
      autenticarComo(Fixtures.perfilDemo.id);

      expect(
        () => academico.publicar(
          conteudo: 'quero publicar',
          visibilidade: Visibilidade.publico,
        ),
        throwsA(isA<FalhaDePermissao>()),
      );
    });

    test('instituição pendente não publica', () async {
      // A conta de empresa das fixtures nasce pendente — é o estado em que toda
      // conta institucional nasce.
      autenticarComo(Fixtures.perfilEmpresa.id);

      expect(
        () => academico.publicar(
          conteudo: 'em análise',
          visibilidade: Visibilidade.publico,
        ),
        throwsA(isA<FalhaDePermissao>()),
      );
    });

    test('a universidade do post é a da conta autora', () async {
      autenticarComo(Fixtures.perfilFatec.id);

      final post = await academico.publicar(
        conteudo: 'aviso novo',
        visibilidade: Visibilidade.institucional,
      );

      // Não há parâmetro de universidade na interface, e é a ausência que garante
      // isto: uma faculdade não consegue publicar no nome de outra.
      expect(post.instituicao.id, Fixtures.fatecRp.id);
      expect(post.podeEditar, isTrue);
    });

    test('restrito a curso exige curso, e da própria instituição', () async {
      autenticarComo(Fixtures.perfilFatec.id);

      expect(
        () => academico.publicar(
          conteudo: 'sem curso',
          visibilidade: Visibilidade.curso,
        ),
        throwsA(isA<FalhaDeValidacao>()),
      );
      expect(
        () => academico.publicar(
          conteudo: 'curso de outra',
          visibilidade: Visibilidade.curso,
          cursoId: Fixtures.cienciaComputacao.id, // é da USP
        ),
        throwsA(isA<FalhaDeValidacao>()),
      );
    });

    test('curso sobrando em post institucional é recusado, não ignorado', () async {
      autenticarComo(Fixtures.perfilFatec.id);

      // Aceito em silêncio, ele pareceria uma restrição que não existe — e quem
      // publicou acharia que restringiu.
      expect(
        () => academico.publicar(
          conteudo: 'alcance ambíguo',
          visibilidade: Visibilidade.institucional,
          cursoId: Fixtures.ads.id,
        ),
        throwsA(isA<FalhaDeValidacao>()),
      );
    });

    test('editar muda o alcance e limpa a restrição ao sair de curso', () async {
      autenticarComo(Fixtures.perfilFatec.id);
      final restrito = await porAlcance(Visibilidade.curso);

      final editado = await academico.editar(
        restrito.id,
        conteudo: 'texto corrigido',
        visibilidade: Visibilidade.publico,
      );

      expect(editado.conteudo, 'texto corrigido');
      expect(editado.visibilidade, Visibilidade.publico);
      expect(
        editado.curso,
        isNull,
        reason: 'sair de curso limpa a restrição, em vez de deixar uma órfã',
      );
      expect(
        editado.editadoEm,
        isNotNull,
        reason:
            'é o que faz a tela mostrar "editado" — quem já leu não é avisado',
      );
    });

    test('outra faculdade não edita nem apaga', () async {
      autenticarComo(Fixtures.perfilFatec.id);
      final post = await porAlcance(Visibilidade.publico);

      // Uma segunda conta institucional, ativada e administrando outra
      // universidade: tem todos os poderes, menos sobre o post que não é dela.
      banco.salvar(
        Fixtures.perfilEmpresa.copyWith(
          id: 'user-usp',
          tipo: TipoConta.faculdade,
          ativadaEm: DateTime.utc(2026, 1, 1),
        ),
      );
      banco.contaDaUniversidade[Fixtures.usp.id] = 'user-usp';
      autenticarComo('user-usp');

      expect(
        () => academico.editar(post.id, conteudo: 'sequestrado'),
        throwsA(isA<FalhaNaoEncontrado>()),
      );
      expect(
        () => academico.remover(post.id),
        throwsA(isA<FalhaNaoEncontrado>()),
      );
    });

    test('apagar leva curtidas e comentários', () async {
      autenticarComo(Fixtures.perfilDemo.id);
      final post = await porAlcance(Visibilidade.institucional);
      await academico.curtir(post.id, curtir: true);
      await academico.comentar(post.id, 'combinado');

      autenticarComo(Fixtures.perfilFatec.id);
      await academico.remover(post.id);

      expect(
        banco.comentarios.where((c) => c.postId == post.id),
        isEmpty,
        reason: 'no banco é ON DELETE CASCADE; aqui é à mão, pelo mesmo motivo',
      );
    });
  });

  group('curtidas e comentários', () {
    test('curtir é idempotente e a marca é por leitor', () async {
      autenticarComo(Fixtures.perfilDemo.id);
      final post = await porAlcance(Visibilidade.institucional);

      await academico.curtir(post.id, curtir: true);
      await academico.curtir(post.id, curtir: true);

      final meu = await academico.post(post.id);
      expect(meu.totalDeCurtidas, 1, reason: 'duas chamadas, uma curtida');
      expect(meu.curtidoPorMim, isTrue);

      autenticarComo(Fixtures.perfilCarla.id);
      final dela = await academico.post(post.id);
      expect(dela.totalDeCurtidas, 1);
      expect(
        dela.curtidoPorMim,
        isFalse,
        reason:
            'o protótipo guardava isLiked no post, e a curtida de um '
            'aparecia para todos',
      );
    });

    test('descurtir o que não estava curtido não falha', () async {
      autenticarComo(Fixtures.perfilDemo.id);
      final post = await porAlcance(Visibilidade.publico);

      await expectLater(academico.curtir(post.id, curtir: false), completes);
    });

    test(
      'quem não vê o post não curte, não comenta e não lê comentários',
      () async {
        autenticarComo(Fixtures.perfilDemo.id);
        final restrito = await porAlcance(Visibilidade.curso);

        autenticarComo(Fixtures.perfilSemVinculo.id);

        // O erro clássico deste desenho é checar visibilidade na leitura e esquecer
        // na escrita. As três passam pelo mesmo portão.
        expect(
          () => academico.curtir(restrito.id, curtir: true),
          throwsA(isA<FalhaNaoEncontrado>()),
        );
        expect(
          () => academico.comentar(restrito.id, 'li o que não devia'),
          throwsA(isA<FalhaNaoEncontrado>()),
        );
        expect(
          () => academico.comentarios(restrito.id),
          throwsA(isA<FalhaNaoEncontrado>()),
        );
      },
    );

    test('comentários vêm em ordem cronológica, com autor resolvido', () async {
      autenticarComo(Fixtures.perfilDemo.id);
      final post = await porAlcance(Visibilidade.institucional);

      for (final texto in ['primeiro', 'segundo', 'terceiro']) {
        await academico.comentar(post.id, texto);
      }

      final itens = (await academico.comentarios(post.id)).itens;

      expect(itens.map((c) => c.conteudo), ['primeiro', 'segundo', 'terceiro']);
      expect(itens.first.autor.nomeCompleto, Fixtures.perfilDemo.nomeCompleto);
      expect(itens.first.podeRemover, isTrue);
    });

    test('a faculdade autora modera comentário de outro', () async {
      autenticarComo(Fixtures.perfilDemo.id);
      final post = await porAlcance(Visibilidade.institucional);
      final comentario = await academico.comentar(post.id, 'fora de lugar');

      autenticarComo(Fixtures.perfilFatec.id);
      final visto = (await academico.comentarios(post.id)).itens.single;

      // Sem esta metade, a única saída da instituição seria apagar o comunicado
      // inteiro.
      expect(visto.podeRemover, isTrue);
      await expectLater(academico.removerComentario(comentario.id), completes);
    });

    test('um aluno não remove o comentário de outro', () async {
      autenticarComo(Fixtures.perfilDemo.id);
      final post = await porAlcance(Visibilidade.institucional);
      final comentario = await academico.comentar(post.id, 'meu');

      autenticarComo(Fixtures.perfilCarla.id);
      final alheio = (await academico.comentarios(post.id)).itens.single;

      expect(alheio.podeRemover, isFalse);
      expect(
        () => academico.removerComentario(comentario.id),
        throwsA(isA<FalhaNaoEncontrado>()),
      );
    });

    test('a contagem de comentários acompanha a lista', () async {
      autenticarComo(Fixtures.perfilDemo.id);
      final post = await porAlcance(Visibilidade.institucional);

      expect(post.totalDeComentarios, 0);
      await academico.comentar(post.id, 'primeiro');

      expect((await academico.post(post.id)).totalDeComentarios, 1);
    });
  });
}
