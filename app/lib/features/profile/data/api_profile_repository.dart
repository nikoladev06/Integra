import 'package:integra/core/network/api_client.dart';
import 'package:integra/features/profile/data/models/instituicao.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/data/profile_repository.dart';
import 'package:integra/shared/domain/documentos.dart';

/// [ProfileRepository] contra o `user-service` real.
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api);

  final ApiClient _api;

  // ──────────────────────────────  perfil  ──────────────────────────────

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
  }) async {
    // Só os campos informados vão no corpo: o contrato manda `PATCH` deixar
    // inalterado o que foi omitido, e enviar `null` apagaria o valor.
    final corpo = <String, dynamic>{
      if (nomeCompleto != null) 'nomeCompleto': nomeCompleto,
      if (username != null) 'username': username,
      if (telefone != null) 'telefone': telefone,
      if (bio != null) 'bio': bio,
    };
    return Perfil.fromJson(await _api.patch('/users/me', corpo: corpo));
  }

  // ────────────────────────────  formação  ────────────────────────────

  @override
  Future<Formacao> declararFormacao({
    required String universidadeId,
    required String cursoId,
  }) async => Formacao.fromJson(
    await _api.post(
      '/users/me/formacoes',
      corpo: {'universidadeId': universidadeId, 'cursoId': cursoId},
    ),
  );

  @override
  Future<void> removerFormacao(String formacaoId) =>
      _api.delete('/users/me/formacoes/$formacaoId');

  // ─────────────────────────────  vínculo  ─────────────────────────────

  @override
  Future<Vinculo?> meuVinculo() async {
    // A rota devolve `null` quando não há vínculo, e o corpo nulo chega aqui
    // como mapa vazio. Sem vínculo é o estado normal de quem acabou de entrar,
    // não um erro.
    final dados = await _api.get('/users/me/vinculo');
    return dados.isEmpty ? null : Vinculo.fromJson(dados);
  }

  @override
  Future<Vinculo> criarVinculo({
    required String universidadeId,
    required String cpf,
  }) async => Vinculo.fromJson(
    await _api.post(
      '/universidades/$universidadeId/vinculo',
      // Normalizado aqui: o campo aceita pontuação para quem digita, e o
      // serviço compara contra os 11 dígitos guardados.
      corpo: {'cpf': normalizarCpf(cpf)},
    ),
  );

  @override
  Future<void> encerrarVinculo() => _api.delete('/users/me/vinculo');

  // ───────────────────────────  catálogo e busca  ───────────────────────────

  @override
  Future<List<Universidade>> universidades({String? termo}) async {
    final itens = await _api.getLista(
      '/universidades',
      query: {
        if (termo != null && termo.isNotEmpty) 'q': termo,
      },
    );
    return itens
        .map((e) => Universidade.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Curso>> cursosDe(String universidadeId) async {
    final itens = await _api.getLista('/universidades/$universidadeId/cursos');
    return itens.map((e) => Curso.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<PerfilDeUniversidade> perfilDaUniversidade(
    String universidadeId,
  ) async => PerfilDeUniversidade.fromJson(
    await _api.get('/universidades/$universidadeId'),
  );

  @override
  Future<ResultadoDeBusca> buscar(String termo) async =>
      ResultadoDeBusca.fromJson(await _api.get('/busca', query: {'q': termo}));

  @override
  Future<List<Perfil>> buscarPessoas(
    String termo, {
    String? universidadeId,
    String? cursoId,
  }) async {
    final itens = await _api.getLista(
      '/users',
      query: {
        'q': termo,
        if (universidadeId != null) 'universidadeId': universidadeId,
        if (cursoId != null) 'cursoId': cursoId,
      },
    );
    return itens
        .map((e) => Perfil.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────  seguir  ─────────────────────────────

  @override
  Future<List<UniversidadeSeguida>> universidadesSeguidas() async {
    final itens = await _api.getLista('/users/me/seguindo/universidades');
    return itens
        .map((e) => UniversidadeSeguida.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> seguirUniversidade(
    String universidadeId, {
    required bool seguir,
  }) {
    final caminho = '/users/me/seguindo/universidades/$universidadeId';
    // `PUT` e `DELETE` em vez de um `POST /seguir` com corpo booleano: seguir é
    // idempotente, e o método HTTP já diz isso sem o servidor ter que ler o
    // corpo para saber o que fazer.
    return seguir ? _api.put(caminho) : _api.delete(caminho);
  }
}
