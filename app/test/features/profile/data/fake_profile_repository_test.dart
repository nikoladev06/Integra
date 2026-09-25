import 'package:flutter_test/flutter_test.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/fake_profile_repository.dart';
import 'package:integra/features/profile/data/fixtures.dart';
import 'package:integra/features/profile/data/models/instituicao.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

void main() {
  late BancoFalso banco;
  late FakeProfileRepository repo;

  /// Entra como [perfilId] sem passar pelo repositório de autenticação: o que
  /// estes testes verificam é o de perfil.
  void autenticarComo(String perfilId) => banco.usuarioAtualId = perfilId;

  setUp(() {
    banco = BancoFalso();
    repo = FakeProfileRepository(banco, latencia: Duration.zero);
    autenticarComo(Fixtures.perfilDemo.id);
  });

  group('meuPerfil', () {
    test('traz contato e documento', () async {
      final perfil = await repo.meuPerfil();

      expect(perfil.email, Fixtures.emailDemo);
      expect(perfil.telefone, isNotNull);
      expect(perfil.cpf, Fixtures.cpfAna);
      expect(perfil.eOProprioPerfil, isTrue);
    });

    test('devolve quem entrou, não uma conta fixa', () async {
      autenticarComo(Fixtures.perfilSemVinculo.id);
      expect((await repo.meuPerfil()).email, Fixtures.emailSemVinculo);
    });
  });

  group('perfilDe', () {
    test('omite contato E documento no perfil público', () async {
      final perfil = await repo.perfilDe(Fixtures.perfilDemo.id);

      // O contrato não devolve e-mail, telefone, CPF nem CNPJ em `/users/{id}`
      // — nem mascarados. Se o falso os entregasse, a tela seria escrita
      // assumindo campos que a API real não manda.
      expect(perfil.email, isNull);
      expect(perfil.telefone, isNull);
      expect(perfil.cpf, isNull);
      expect(perfil.cnpj, isNull);
      // Formação e vínculo, ao contrário, são públicos de propósito: são o
      // equivalente a "estudou em" e "trabalha em" num perfil profissional.
      expect(perfil.formacoes, isNotEmpty);
      expect(perfil.vinculo, isNotNull);
    });

    test('id inexistente responde não encontrado', () async {
      await expectLater(
        repo.perfilDe('user-que-nao-existe'),
        throwsA(isA<FalhaNaoEncontrado>()),
      );
    });
  });

  group('atualizarMeuPerfil', () {
    test('campos omitidos ficam inalterados', () async {
      final antes = await repo.meuPerfil();
      final depois = await repo.atualizarMeuPerfil(bio: 'Nova bio');

      expect(depois.bio, 'Nova bio');
      expect(depois.nomeCompleto, antes.nomeCompleto);
      expect(depois.username, antes.username);
      expect(depois.alteradoEm, isNotNull);
    });

    test('username de outra conta responde conflito', () async {
      await expectLater(
        repo.atualizarMeuPerfil(username: Fixtures.perfilSemVinculo.username),
        throwsA(isA<FalhaDeConflito>()),
      );
    });

    test('manter o próprio username não é conflito', () async {
      // Salvar o formulário sem mexer no campo manda o valor atual de volta, e
      // recusar isso seria impedir a edição de qualquer outro campo.
      await expectLater(
        repo.atualizarMeuPerfil(username: Fixtures.perfilDemo.username),
        completes,
      );
    });

    test('não mexe em formação nem em vínculo', () async {
      // Na v1 este mesmo método trocava a afiliação, que ao mesmo tempo
      // aparecia no perfil e concedia acesso. Editar o perfil não pode ser um
      // caminho para se conceder visibilidade.
      final antes = await repo.meuPerfil();
      final depois = await repo.atualizarMeuPerfil(nomeCompleto: 'Ana P. S.');

      expect(depois.formacoes, antes.formacoes);
      expect(depois.vinculo, antes.vinculo);
    });
  });

  group('formação', () {
    test('declarar cria uma linha SEM selo', () async {
      final nova = await repo.declararFormacao(
        universidadeId: Fixtures.usp.id,
        cursoId: Fixtures.cienciaComputacao.id,
      );

      expect(nova.verificada, isFalse);
      expect((await repo.meuPerfil()).formacoes, hasLength(2));
    });

    test('declarar a mesma duas vezes responde conflito', () async {
      await expectLater(
        repo.declararFormacao(
          universidadeId: Fixtures.fatecRp.id,
          cursoId: Fixtures.ads.id,
        ),
        throwsA(isA<FalhaDeConflito>()),
      );
    });

    test('curso de outra universidade é recusado', () async {
      await expectLater(
        repo.declararFormacao(
          universidadeId: Fixtures.fatecRp.id,
          cursoId: Fixtures.cienciaComputacao.id,
        ),
        throwsA(isA<FalhaDeValidacao>()),
      );
    });

    test('formação verificada NÃO pode ser removida', () async {
      // O selo é afirmação da instituição, não do usuário. Deixá-lo apagável
      // pelo perfil transformaria "verificado" em algo que o próprio
      // interessado controla.
      final verificada = (await repo.meuPerfil()).formacoes.single;
      expect(verificada.verificada, isTrue);

      await expectLater(
        repo.removerFormacao(verificada.id),
        throwsA(isA<FalhaDeConflito>()),
      );
    });

    test('formação declarada pode ser removida', () async {
      final nova = await repo.declararFormacao(
        universidadeId: Fixtures.usp.id,
        cursoId: Fixtures.cienciaComputacao.id,
      );

      await repo.removerFormacao(nova.id);
      expect((await repo.meuPerfil()).formacoes, hasLength(1));
    });
  });

  group('vínculo', () {
    setUp(() => autenticarComo(Fixtures.perfilSemVinculo.id));

    test('parte de nulo, que é o estado normal de quem acabou de entrar', () async {
      expect(await repo.meuVinculo(), isNull);
    });

    test('CPF de outra pessoa é recusado ANTES de consultar a lista', () async {
      // É o passo que impede a escalada. O CPF da Ana consta nas matrículas da
      // FATEC; se a conferência contra a própria conta não viesse primeiro,
      // saber o CPF dela bastaria para entrar na instituição dela.
      await expectLater(
        repo.criarVinculo(
          universidadeId: Fixtures.fatecRp.id,
          cpf: Fixtures.cpfAna,
        ),
        throwsA(isA<FalhaDePermissao>()),
      );
      expect(await repo.meuVinculo(), isNull);
    });

    test('as duas recusas têm a MESMA mensagem', () async {
      // Status diferentes (403 e 404) servem a quem depura. O texto é único
      // para a rota não virar sonda da lista de matrículas da instituição.
      final deOutraPessoa = await repo
          .criarVinculo(
            universidadeId: Fixtures.fatecRp.id,
            cpf: Fixtures.cpfAna,
          )
          .then<Object?>((_) => null, onError: (Object e) => e);
      final foraDaLista = await repo
          .criarVinculo(
            universidadeId: Fixtures.usp.id,
            cpf: Fixtures.cpfBruno,
          )
          .then<Object?>((_) => null, onError: (Object e) => e);

      expect(deOutraPessoa, isA<FalhaDePermissao>());
      expect(foraDaLista, isA<FalhaNaoEncontrado>());
      expect(
        (deOutraPessoa! as Failure).mensagem,
        (foraDaLista! as Failure).mensagem,
      );
    });

    test('CPF próprio que consta na lista cria o vínculo e estampa o selo', () async {
      final vinculo = await repo.criarVinculo(
        universidadeId: Fixtures.fatecRp.id,
        cpf: Fixtures.cpfBruno,
      );

      expect(vinculo.universidade.id, Fixtures.fatecRp.id);
      // O curso vem da matrícula, não de escolha do aluno: é a faculdade que
      // diz em que curso ele está.
      expect(vinculo.curso.id, Fixtures.ads.id);

      // A formação que ele já havia declarado ganha o selo, em vez de uma
      // segunda linha idêntica aparecer no currículo.
      final perfil = await repo.meuPerfil();
      expect(perfil.formacoes, hasLength(1));
      expect(perfil.formacoes.single.verificada, isTrue);
    });

    test('aceita CPF com pontuação', () async {
      await expectLater(
        repo.criarVinculo(
          universidadeId: Fixtures.fatecRp.id,
          cpf: '529.982.247-25',
        ),
        completes,
      );
    });

    test('encerrar apaga o vínculo e PRESERVA o selo', () async {
      await repo.criarVinculo(
        universidadeId: Fixtures.fatecRp.id,
        cpf: Fixtures.cpfBruno,
      );
      await repo.encerrarVinculo();

      final perfil = await repo.meuPerfil();
      expect(perfil.vinculo, isNull);
      // Encerrar o vínculo não desfaz o fato de ter estudado lá — apagar o selo
      // reescreveria o passado.
      expect(perfil.formacoes.single.verificada, isTrue);
    });

    test('encerrar é idempotente', () async {
      await expectLater(repo.encerrarVinculo(), completes);
      await expectLater(repo.encerrarVinculo(), completes);
    });
  });

  group('busca', () {
    test('termo curto devolve os três grupos vazios, sem consultar', () async {
      final resultado = await repo.buscar('a');

      // Os grupos vêm sempre, ainda que vazios: a ausência de chave seria
      // ambígua entre "não achei" e "não pedi este tipo".
      expect(resultado.vazio, isTrue);
      expect(resultado.universidades, isEmpty);
      expect(resultado.empresas, isEmpty);
      expect(resultado.pessoas, isEmpty);
    });

    test('agrupa universidade, empresa e pessoa', () async {
      expect((await repo.buscar('fatec')).universidades, isNotEmpty);
      expect((await repo.buscar('órbita')).empresas, isNotEmpty);
      expect((await repo.buscar('bruno')).pessoas, isNotEmpty);
    });

    test('a conta de faculdade NÃO aparece entre as pessoas', () async {
      // Ela já aparece no grupo de universidades; listá-la também em "Pessoas"
      // mostraria a mesma instituição duas vezes, com nomes diferentes.
      final resultado = await repo.buscar('fatec');
      expect(resultado.pessoas, isEmpty);
    });

    test('resultados de busca omitem contato', () async {
      final achados = await repo.buscar('ana');
      expect(achados.pessoas, isNotEmpty);
      expect(achados.pessoas.every((p) => p.email == null), isTrue);
    });
  });

  group('buscarPessoas', () {
    test('filtra por VÍNCULO, não por formação declarada', () async {
      // É o filtro que sustenta "ver outros alunos da mesma instituição". Ele
      // olha o vínculo porque qualquer um pode declarar qualquer formação — o
      // Bruno declarou a FATEC e não tem vínculo com ela.
      // A Ana tem vínculo com a FATEC e aparece.
      expect(
        (await repo.buscarPessoas('ana', universidadeId: Fixtures.fatecRp.id))
            .map((p) => p.id),
        contains(Fixtures.perfilDemo.id),
      );

      // O Bruno declarou a FATEC no currículo e **não** tem vínculo: some do
      // filtro, embora a busca sem filtro o encontre.
      expect(await repo.buscarPessoas('bruno'), isNotEmpty);
      expect(
        await repo.buscarPessoas('bruno', universidadeId: Fixtures.fatecRp.id),
        isEmpty,
      );
    });

    test('termo curto devolve vazio sem consultar', () async {
      expect(await repo.buscarPessoas('a'), isEmpty);
      expect(await repo.buscarPessoas(''), isEmpty);
    });
  });

  group('instituições', () {
    test('lista universidades e seus cursos', () async {
      expect(await repo.universidades(), hasLength(2));
      expect(
        (await repo.cursosDe(Fixtures.fatecRp.id)).map((c) => c.nome),
        contains('Gestão Empresarial'),
      );
    });

    test('universidade inexistente responde não encontrado', () async {
      await expectLater(
        repo.cursosDe('uni-inexistente'),
        throwsA(isA<FalhaNaoEncontrado>()),
      );
    });

    test('perfil da universidade resolve temVinculo para o leitor', () async {
      final comoAna = await repo.perfilDaUniversidade(Fixtures.fatecRp.id);
      expect(comoAna.temVinculo, isTrue);
      expect(comoAna.totalDeAlunos, 2);

      autenticarComo(Fixtures.perfilSemVinculo.id);
      final comoBruno = await repo.perfilDaUniversidade(Fixtures.fatecRp.id);
      // Declarou a FATEC, mas não tem vínculo — e é o vínculo que o menu lê.
      expect(comoBruno.temVinculo, isFalse);
    });
  });

  group('seguir universidades', () {
    test('a do vínculo entra na lista sem ninguém ter clicado em seguir', () async {
      final seguidas = await repo.universidadesSeguidas();

      expect(seguidas, hasLength(1));
      expect(seguidas.single.id, Fixtures.fatecRp.id);
      // `propria` marca a do vínculo: ela não é opcional enquanto o vínculo
      // existir, e deixá-la de fora faria o escopo "geral" do feed excluir
      // justamente a instituição do aluno.
      expect(seguidas.single.propria, isTrue);
    });

    test('seguir e deixar de seguir', () async {
      await repo.seguirUniversidade(Fixtures.usp.id, seguir: true);
      expect(await repo.universidadesSeguidas(), hasLength(2));

      await repo.seguirUniversidade(Fixtures.usp.id, seguir: false);
      expect(await repo.universidadesSeguidas(), hasLength(1));
    });

    test('seguir a própria não a duplica na lista', () async {
      await repo.seguirUniversidade(Fixtures.fatecRp.id, seguir: true);
      expect(await repo.universidadesSeguidas(), hasLength(1));
    });
  });
}
