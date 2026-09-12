import 'package:dio/dio.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/network/auth_interceptor.dart';
import 'package:integra/core/storage/token_storage.dart';

/// O único lugar do app que fala HTTP.
///
/// Nenhuma tela e nenhum repositório constrói `Dio`: pegam este cliente. Assim
/// o token, o refresh e a tradução de erro acontecem uma vez, e não em cada
/// chamada — que é como o protótipo perdia o controle, com cada controller
/// repetindo o próprio `try/catch`.
class ApiClient {
  ApiClient({required String baseUrl, required TokenStorage tokenStorage})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
          // Nós decidimos o que é erro, olhando o corpo no formato do contrato.
          // Sem isto o dio lança antes de podermos ler `code` e `fields`.
          validateStatus: (_) => true,
        ),
      ) {
    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
        aoPerderSessao: () => aoPerderSessao?.call(),
      ),
    );
  }

  final Dio _dio;

  /// Chamado quando o refresh falha e a sessão não pode ser recuperada.
  /// O controlador de sessão liga isto para levar o usuário ao login.
  void Function()? aoPerderSessao;

  Future<Map<String, dynamic>> get(
    String caminho, {
    Map<String, dynamic>? query,
  }) async => _mapear(
    () => _dio.get<dynamic>(caminho, queryParameters: query),
  );

  Future<List<dynamic>> getLista(
    String caminho, {
    Map<String, dynamic>? query,
  }) async {
    final resposta = await _executar(
      () => _dio.get<dynamic>(caminho, queryParameters: query),
    );
    final dados = resposta.data;
    if (dados is List) return dados;
    // Rota paginada devolve `{itens: [...]}`; a não paginada devolve a lista
    // nua. Aceitar as duas evita um método por formato.
    if (dados is Map<String, dynamic> && dados['itens'] is List) {
      return dados['itens'] as List<dynamic>;
    }
    throw const FalhaDeServidor('Resposta em formato inesperado');
  }

  Future<Map<String, dynamic>> post(String caminho, {Object? corpo}) async =>
      _mapear(() => _dio.post<dynamic>(caminho, data: corpo));

  Future<Map<String, dynamic>> patch(String caminho, {Object? corpo}) async =>
      _mapear(() => _dio.patch<dynamic>(caminho, data: corpo));

  Future<void> put(String caminho, {Object? corpo}) async {
    await _executar(() => _dio.put<dynamic>(caminho, data: corpo));
  }

  Future<void> postSemCorpo(String caminho, {Object? corpo}) async {
    await _executar(() => _dio.post<dynamic>(caminho, data: corpo));
  }

  Future<Map<String, dynamic>> _mapear(
    Future<Response<dynamic>> Function() requisicao,
  ) async {
    final resposta = await _executar(requisicao);
    final dados = resposta.data;
    if (dados is Map<String, dynamic>) return dados;
    if (dados == null) return const {};
    throw const FalhaDeServidor('Resposta em formato inesperado');
  }

  Future<Response<dynamic>> _executar(
    Future<Response<dynamic>> Function() requisicao,
  ) async {
    final Response<dynamic> resposta;
    try {
      resposta = await requisicao();
    } on DioException catch (e) {
      throw _daDioException(e);
    }

    final status = resposta.statusCode ?? 0;
    if (status >= 200 && status < 300) return resposta;
    throw _doCorpo(status, resposta.data);
  }

  /// Traduz o corpo de erro do contrato — `{code, message, fields}` — para o
  /// [Failure] correspondente.
  Failure _doCorpo(int status, dynamic corpo) {
    final mapa = corpo is Map<String, dynamic> ? corpo : const <String, dynamic>{};
    final mensagem = mapa['message'] as String?;

    if (status == 422) {
      final brutos = mapa['fields'];
      final campos = <String, List<String>>{};
      if (brutos is Map) {
        for (final entrada in brutos.entries) {
          final valor = entrada.value;
          if (valor is List) {
            campos[entrada.key.toString()] = valor.map((v) => '$v').toList();
          }
        }
      }
      return FalhaDeValidacao(
        campos: campos,
        mensagem: mensagem ?? 'Verifique os campos destacados',
      );
    }

    return switch (status) {
      401 => FalhaDeAutenticacao(mensagem ?? 'E-mail ou senha incorretos'),
      403 => FalhaDePermissao(
        mensagem ?? 'Sua conta não tem permissão para esta ação',
      ),
      404 => FalhaNaoEncontrado(mensagem ?? 'Não encontramos o que você pediu'),
      409 => FalhaDeConflito(mensagem ?? 'Esse valor já está em uso'),
      _ => FalhaDeServidor(
        mensagem ??
            'Algo deu errado do nosso lado. Tente novamente em instantes.',
      ),
    };
  }

  Failure _daDioException(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => const FalhaDeRede(),
    _ => FalhaDeServidor(e.message ?? 'Falha inesperada na requisição'),
  };
}
