import 'package:integra/core/network/api_client.dart';
import 'package:integra/features/auth/data/auth_repository.dart';
import 'package:integra/features/auth/data/models/par_de_tokens.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/shared/domain/documentos.dart';

/// [AuthRepository] contra o `auth-service` real.
///
/// Os caminhos são exatamente os de `contracts/auth.openapi.yaml`, e o guarda de
/// deriva em `services/shared/tests/test_contratos.py` reprova a CI se o serviço
/// expuser algo que o contrato não declara.
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
    required String cpf,
    String? universidadeId,
    String? cursoId,
  }) => _api.postSemCorpo(
    '/auth/register',
    corpo: {
      'nomeCompleto': nomeCompleto,
      'email': email,
      'username': username,
      'senha': senha,
      'telefone': telefone,
      // Normalizado aqui, e não só no servidor: o campo aceita pontuação para
      // quem digita, mas o que trafega é o que o banco guarda.
      'cpf': normalizarCpf(cpf),
      // Omitidos quando não há formação declarada. Mandar `null` não é o mesmo:
      // o schema aceita o campo ausente, e enviar a chave vazia só aumenta a
      // superfície de um corpo que o servidor já valida aos pares.
      if (universidadeId != null && universidadeId.isNotEmpty)
        'universidadeId': universidadeId,
      if (cursoId != null && cursoId.isNotEmpty) 'cursoId': cursoId,
    },
  );

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
  }) {
    assert(
      tipo.eInstitucional,
      'aluno não se cadastra aqui; use cadastrar()',
    );
    return _api.postSemCorpo(
      '/auth/register/instituicao',
      corpo: {
        'tipo': tipo.name,
        'nome': nome,
        'cnpj': normalizarCnpj(cnpj),
        'email': email,
        'username': username,
        'senha': senha,
        'telefone': telefone,
        if (sigla != null && sigla.isNotEmpty) 'sigla': sigla,
      },
    );
  }

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
