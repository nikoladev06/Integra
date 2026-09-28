import 'package:integra/core/network/api_client.dart';
import 'package:integra/features/academic/data/academic_repository.dart';
import 'package:integra/features/academic/data/models/post.dart';

/// [AcademicRepository] contra o `academic-service` real.
///
/// Todos os caminhos começam em `/academic`, inclusive o de posts de uma
/// universidade: no gateway, `/academic/universidades/{id}/posts` não compete com
/// o `/universidades` do `user-service`. Um prefixo comum por serviço é o que
/// permite o Traefik rotear por `PathPrefix` sem regra de exceção.
class ApiAcademicRepository implements AcademicRepository {
  ApiAcademicRepository(this._api);

  final ApiClient _api;

  // ──────────────────────────────  leitura  ──────────────────────────────

  @override
  Future<PaginaDePosts> feed({
    EscopoDoFeed escopo = EscopoDoFeed.geral,
    String? cursor,
  }) async => PaginaDePosts.fromJson(
    await _api.get(
      '/academic/posts',
      query: {'escopo': escopo.valor, if (cursor != null) 'cursor': cursor},
    ),
  );

  @override
  Future<PaginaDePosts> postsDaUniversidade(
    String universidadeId, {
    Visibilidade? visibilidade,
    String? cursor,
  }) async => PaginaDePosts.fromJson(
    await _api.get(
      '/academic/universidades/$universidadeId/posts',
      query: {
        if (visibilidade != null) 'visibilidade': visibilidade.name,
        if (cursor != null) 'cursor': cursor,
      },
    ),
  );

  @override
  Future<Post> post(String postId) async =>
      Post.fromJson(await _api.get('/academic/posts/$postId'));

  @override
  Future<PaginaDeComentarios> comentarios(
    String postId, {
    String? cursor,
  }) async => PaginaDeComentarios.fromJson(
    await _api.get(
      '/academic/posts/$postId/comentarios',
      query: {if (cursor != null) 'cursor': cursor},
    ),
  );

  // ─────────────────────────────  publicação  ─────────────────────────────

  @override
  Future<Post> publicar({
    required String conteudo,
    required Visibilidade visibilidade,
    String? cursoId,
  }) async => Post.fromJson(
    await _api.post(
      '/academic/posts',
      corpo: {
        'conteudo': conteudo,
        'visibilidade': visibilidade.name,
        // Só vai quando o alcance é `curso`: o serviço **recusa** `cursoId` nos
        // outros dois, em vez de ignorá-lo. Mandar sempre renderia 422 num post
        // institucional.
        if (visibilidade == Visibilidade.curso && cursoId != null)
          'cursoId': cursoId,
      },
    ),
  );

  @override
  Future<Post> editar(
    String postId, {
    String? conteudo,
    Visibilidade? visibilidade,
    String? cursoId,
  }) async {
    // Só os campos informados vão no corpo: o contrato manda o `PATCH` deixar
    // inalterado o que for omitido.
    //
    // `cursoId` acompanha a visibilidade em vez de ir por conta própria. Sair de
    // `curso` para outro alcance **limpa** a restrição no servidor, então mandar
    // o `cursoId` antigo junto de `visibilidade: publico` renderia 422 — o que,
    // aliás, é a resposta certa: o servidor não adivinha qual dos dois campos
    // está errado.
    final corpo = <String, dynamic>{
      if (conteudo != null) 'conteudo': conteudo,
      if (visibilidade != null) 'visibilidade': visibilidade.name,
      if (visibilidade == Visibilidade.curso && cursoId != null)
        'cursoId': cursoId,
    };
    return Post.fromJson(
      await _api.patch('/academic/posts/$postId', corpo: corpo),
    );
  }

  @override
  Future<void> remover(String postId) => _api.delete('/academic/posts/$postId');

  // ──────────────────────  curtidas e comentários  ──────────────────────

  @override
  Future<void> curtir(String postId, {required bool curtir}) {
    final caminho = '/academic/posts/$postId/curtidas';
    // `PUT` e `DELETE`, como em seguir universidade: o método já diz que repetir
    // não acumula, sem o servidor ter que ler corpo para decidir.
    return curtir ? _api.put(caminho) : _api.delete(caminho);
  }

  @override
  Future<Comentario> comentar(String postId, String conteudo) async =>
      Comentario.fromJson(
        await _api.post(
          '/academic/posts/$postId/comentarios',
          corpo: {'conteudo': conteudo},
        ),
      );

  @override
  Future<void> removerComentario(String comentarioId) =>
      _api.delete('/academic/comentarios/$comentarioId');
}
