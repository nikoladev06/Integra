import 'dart:typed_data';

import 'package:integra/core/network/api_client.dart';
import 'package:integra/features/profile/data/models/instituicao.dart';
import 'package:integra/features/professional/data/api_feed_repository.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';
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
    String? fotoUrl,
  }) async {
    // Só os campos informados vão no corpo: o contrato manda `PATCH` deixar
    // inalterado o que foi omitido, e enviar `null` apagaria o valor.
    final corpo = <String, dynamic>{
      if (nomeCompleto != null) 'nomeCompleto': nomeCompleto,
      if (username != null) 'username': username,
      if (telefone != null) 'telefone': telefone,
      if (bio != null) 'bio': bio,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
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
      query: {if (termo != null && termo.isNotEmpty) 'q': termo},
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

  @override
  Future<List<Perfil>> usuariosSeguidos() async {
    final itens = await _api.getLista('/users/me/seguindo/usuarios');
    return itens
        .map((e) => Perfil.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> seguirUsuario(String userId, {required bool seguir}) {
    final caminho = '/users/me/seguindo/usuarios/$userId';
    return seguir ? _api.put(caminho) : _api.delete(caminho);
  }

  // ───────────────  administração da própria instituição  ───────────────

  @override
  Future<List<Curso>> meusCursos() async {
    final itens = await _api.getLista('/universidades/me/cursos');
    return itens.map((e) => Curso.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Curso> criarCurso(String nome) async => Curso.fromJson(
    await _api.post('/universidades/me/cursos', corpo: {'nome': nome.trim()}),
  );

  @override
  Future<void> removerCurso(String cursoId) =>
      _api.delete('/universidades/me/cursos/$cursoId');

  @override
  Future<List<Matricula>> minhasMatriculas({
    String? cursoId,
    String situacao = 'todas',
  }) async {
    final itens = await _api.getLista(
      '/universidades/me/matriculas',
      query: {'situacao': situacao, if (cursoId != null) 'cursoId': cursoId},
    );
    return itens
        .map((e) => Matricula.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Matricula> criarMatricula({
    required String cpf,
    required String cursoId,
  }) async => Matricula.fromJson(
    await _api.post(
      '/universidades/me/matriculas',
      // Normalizado aqui: o campo aceita pontuação para quem digita, e o serviço
      // guarda só os 11 dígitos. A unicidade do CPF depende de os dois lados
      // gravarem no mesmo formato — com e sem pontuação seriam duas linhas para
      // a mesma pessoa, e nenhuma delas casaria com a conta dela.
      corpo: {'cpf': normalizarCpf(cpf), 'cursoId': cursoId},
    ),
  );

  @override
  Future<void> removerMatricula(String matriculaId) =>
      _api.delete('/universidades/me/matriculas/$matriculaId');

  // ──────────────────────────  foto de perfil  ──────────────────────────

  @override
  Future<UrlDeUpload> urlDeUploadDeAvatar({
    required String contentType,
    required int tamanhoBytes,
  }) async {
    final corpo = await _api.post(
      '/users/me/avatar/upload-url',
      corpo: {'contentType': contentType, 'tamanhoBytes': tamanhoBytes},
    );
    // `fotoUrl` aqui, `imagemUrl` na rota do feed: os dois contratos nomeiam o
    // campo pelo que ele vai virar no destino. [UrlDeUpload] os unifica em
    // `urlFinal`, porque para o `PUT` a diferença não existe — e dois tipos
    // idênticos divergiriam no primeiro campo novo.
    return UrlDeUpload(
      uploadUrl: corpo['uploadUrl'] as String,
      urlFinal: corpo['fotoUrl'] as String,
      expiraEm: DateTime.parse(corpo['expiraEm'] as String),
    );
  }

  @override
  Future<void> enviarAvatar(
    UrlDeUpload destino,
    Uint8List bytes, {
    required String contentType,
  }) => enviarParaStorage(destino, bytes, contentType: contentType);
}
