import 'package:flutter_test/flutter_test.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/features/auth/data/fake_auth_repository.dart';
import 'package:integra/features/profile/data/fixtures.dart';

/// Estes testes travam o **comportamento do contrato**, não a implementação do
/// falso.
///
/// Quando o `ApiAuthRepository` entrar na Sprint 3, este mesmo arquivo deve
/// passar contra ele — é o que garante que o falso não ensinou as telas um
/// comportamento que a API real não tem.
void main() {
  late FakeAuthRepository repo;

  setUp(() => repo = FakeAuthRepository(latencia: Duration.zero));

  group('entrar', () {
    test('credencial correta emite o par de tokens', () async {
      final par = await repo.entrar(
        email: Fixtures.emailDemo,
        senha: Fixtures.senhaDemo,
      );

      expect(par.accessToken, isNotEmpty);
      expect(par.refreshToken, isNotEmpty);
      expect(par.tokenType, 'Bearer');
      expect(par.expiresIn, 900);
    });

    test('e-mail é normalizado para minúsculas', () async {
      await expectLater(
        repo.entrar(
          email: Fixtures.emailDemo.toUpperCase(),
          senha: Fixtures.senhaDemo,
        ),
        completes,
      );
    });

    test('senha errada e e-mail inexistente dão a MESMA mensagem', () async {
      // O contrato exige isso: mensagens diferentes entregam ao atacante uma
      // sonda de quais e-mails existem na base.
      final porSenha = await repo
          .entrar(email: Fixtures.emailDemo, senha: 'errada')
          .then<Object?>((_) => null, onError: (Object e) => e);
      final porEmail = await repo
          .entrar(email: 'ninguem@exemplo.com', senha: 'qualquer')
          .then<Object?>((_) => null, onError: (Object e) => e);

      expect(porSenha, isA<FalhaDeAutenticacao>());
      expect(porEmail, isA<FalhaDeAutenticacao>());
      expect(
        (porSenha! as Failure).mensagem,
        (porEmail! as Failure).mensagem,
      );
    });
  });

  group('cadastrar', () {
    test('e-mail já usado responde conflito, não validação', () async {
      // 409 e 422 são coisas distintas para o cliente: um é "já existe", o
      // outro é "formato inválido", e a tela reage diferente aos dois.
      await expectLater(
        repo.cadastrar(
          nomeCompleto: 'Ana Souza',
          email: Fixtures.emailDemo,
          username: 'outra_ana',
          senha: 'segredo1',
          telefone: '(16)99999-0000',
          universidadeId: Fixtures.fatecRp.id,
          cursoId: Fixtures.ads.id,
        ),
        throwsA(
          isA<FalhaDeConflito>().having(
            (f) => f.mensagem,
            'mensagem',
            'Email já cadastrado',
          ),
        ),
      );
    });

    test('username já usado responde conflito', () async {
      await expectLater(
        repo.cadastrar(
          nomeCompleto: 'Bruno Lima',
          email: 'bruno@exemplo.com',
          username: Fixtures.perfilDemo.username,
          senha: 'segredo1',
          telefone: '(16)99999-0000',
          universidadeId: Fixtures.fatecRp.id,
          cursoId: Fixtures.ads.id,
        ),
        throwsA(isA<FalhaDeConflito>()),
      );
    });

    test('cadastro novo permite entrar em seguida', () async {
      await repo.cadastrar(
        nomeCompleto: 'Bruno Lima',
        email: 'bruno@exemplo.com',
        username: 'brunolima',
        senha: 'segredo1',
        telefone: '(16)99999-0000',
        universidadeId: Fixtures.fatecRp.id,
        cursoId: Fixtures.ads.id,
      );

      await expectLater(
        repo.entrar(email: 'bruno@exemplo.com', senha: 'segredo1'),
        completes,
      );
    });
  });

  group('renovar', () {
    test('rotaciona: o refresh usado não serve de novo', () async {
      final primeiro = await repo.entrar(
        email: Fixtures.emailDemo,
        senha: Fixtures.senhaDemo,
      );
      final segundo = await repo.renovar(primeiro.refreshToken);

      expect(segundo.refreshToken, isNot(primeiro.refreshToken));
      // Reapresentar o antigo é o sinal de token vazado, e o contrato manda
      // recusar.
      await expectLater(
        repo.renovar(primeiro.refreshToken),
        throwsA(isA<FalhaDeAutenticacao>()),
      );
    });

    test('refresh desconhecido é recusado', () async {
      await expectLater(
        repo.renovar('nunca-emitido'),
        throwsA(isA<FalhaDeAutenticacao>()),
      );
    });
  });

  group('sair', () {
    test('é idempotente, mesmo com token já inválido', () async {
      final par = await repo.entrar(
        email: Fixtures.emailDemo,
        senha: Fixtures.senhaDemo,
      );

      await expectLater(repo.sair(par.refreshToken), completes);
      // O contrato responde 204 nas duas vezes: o cliente não tem o que fazer
      // com um erro de logout.
      await expectLater(repo.sair(par.refreshToken), completes);
    });
  });

  group('trocarSenha', () {
    test('exige a senha atual correta', () async {
      await expectLater(
        repo.trocarSenha(
          senhaAtual: 'errada',
          novaSenha: 'novaSenha1',
          confirmacao: 'novaSenha1',
        ),
        throwsA(isA<FalhaDeAutenticacao>()),
      );
    });

    test('confirmação divergente responde validação por campo', () async {
      await expectLater(
        repo.trocarSenha(
          senhaAtual: Fixtures.senhaDemo,
          novaSenha: 'novaSenha1',
          confirmacao: 'novaSenha2',
        ),
        throwsA(
          isA<FalhaDeValidacao>().having(
            (f) => f.primeiroErroDe('confirmacao'),
            'erro do campo confirmacao',
            'As senhas não correspondem',
          ),
        ),
      );
    });

    test('trocar a senha revoga TODAS as sessões', () async {
      final par = await repo.entrar(
        email: Fixtures.emailDemo,
        senha: Fixtures.senhaDemo,
      );

      await repo.trocarSenha(
        senhaAtual: Fixtures.senhaDemo,
        novaSenha: 'novaSenha1',
        confirmacao: 'novaSenha1',
      );

      // Inclusive a sessão que fez a troca: o cliente precisa refazer o login.
      await expectLater(
        repo.renovar(par.refreshToken),
        throwsA(isA<FalhaDeAutenticacao>()),
      );
      await expectLater(
        repo.entrar(email: Fixtures.emailDemo, senha: 'novaSenha1'),
        completes,
      );
    });
  });
}
