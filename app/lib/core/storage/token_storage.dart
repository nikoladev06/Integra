import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Onde os tokens de sessão ficam.
///
/// Interface antes de implementação por um motivo prático: teste de widget não
/// pode tocar no keystore do sistema. [TokenStorageEmMemoria] existe para isso,
/// e é o que faz o portão da sprint ("teste rodando na CI sem servidor") ser
/// possível.
abstract interface class TokenStorage {
  Future<String?> lerAccessToken();
  Future<String?> lerRefreshToken();
  Future<void> salvar({required String accessToken, required String refreshToken});
  Future<void> limpar();
}

/// Implementação real: Keychain no iOS, e no Android AES/GCM com chave guardada
/// no Keystore — o padrão do pacote na versão 11, onde a criptografia deixou de
/// ser opcional.
///
/// **Não** `SharedPreferences`: lá o token fica em texto claro, legível por
/// qualquer processo com acesso ao diretório do app em aparelho com root.
class TokenStorageSeguro implements TokenStorage {
  TokenStorageSeguro([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _chaveAccess = 'integra.access_token';
  static const _chaveRefresh = 'integra.refresh_token';

  @override
  Future<String?> lerAccessToken() => _storage.read(key: _chaveAccess);

  @override
  Future<String?> lerRefreshToken() => _storage.read(key: _chaveRefresh);

  @override
  Future<void> salvar({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _chaveAccess, value: accessToken);
    await _storage.write(key: _chaveRefresh, value: refreshToken);
  }

  @override
  Future<void> limpar() async {
    await _storage.delete(key: _chaveAccess);
    await _storage.delete(key: _chaveRefresh);
  }
}

/// Para testes e para o modo com repositórios falsos.
class TokenStorageEmMemoria implements TokenStorage {
  TokenStorageEmMemoria({String? accessToken, String? refreshToken})
    : _access = accessToken,
      _refresh = refreshToken;

  String? _access;
  String? _refresh;

  @override
  Future<String?> lerAccessToken() async => _access;

  @override
  Future<String?> lerRefreshToken() async => _refresh;

  @override
  Future<void> salvar({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> limpar() async {
    _access = null;
    _refresh = null;
  }
}
