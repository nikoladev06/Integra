import 'package:integra/core/error/failure.dart';
import 'package:integra/features/auth/data/auth_repository.dart';
import 'package:integra/features/auth/data/models/par_de_tokens.dart';
import 'package:integra/features/profile/data/fixtures.dart';

/// Implementação em memória de [AuthRepository], usada enquanto o
/// `auth-service` não existe.
///
/// Não é um dublê vazio: reproduz os erros que o contrato declara — 409 de
/// e-mail duplicado, 401 de credencial errada, revogação de sessão na troca de
/// senha. Um falso que só devolve sucesso esconde exatamente os caminhos de
/// erro que as telas precisam tratar, e a tela de login nasceria sem o estado
/// de falha.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({Duration? latencia})
    : _latencia = latencia ?? const Duration(milliseconds: 400);

  /// Latência simulada, para os estados de carregamento serem visíveis em
  /// desenvolvimento. Os testes passam `Duration.zero`.
  final Duration _latencia;

  /// E-mail → senha. Começa com a conta de exemplo das fixtures.
  final Map<String, String> _credenciais = {
    Fixtures.emailDemo: Fixtures.senhaDemo,
  };

  final Set<String> _usernames = {Fixtures.perfilDemo.username};

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

  @override
  Future<void> cadastrar({
    required String nomeCompleto,
    required String email,
    required String username,
    required String senha,
    required String telefone,
    required String universidadeId,
    required String cursoId,
  }) async {
    await _esperar();

    final emailNormalizado = email.trim().toLowerCase();
    final usernameNormalizado = username.trim().toLowerCase();

    if (_credenciais.containsKey(emailNormalizado)) {
      throw const FalhaDeConflito('Email já cadastrado');
    }
    if (_usernames.contains(usernameNormalizado)) {
      throw const FalhaDeConflito('Username já existe');
    }

    _credenciais[emailNormalizado] = senha;
    _usernames.add(usernameNormalizado);
  }

  @override
  Future<ParDeTokens> entrar({
    required String email,
    required String senha,
  }) async {
    await _esperar();

    final esperada = _credenciais[email.trim().toLowerCase()];
    // Mensagem única para e-mail inexistente e senha errada, como o contrato
    // determina: distinguir os dois entrega uma sonda de quais e-mails existem.
    if (esperada == null || esperada != senha) {
      throw const FalhaDeAutenticacao();
    }
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
  }

  @override
  Future<void> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmacao,
  }) async {
    await _esperar();

    if (_credenciais[Fixtures.emailDemo] != senhaAtual) {
      throw const FalhaDeAutenticacao('Senha atual está incorreta');
    }
    if (novaSenha != confirmacao) {
      throw const FalhaDeValidacao(
        campos: {'confirmacao': ['As senhas não correspondem']},
      );
    }

    _credenciais[Fixtures.emailDemo] = novaSenha;
    // Trocar a senha revoga todas as sessões, inclusive a que fez a troca.
    _refreshValidos.clear();
  }
}
