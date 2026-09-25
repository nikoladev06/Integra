import 'package:integra/core/error/failure.dart';
import 'package:integra/features/auth/data/auth_repository.dart';
import 'package:integra/features/auth/data/models/par_de_tokens.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/shared/domain/documentos.dart';

/// Implementação em memória de [AuthRepository], para o app rodar sem backend.
///
/// Não é um dublê vazio: reproduz os erros que o contrato declara — 409 de
/// e-mail, username, CPF e CNPJ duplicados, 401 de credencial errada, revogação
/// de sessão na troca de senha, e a conta institucional nascendo **pendente**.
/// Um falso que só devolve sucesso esconde exatamente os caminhos de erro que as
/// telas precisam tratar.
///
/// Escreve no mesmo [BancoFalso] que o repositório de perfil lê. Antes eram dois
/// estados separados, e cadastrar criava um usuário que `GET /users/me` nunca
/// via — quem se cadastrava entrava e encontrava o nome de outra pessoa.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._banco, {Duration? latencia})
    : _latencia = latencia ?? const Duration(milliseconds: 400);

  final BancoFalso _banco;

  /// Latência simulada, para os estados de carregamento serem visíveis em
  /// desenvolvimento. Os testes passam `Duration.zero`.
  final Duration _latencia;

  /// Refresh tokens válidos. Renovar consome o antigo, como o contrato manda.
  final Set<String> _refreshValidos = {};

  int _contador = 0;

  Future<void> _esperar() => Future<void>.delayed(_latencia);

  ParDeTokens _emitir() {
    _contador++;
    final refresh = 'fake-refresh-$_contador';
    _refreshValidos.add(refresh);
    return ParDeTokens(
      accessToken: 'fake-access-$_contador',
      refreshToken: refresh,
      expiresIn: 900,
    );
  }

  /// As unicidades que o `auth-service` confere, na mesma ordem em que ele as
  /// confere — a ordem decide qual mensagem o usuário vê quando colide em mais
  /// de uma.
  void _garantirDisponivel({
    required String email,
    required String username,
    String? cpf,
    String? cnpj,
  }) {
    if (_banco.senhas.containsKey(email)) {
      throw const FalhaDeConflito('Email já cadastrado');
    }
    if (_banco.usuarios.values.any((u) => u.username == username)) {
      throw const FalhaDeConflito('Username já existe');
    }
    if (cpf != null && _banco.usuarios.values.any((u) => u.cpf == cpf)) {
      throw const FalhaDeConflito('CPF já cadastrado');
    }
    if (cnpj != null && _banco.usuarios.values.any((u) => u.cnpj == cnpj)) {
      throw const FalhaDeConflito('CNPJ já cadastrado');
    }
  }

  @override
  Future<void> cadastrar({
    required String nomeCompleto,
    required String email,
    required String username,
    required String senha,
    required String telefone,
    required String cpf,
    String? universidadeId,
    String? cursoId,
  }) async {
    await _esperar();

    final emailNormalizado = email.trim().toLowerCase();
    final usernameNormalizado = username.trim().toLowerCase();
    final digitos = normalizarCpf(cpf);

    if (!cpfEValido(digitos)) {
      throw const FalhaDeValidacao(
        campos: {
          'cpf': ['CPF inválido'],
        },
      );
    }
    // Os dois juntos, ou nenhum: meia formação é uma linha de currículo que
    // nenhuma tela sabe exibir, e o serviço recusa pelo mesmo critério.
    if ((universidadeId == null) != (cursoId == null)) {
      throw const FalhaDeValidacao(
        campos: {
          'cursoId': ['Escolha também o curso'],
        },
      );
    }

    _garantirDisponivel(
      email: emailNormalizado,
      username: usernameNormalizado,
      cpf: digitos,
    );

    final agora = DateTime.now().toUtc();

    // Formação **declarada**: nasce sem selo e não cria vínculo nenhum. O
    // vínculo só nasce pelo CPF conferido contra a lista da instituição.
    final formacoes = <Formacao>[];
    if (universidadeId != null && cursoId != null) {
      final universidade = _banco.universidadePorId(universidadeId);
      final curso = _banco.cursoPorId(universidadeId, cursoId);
      if (universidade == null || curso == null) {
        throw const FalhaDeValidacao(
          campos: {
            'cursoId': ['Curso não pertence a esta universidade'],
          },
        );
      }
      formacoes.add(
        Formacao(
          id: _banco.proximoId('form'),
          universidade: universidade,
          curso: curso,
          criadoEm: agora,
        ),
      );
    }

    _banco.salvar(
      Perfil(
        id: _banco.proximoId('user'),
        nomeCompleto: nomeCompleto.trim(),
        username: usernameNormalizado,
        tipo: TipoConta.aluno,
        criadoEm: agora,
        email: emailNormalizado,
        cpf: digitos,
        telefone: telefone.trim(),
        formacoes: formacoes,
        // Conta de aluno nasce ativa. Só a institucional fica pendente.
        ativadaEm: agora,
      ),
    );
    _banco.senhas[emailNormalizado] = senha;
  }

  @override
  Future<void> cadastrarInstituicao({
    required TipoConta tipo,
    required String nome,
    required String cnpj,
    required String email,
    required String username,
    required String senha,
    required String telefone,
    String? sigla,
  }) async {
    await _esperar();

    final emailNormalizado = email.trim().toLowerCase();
    final usernameNormalizado = username.trim().toLowerCase();
    final digitos = normalizarCnpj(cnpj);

    if (!tipo.eInstitucional) {
      throw const FalhaDeValidacao(
        campos: {
          'tipo': ['Use o cadastro de aluno'],
        },
      );
    }
    if (!cnpjEValido(digitos)) {
      throw const FalhaDeValidacao(
        campos: {
          'cnpj': ['CNPJ inválido'],
        },
      );
    }

    _garantirDisponivel(
      email: emailNormalizado,
      username: usernameNormalizado,
      cnpj: digitos,
    );

    if (tipo == TipoConta.faculdade) {
      _reivindicarOuCriarUniversidade(nome: nome, sigla: sigla);
    }

    _banco.salvar(
      Perfil(
        id: _banco.proximoId('user'),
        nomeCompleto: nome.trim(),
        username: usernameNormalizado,
        tipo: tipo,
        criadoEm: DateTime.now().toUtc(),
        email: emailNormalizado,
        cnpj: digitos,
        telefone: telefone.trim(),
        // **Nasce pendente**, com `ativadaEm` nulo. CNPJ é dado público e não
        // prova quem digitou; sem este estado, consultar o CNPJ de uma
        // faculdade bastaria para distribuir formações "verificadas" no nome
        // dela, e o selo deixaria de significar algo.
      ),
    );
    _banco.senhas[emailNormalizado] = senha;
  }

  /// No serviço, é o **CNPJ** que decide a identidade da instituição: casando
  /// com uma universidade catalogada e sem conta, a conta reivindica aquela
  /// linha — a mesma que os alunos já seguem e declararam. Sem isso apareceriam
  /// duas FATEC na busca, com os alunos divididos entre elas.
  ///
  /// O catálogo semeado aqui não guarda CNPJ (ele não sai em nenhuma resposta
  /// do contrato), então o falso casa pela sigla. É a única regra em que ele se
  /// afasta do serviço, e se afasta para menos: a demonstração do conflito
  /// continua possível, a do casamento por número não.
  void _reivindicarOuCriarUniversidade({
    required String nome,
    required String? sigla,
  }) {
    final rotulo = (sigla ?? '').trim();
    final catalogada = _banco.universidades
        .where((u) => rotulo.isNotEmpty && u.sigla == rotulo)
        .firstOrNull;

    if (catalogada != null) {
      if (catalogada.temConta) {
        throw const FalhaDeConflito(
          'Esta instituição já tem uma conta cadastrada',
        );
      }
      _banco.universidades[_banco.universidades.indexOf(catalogada)] =
          catalogada.copyWith(temConta: true);
      return;
    }

    final nova = Universidade(
      id: _banco.proximoId('uni'),
      nome: nome.trim(),
      sigla: rotulo.isEmpty ? _iniciaisDe(nome) : rotulo,
      temConta: true,
    );
    _banco.universidades.add(nova);
    _banco.cursos[nova.id] = [];
  }

  /// Rótulo curto para a instituição que não informou sigla, até ela editar o
  /// perfil.
  static String _iniciaisDe(String nome) => nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.length > 2)
      .map((p) => p[0].toUpperCase())
      .take(5)
      .join();

  @override
  Future<ParDeTokens> entrar({
    required String email,
    required String senha,
  }) async {
    await _esperar();

    final normalizado = email.trim().toLowerCase();
    final esperada = _banco.senhas[normalizado];
    // Mensagem única para e-mail inexistente e senha errada, como o contrato
    // determina: distinguir os dois entrega uma sonda de quais e-mails existem.
    if (esperada == null || esperada != senha) {
      throw const FalhaDeAutenticacao();
    }

    _banco.usuarioAtualId = _banco.usuarios.values
        .firstWhere((u) => u.email == normalizado)
        .id;
    return _emitir();
  }

  @override
  Future<ParDeTokens> renovar(String refreshToken) async {
    await _esperar();

    if (!_refreshValidos.remove(refreshToken)) {
      throw const FalhaDeAutenticacao('Sessão expirada. Faça login novamente.');
    }
    return _emitir();
  }

  @override
  Future<void> sair(String refreshToken) async {
    await _esperar();
    // Idempotente de propósito: o contrato responde 204 mesmo para token já
    // inválido, porque o cliente não tem o que fazer com um erro aqui.
    _refreshValidos.remove(refreshToken);
    _banco.usuarioAtualId = null;
  }

  @override
  Future<void> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmacao,
  }) async {
    await _esperar();

    final email = _banco.usuarioAtual.email!;
    if (_banco.senhas[email] != senhaAtual) {
      throw const FalhaDeAutenticacao('Senha atual está incorreta');
    }
    if (novaSenha != confirmacao) {
      throw const FalhaDeValidacao(
        campos: {
          'confirmacao': ['As senhas não correspondem'],
        },
      );
    }

    _banco.senhas[email] = novaSenha;
    // Trocar a senha revoga todas as sessões, inclusive a que fez a troca.
    _refreshValidos.clear();
  }
}
