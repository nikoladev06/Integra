import 'package:integra/core/network/api_client.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/data/profile_repository.dart';

/// [ProfileRepository] contra o `user-service` real.
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<Perfil> meuPerfil() async =>
      Perfil.fromJson(await _api.get('/users/me'));

  @override
  Future<Perfil> perfilDe(String userId) async =>
      Perfil.fromJson(await _api.get('/users/$userId'));

  @override
  Future<Perfil> atualizarMeuPerfil({
    String? nomeCompleto,
    String? username,
    String? telefone,
    String? bio,
    String? universidadeId,
    String? cursoId,
  }) async {
    // Só os campos informados vão no corpo: o contrato manda `PATCH` deixar
    // inalterado o que foi omitido, e enviar `null` apagaria o valor.
    final corpo = <String, dynamic>{
      if (nomeCompleto != null) 'nomeCompleto': nomeCompleto,
      if (username != null) 'username': username,
      if (telefone != null) 'telefone': telefone,
      if (bio != null) 'bio': bio,
      if (universidadeId != null) 'universidadeId': universidadeId,
      if (cursoId != null) 'cursoId': cursoId,
    };
    return Perfil.fromJson(await _api.patch('/users/me', corpo: corpo));
  }

  @override
  Future<List<Perfil>> buscar(String termo, {String? universidadeId}) async {
    final itens = await _api.getLista(
      '/users',
      query: {
        'q': termo,
        if (universidadeId != null) 'universidadeId': universidadeId,
      },
    );
    return itens
        .map((e) => Perfil.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Universidade>> universidades() async {
    final itens = await _api.getLista('/universidades');
    return itens
        .map((e) => Universidade.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Curso>> cursosDe(String universidadeId) async {
    final itens = await _api.getLista('/universidades/$universidadeId/cursos');
    return itens.map((e) => Curso.fromJson(e as Map<String, dynamic>)).toList();
  }
}
