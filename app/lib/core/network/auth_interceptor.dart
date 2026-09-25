import 'dart:async';

import 'package:dio/dio.dart';

import 'package:integra/core/storage/token_storage.dart';

/// Acrescenta o token a cada requisição e renova a sessão quando ele expira.
///
/// O access token vive 15 minutos, então expirar durante o uso é rotina, não
/// exceção. Sem isto, o usuário seria jogado para o login a cada 15 minutos.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required String baseUrl,
    required this.aoPerderSessao,
  }) : _tokens = tokenStorage,
       // Cliente separado, sem interceptor, para chamar o refresh. Usar o
       // mesmo Dio faria o 401 do refresh disparar outro refresh, em recursão.
       _dioDeRefresh = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           contentType: Headers.jsonContentType,
           validateStatus: (_) => true,
         ),
       );

  final TokenStorage _tokens;

  /// Chamado quando a renovação falha e só o login resolve.
  final void Function() aoPerderSessao;
  final Dio _dioDeRefresh;

  /// Renovação em voo. Se cinco requisições tomarem 401 ao mesmo tempo, todas
  /// esperam **a mesma** renovação — cinco chamadas concorrentes de refresh
  /// invalidariam umas às outras, porque o contrato rotaciona o token.
  Future<String?>? _renovacaoEmVoo;

  /// Rotas de credencial: não levam token e um 401 nelas **não** é sessão
  /// expirada, é resposta de negócio.
  ///
  /// A lista é só de `/auth/*` de propósito. Uma versão anterior tinha também
  /// `/universidades`, para poupar o token no combobox do cadastro, e com isso
  /// deixava sem `Authorization` tudo que pendura naquele prefixo — inclusive
  /// `POST /universidades/{id}/vinculo`, que é justamente o "inserir CPF", e
  /// `GET /universidades/{id}`, que precisa do leitor para calcular
  /// `temVinculo`. Prefixo é do caminho, não da autorização.
  ///
  /// O que sobrou é o mínimo: mandar um token a uma rota que não o lê é
  /// inofensivo — o serviço só o consulta onde declara a dependência — enquanto
  /// omiti-lo onde ele é exigido quebra a rota em silêncio.
  static const _deCredencial = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
  };

  bool _eDeCredencial(String caminho) =>
      _deCredencial.any((p) => caminho == p || caminho.startsWith('$p/'));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_eDeCredencial(options.path)) {
      final token = await _tokens.lerAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;

    final naoEhRenovavel =
        response.statusCode != 401 ||
        _eDeCredencial(options.path) ||
        options.extra['jaTentouRenovar'] == true;

    if (naoEhRenovavel) {
      handler.next(response);
      return;
    }

    final novoToken = await _renovar();
    if (novoToken == null) {
      handler.next(response);
      return;
    }

    // Repete a requisição original uma única vez, marcada para não entrar em
    // laço se o 401 voltar.
    try {
      final repetida = await _dioDeRefresh.fetch<dynamic>(
        options
          ..headers['Authorization'] = 'Bearer $novoToken'
          ..extra['jaTentouRenovar'] = true,
      );
      handler.resolve(repetida);
    } on DioException catch (e) {
      handler.next(e.response ?? response);
    }
  }

  Future<String?> _renovar() {
    return _renovacaoEmVoo ??= _fazerRenovacao().whenComplete(() {
      _renovacaoEmVoo = null;
    });
  }

  Future<String?> _fazerRenovacao() async {
    final refresh = await _tokens.lerRefreshToken();
    if (refresh == null) {
      _encerrar();
      return null;
    }

    final resposta = await _dioDeRefresh.post<dynamic>(
      '/auth/refresh',
      data: {'refreshToken': refresh},
    );

    final dados = resposta.data;
    if (resposta.statusCode != 200 || dados is! Map<String, dynamic>) {
      // Refresh recusado significa token vazado e família revogada, ou sessão
      // simplesmente velha. Nos dois casos só o login resolve.
      _encerrar();
      return null;
    }

    final access = dados['accessToken'] as String?;
    final novoRefresh = dados['refreshToken'] as String?;
    if (access == null || novoRefresh == null) {
      _encerrar();
      return null;
    }

    await _tokens.salvar(accessToken: access, refreshToken: novoRefresh);
    return access;
  }

  void _encerrar() {
    unawaited(_tokens.limpar());
    aoPerderSessao();
  }
}
