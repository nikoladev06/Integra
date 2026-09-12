import 'package:integra/core/network/api_client.dart';
import 'package:integra/features/auth/data/auth_repository.dart';
import 'package:integra/features/auth/data/models/par_de_tokens.dart';

/// [AuthRepository] contra o `auth-service` real.
///
/// **Esta classe é a troca de uma linha do plano.** Ela existe desde já, com os
/// caminhos exatamente como `contracts/auth.openapi.yaml` declara, mesmo antes
/// de o serviço implementar as rotas — o que o guarda de contrato em
/// `services/shared/tests/test_contratos.py` lista como pendente é exatamente
/// o que falta para ela funcionar.
///
/// Escrever isto agora, e não na Sprint 3, é o que garante que a interface foi
/// desenhada para uma API HTTP de verdade, e não só para o que o falso faz.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> cadastrar({
    required String nomeCompleto,
    required String email,
    required String username,
    required String senha,
    required String telefone,
    required String universidadeId,
    required String cursoId,
  }) => _api.postSemCorpo(
    '/auth/register',
    corpo: {
      'nomeCompleto': nomeCompleto,
      'email': email,
      'username': username,
      'senha': senha,
      'telefone': telefone,
      'universidadeId': universidadeId,
      'cursoId': cursoId,
    },
  );

  @override
  Future<ParDeTokens> entrar({
    required String email,
    required String senha,
  }) async {
    final dados = await _api.post(
      '/auth/login',
      corpo: {'email': email, 'senha': senha},
    );
    return ParDeTokens.fromJson(dados);
  }

  @override
  Future<ParDeTokens> renovar(String refreshToken) async {
    final dados = await _api.post(
      '/auth/refresh',
      corpo: {'refreshToken': refreshToken},
    );
    return ParDeTokens.fromJson(dados);
  }

  @override
  Future<void> sair(String refreshToken) =>
      _api.postSemCorpo('/auth/logout', corpo: {'refreshToken': refreshToken});

  @override
  Future<void> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmacao,
  }) => _api.put(
    '/auth/password',
    corpo: {
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
      'confirmacao': confirmacao,
    },
  );
}
