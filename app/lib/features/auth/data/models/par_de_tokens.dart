import 'package:freezed_annotation/freezed_annotation.dart';

part 'par_de_tokens.freezed.dart';
part 'par_de_tokens.g.dart';

/// Par de tokens emitido por `POST /auth/login` e `POST /auth/refresh`.
///
/// Espelha `components.schemas.TokenPair` em `contracts/auth.openapi.yaml`.
/// O `accessToken` é um JWT que os serviços validam sozinhos; o `refreshToken`
/// é opaco e só o auth-service sabe ler.
@freezed
abstract class ParDeTokens with _$ParDeTokens {
  const factory ParDeTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    @Default('Bearer') String tokenType,
  }) = _ParDeTokens;

  factory ParDeTokens.fromJson(Map<String, dynamic> json) =>
      _$ParDeTokensFromJson(json);
}
