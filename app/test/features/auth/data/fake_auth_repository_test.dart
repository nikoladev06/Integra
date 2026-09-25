import 'package:flutter_test/flutter_test.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/features/auth/data/fake_auth_repository.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/fixtures.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// Estes testes travam o **comportamento do contrato**, não a implementação do
/// falso.
///
/// Quando o app apontar para o `auth-service`, este mesmo arquivo deve descrever
/// o que acontece — é o que garante que o falso não ensinou às telas um
/// comportamento que a API real não tem.
void main() {
  late BancoFalso banco;
  late FakeAuthRepository repo;

  setUp(() {
    banco = BancoFalso();
    repo = FakeAuthRepository(banco, latencia: Duration.zero);
  });

  /// Um CPF estruturalmente válido que ainda não está na base semeada.
  const cpfNovo = '24611680320';

  Future<void> cadastrarBruno({
    String email = 'novo@exemplo.com',
    String username = 'novo_usuario',
    String cpf = cpfNovo,
    String? universidadeId,
    String? cursoId,
  }) => repo.cadastrar(
    nomeCompleto: 'Bruno Lima',
    email: email,
    username: username,
    senha: 'segredo1',
    telefone: '(16)99999-0000',
    cpf: cpf,
    universidadeId: universidadeId,
    cursoId: cursoId,
  );

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

    test('entrar diz ao banco QUEM entrou', () async {
      // Sem isto, `GET /users/me` devolveria sempre a mesma conta. Era o que o
      // falso fazia antes de os dois repositórios compartilharem estado.
      await repo.entrar(
        email: Fixtures.emailSemVinculo,
        senha: Fixtures.senhaSemVinculo,
      );

      expect(banco.usuarioAtual.email, Fixtures.emailSemVinculo);
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
      expect((porSenha! as Failure).mensagem, (porEmail! as Failure).mensagem);
    });
  });

  group('cadastrar', () {
    test('cria a conta que o repositório de perfil enxerga', () async {
      await cadastrarBruno();
      await repo.entrar(email: 'novo@exemplo.com', senha: 'segredo1');

      final criado = banco.usuarioAtual;
      expect(criado.nomeCompleto, 'Bruno Lima');
      expect(criado.cpf, cpfNovo);
      expect(criado.tipo, TipoConta.aluno);
      // Conta de aluno nasce ativa; só a institucional fica pendente.
      expect(criado.aguardandoAtivacao, isFalse);
    });

    test('sem universidade e curso, a conta nasce sem formação', () async {
      // O ponto da v2: declarar formação virou opcional, porque não concede
      // acesso a nada. Exigir no cadastro só fazia todo mundo escolher a
      // primeira faculdade da lista.
      await cadastrarBruno();
      await repo.entrar(email: 'novo@exemplo.com', senha: 'segredo1');

      expect(banco.usuarioAtual.formacoes, isEmpty);
      expect(banco.usuarioAtual.vinculo, isNull);
    });

    test('com universidade e curso, cria formação SEM selo e SEM vínculo', () async {
      await cadastrarBruno(
        universidadeId: Fixtures.fatecRp.id,
        cursoId: Fixtures.ads.id,
      );
      await repo.entrar(email: 'novo@exemplo.com', senha: 'segredo1');

      final criado = banco.usuarioAtual;
      expect(criado.formacoes, hasLength(1));
      expect(criado.formacoes.single.universidade.id, Fixtures.fatecRp.id);
      // A distinção que o modelo inteiro existe para sustentar: declarar não é
      // ser verificado, e não abre os comunicados internos da instituição.
      expect(criado.formacoes.single.verificada, isFalse);
      expect(criado.vinculo, isNull);
    });

    test('só um dos dois campos de formação é recusado', () async {
      await expectLater(
        cadastrarBruno(universidadeId: Fixtures.fatecRp.id),
        throwsA(isA<FalhaDeValidacao>()),
      );
    });

    test('CPF inválido é recusado por validação, não por conflito', () async {
      await expectLater(
        cadastrarBruno(cpf: '11111111111'),
        throwsA(
          isA<FalhaDeValidacao>().having(
            (f) => f.primeiroErroDe('cpf'),
            'erro do campo cpf',
            'CPF inválido',
          ),
        ),
      );
    });

    test('CPF já cadastrado responde conflito', () async {
      // O CPF é único por conta porque é a chave que liga a conta às
      // matrículas: dois donos do mesmo número disputariam a mesma matrícula.
      await expectLater(
        cadastrarBruno(cpf: Fixtures.cpfAna),
        throwsA(
          isA<FalhaDeConflito>().having(
            (f) => f.mensagem,
            'mensagem',
            'CPF já cadastrado',
          ),
        ),
      );
    });

    test('e-mail já usado responde conflito, não validação', () async {
      // 409 e 422 são coisas distintas para o cliente: um é "já existe", o
      // outro é "formato inválido", e a tela reage diferente aos dois.
      await expectLater(
        cadastrarBruno(email: Fixtures.emailDemo),
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
        cadastrarBruno(username: Fixtures.perfilDemo.username),
        throwsA(isA<FalhaDeConflito>()),
      );
    });

    test('cadastro novo permite entrar em seguida', () async {
      await cadastrarBruno();
      await expectLater(
        repo.entrar(email: 'novo@exemplo.com', senha: 'segredo1'),
        completes,
      );
    });
  });

  group('cadastrarInstituicao', () {
    Future<void> cadastrarFaculdade({
      String cnpj = '11222333000181',
      String? sigla,
    }) => repo.cadastrarInstituicao(
      tipo: TipoConta.faculdade,
      nome: 'Instituto Federal de Exemplo',
      cnpj: cnpj,
      email: 'contato@ife.edu.br',
      username: 'ife_exemplo',
      senha: 'segredo1',
      telefone: '(16)3333-1111',
      sigla: sigla,
    );

    test('a conta nasce PENDENTE de ativação', () async {
      await cadastrarFaculdade();
      await repo.entrar(email: 'contato@ife.edu.br', senha: 'segredo1');

      final conta = banco.usuarioAtual;
      // `ativadaEm` nulo é o estado pendente. Sem ele, consultar o CNPJ público
      // de uma faculdade bastaria para distribuir formações "verificadas" no
      // nome dela — e o selo deixaria de significar algo.
      expect(conta.ativadaEm, isNull);
      expect(conta.aguardandoAtivacao, isTrue);
      expect(conta.tipo, TipoConta.faculdade);
      expect(conta.cnpj, '11222333000181');
      // Organização não estuda em lugar nenhum, e CPF é de pessoa.
      expect(conta.cpf, isNull);
    });

    test('faculdade nova entra no catálogo de universidades', () async {
      final antes = banco.universidades.length;
      await cadastrarFaculdade(sigla: 'IFE');

      expect(banco.universidades, hasLength(antes + 1));
      expect(banco.universidades.last.sigla, 'IFE');
      expect(banco.universidades.last.temConta, isTrue);
    });

    test('faculdade já administrada responde conflito', () async {
      // A FATEC semeada já tem conta. Uma segunda apareceria na busca como uma
      // segunda FATEC, com os alunos divididos entre as duas.
      await expectLater(
        cadastrarFaculdade(sigla: Fixtures.fatecRp.sigla),
        throwsA(
          isA<FalhaDeConflito>().having(
            (f) => f.mensagem,
            'mensagem',
            'Esta instituição já tem uma conta cadastrada',
          ),
        ),
      );
    });

    test('CNPJ inválido é recusado', () async {
      await expectLater(
        cadastrarFaculdade(cnpj: '00000000000000'),
        throwsA(isA<FalhaDeValidacao>()),
      );
    });

    test('CNPJ já cadastrado responde conflito', () async {
      await expectLater(
        cadastrarFaculdade(cnpj: Fixtures.cnpjFatec),
        throwsA(
          isA<FalhaDeConflito>().having(
            (f) => f.mensagem,
            'mensagem',
            'CNPJ já cadastrado',
          ),
        ),
      );
    });

    test('empresa não cria universidade nenhuma', () async {
      final antes = banco.universidades.length;
      await repo.cadastrarInstituicao(
        tipo: TipoConta.empresa,
        nome: 'Nova Empresa',
        cnpj: '11222333000181',
        email: 'rh@nova.com.br',
        username: 'nova_empresa',
        senha: 'segredo1',
        telefone: '(16)3333-2222',
      );

      expect(banco.universidades, hasLength(antes));
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
    setUp(
      () => repo.entrar(email: Fixtures.emailDemo, senha: Fixtures.senhaDemo),
    );

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
