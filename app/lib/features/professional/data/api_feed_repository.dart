import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/network/api_client.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/professional/data/feed_repository.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';

/// [FeedRepository] contra o `feed-service` real.
///
/// Todos os caminhos começam em `/feed`, inclusive o de posts de um usuário: no
/// gateway, `/feed/usuarios/{id}/posts` não compete com o `/users` do `user-service`.
/// Um prefixo comum por serviço é o que permite o Traefik rotear por `PathPrefix`
/// sem regra de exceção.
class ApiFeedRepository implements FeedRepository {
  ApiFeedRepository(this._api);

  final ApiClient _api;

  // ──────────────────────────────  leitura  ──────────────────────────────

  @override
  Future<PaginaDePostsProfissionais> feed({
    EscopoDoProfissional escopo = EscopoDoProfissional.geral,
    String? cursor,
  }) async => PaginaDePostsProfissionais.fromJson(
    await _api.get(
      '/feed/posts',
      query: {'escopo': escopo.valor, if (cursor != null) 'cursor': cursor},
    ),
  );

  @override
  Future<PaginaDePostsProfissionais> postsDoUsuario(
    String userId, {
    String? cursor,
  }) async => PaginaDePostsProfissionais.fromJson(
    await _api.get(
      '/feed/usuarios/$userId/posts',
      query: {if (cursor != null) 'cursor': cursor},
    ),
  );

  @override
  Future<PostProfissional> post(String postId) async =>
      PostProfissional.fromJson(await _api.get('/feed/posts/$postId'));

  @override
  Future<PaginaDeComentariosProfissionais> comentarios(
    String postId, {
    String? cursor,
  }) async => PaginaDeComentariosProfissionais.fromJson(
    await _api.get(
      '/feed/posts/$postId/comentarios',
      query: {if (cursor != null) 'cursor': cursor},
    ),
  );

  // ─────────────────────────────  publicação  ─────────────────────────────

  @override
  Future<PostProfissional> publicar({
    required String conteudo,
    String? imagemUrl,
  }) async => PostProfissional.fromJson(
    await _api.post(
      '/feed/posts',
      corpo: {
        'conteudo': conteudo,
        if (imagemUrl != null) 'imagemUrl': imagemUrl,
      },
    ),
  );

  @override
  Future<PostProfissional> editar(
    String postId, {
    String? conteudo,
    String? imagemUrl,
    bool removerImagem = false,
  }) async {
    // As três combinações do contrato, e a terceira é a que exige o parâmetro
    // separado: omitir `imagemUrl` mantém a imagem, mandar uma troca, e mandar
    // `null` **explícito** remove. Com um `String?` só, "remover" e "não mexer"
    // seriam a mesma chamada.
    final corpo = <String, dynamic>{
      if (conteudo != null) 'conteudo': conteudo,
      if (removerImagem) 'imagemUrl': null else if (imagemUrl != null) 'imagemUrl': imagemUrl,
    };
    return PostProfissional.fromJson(
      await _api.patch('/feed/posts/$postId', corpo: corpo),
    );
  }

  @override
  Future<void> remover(String postId) => _api.delete('/feed/posts/$postId');

  // ──────────────────────  curtidas e comentários  ──────────────────────

  @override
  Future<void> curtir(String postId, {required bool curtir}) {
    final caminho = '/feed/posts/$postId/curtidas';
    return curtir ? _api.put(caminho) : _api.delete(caminho);
  }

  @override
  Future<ComentarioProfissional> comentar(String postId, String conteudo) async =>
      ComentarioProfissional.fromJson(
        await _api.post(
          '/feed/posts/$postId/comentarios',
          corpo: {'conteudo': conteudo},
        ),
      );

  @override
  Future<void> removerComentario(String comentarioId) =>
      _api.delete('/feed/comentarios/$comentarioId');

  // ──────────────────────────────  imagem  ──────────────────────────────

  @override
  Future<UrlDeUpload> urlDeUploadDeImagem({
    required String contentType,
    required int tamanhoBytes,
  }) async {
    final corpo = await _api.post(
      '/feed/posts/imagem/upload-url',
      corpo: {'contentType': contentType, 'tamanhoBytes': tamanhoBytes},
    );
    return UrlDeUpload(
      uploadUrl: corpo['uploadUrl'] as String,
      urlFinal: corpo['imagemUrl'] as String,
      expiraEm: DateTime.parse(corpo['expiraEm'] as String),
    );
  }

  @override
  Future<void> enviarImagem(
    UrlDeUpload destino,
    Uint8List bytes, {
    required String contentType,
  }) => enviarParaStorage(destino, bytes, contentType: contentType);
}

/// O `PUT` dos bytes numa URL pré-assinada.
///
/// Fora de qualquer classe porque **não é uma chamada à nossa API** e as duas rotas
/// de upload — avatar no `user-service` e imagem de post no `feed-service` — fazem
/// exatamente o mesmo `PUT`. Duplicá-la nos dois repositórios seria duplicar a parte
/// que é fácil de errar.
///
/// Usa um `Dio` cru, e não o [ApiClient], por três razões que são todas sobre o
/// storage não ser a nossa API:
///
/// 1. **Sem `baseUrl`.** A URL vem assinada e absoluta.
/// 2. **Sem `Authorization`.** A autorização está na assinatura da query string;
///    mandar o nosso JWT junto é vazá-lo para um host que não é nosso.
/// 3. **Sem o tradutor de erro do contrato.** O storage responde XML, não
///    `{code, message, fields}` — passar pelo tradutor renderia uma mensagem vazia.
///
/// Os dois cabeçalhos são obrigatórios e precisam casar **exatamente** com o que foi
/// declarado ao pedir a URL: os dois entram na assinatura, e é o que faz o limite de
/// tamanho ser do storage em vez de uma promessa do cliente. Um `Content-Type`
/// diferente rende 403 com corpo XML, que é o erro mais confuso deste fluxo.
Future<void> enviarParaStorage(
  UrlDeUpload destino,
  Uint8List bytes, {
  required String contentType,
}) async {
  final dio = Dio(
    BaseOptions(
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (_) => true,
    ),
  );

  final Response<dynamic> resposta;
  try {
    resposta = await dio.put<dynamic>(
      destino.uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );
  } on DioException {
    throw const FalhaDeRede();
  } finally {
    dio.close();
  }

  final status = resposta.statusCode ?? 0;
  if (status >= 200 && status < 300) return;

  // Mensagem única, e não o corpo do storage: ele responde XML com códigos da API
  // da Amazon, que não dizem nada a quem está com o celular na mão. O caso mais
  // provável é a URL ter expirado — ela vale poucos minutos —, e a ação é a mesma
  // em todos: tentar de novo.
  throw const FalhaDeServidor(
    'Não foi possível enviar a imagem. Tente novamente.',
  );
}
