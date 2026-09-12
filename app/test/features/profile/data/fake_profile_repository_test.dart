import 'package:flutter_test/flutter_test.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/features/profile/data/fixtures.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/data/profile_repository.dart';

void main() {
  late FakeProfileRepository repo;

  setUp(() => repo = FakeProfileRepository(latencia: Duration.zero));

  group('meuPerfil', () {
    test('traz os dados de contato', () async {
      final perfil = await repo.meuPerfil();

      expect(perfil.email, Fixtures.emailDemo);
      expect(perfil.telefone, isNotNull);
      expect(perfil.eOProprioPerfil, isTrue);
    });
  });

  group('perfilDe', () {
    test('omite contato no perfil público', () async {
      final perfil = await repo.perfilDe(Fixtures.perfilDemo.id);

      // O contrato omite e-mail e telefone em `GET /users/{id}`: dados de
      // contato não circulam entre alunos. Se o falso os entregasse, a tela
      // seria escrita assumindo campos que a API real não manda.
      expect(perfil.email, isNull);
      expect(perfil.telefone, isNull);
      expect(perfil.nomeCompleto, isNotEmpty);
    });

    test('id inexistente responde não encontrado', () async {
      await expectLater(
        repo.perfilDe('user-que-nao-existe'),
        throwsA(isA<FalhaNaoEncontrado>()),
      );
    });
  });

  group('buscar', () {
    test('termo curto devolve vazio sem consultar', () async {
      expect(await repo.buscar('a'), isEmpty);
      expect(await repo.buscar(''), isEmpty);
    });

    test('casa por username e por nome', () async {
      expect(await repo.buscar('bruno'), isNotEmpty);
      expect(await repo.buscar('Carla'), isNotEmpty);
      expect(await repo.buscar('zzzz'), isEmpty);
    });

    test('filtra por universidade', () async {
      // É este filtro que sustenta "ver outros alunos da mesma instituição",
      // do pilar Acadêmico.
      final daFatec = await repo.buscar(
        'an',
        universidadeId: Fixtures.fatecRp.id,
      );
      expect(daFatec, isNotEmpty);
      expect(
        daFatec.every((p) => p.afiliacao.universidade.id == Fixtures.fatecRp.id),
        isTrue,
      );

      // As fixtures não têm ninguém na USP, então o mesmo termo não acha nada
      // ali — o que prova que o filtro está sendo aplicado, e não ignorado.
      expect(await repo.buscar('an', universidadeId: Fixtures.usp.id), isEmpty);
    });

    test('resultados de busca também omitem contato', () async {
      final achados = await repo.buscar('ana');
      expect(achados, isNotEmpty);
      expect(achados.every((p) => p.email == null), isTrue);
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
        repo.atualizarMeuPerfil(username: 'brunocl'),
        throwsA(isA<FalhaDeConflito>()),
      );
    });

    test('curso que não pertence à universidade é recusado', () async {
      // O contrato exige que o curso pertença à universidade vigente. Sem esta
      // checagem, o falso aceitaria um par que a API real recusa — e a tela
      // nasceria sem tratar o erro.
      await expectLater(
        repo.atualizarMeuPerfil(cursoId: Fixtures.cienciaComputacao.id),
        throwsA(isA<FalhaDeValidacao>()),
      );
    });

    test('trocar universidade e curso juntos funciona', () async {
      final perfil = await repo.atualizarMeuPerfil(
        universidadeId: Fixtures.usp.id,
        cursoId: Fixtures.cienciaComputacao.id,
      );

      expect(perfil.afiliacao.universidade.sigla, 'USP');
      expect(perfil.afiliacao.curso.nome, 'Ciência da Computação');
    });
  });

  group('instituições', () {
    test('lista universidades e seus cursos', () async {
      final unis = await repo.universidades();
      expect(unis, hasLength(2));

      final cursos = await repo.cursosDe(Fixtures.fatecRp.id);
      expect(cursos.map((c) => c.nome), contains('Gestão Empresarial'));
    });

    test('universidade inexistente responde não encontrado', () async {
      await expectLater(
        repo.cursosDe('uni-inexistente'),
        throwsA(isA<FalhaNaoEncontrado>()),
      );
    });
  });
}
