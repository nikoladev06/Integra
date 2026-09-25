import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integra/core/config/ambiente.dart';
import 'package:integra/core/network/api_client.dart';
import 'package:integra/core/storage/token_storage.dart';
import 'package:integra/features/auth/data/api_auth_repository.dart';
import 'package:integra/features/auth/data/auth_repository.dart';
import 'package:integra/features/auth/data/fake_auth_repository.dart';
import 'package:integra/features/profile/data/api_profile_repository.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/fake_profile_repository.dart';
import 'package:integra/features/profile/data/profile_repository.dart';

/// A injeção de dependência do app.
///
/// **É aqui que a troca de que o plano fala acontece.** Cada repositório escolhe
/// entre a implementação falsa e a de API olhando uma única condição, e nenhuma
/// tela sabe qual está no ar. Quando os serviços sobem, o que muda é o valor de
/// `API_BASE_URL` na linha de comando — não o código.
///
/// Nos testes, estes providers são substituídos por `overrides` no
/// `ProviderScope`, que é o que torna teste de widget possível sem servidor e
/// sem tocar no keystore do sistema.

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  // Sem backend não há token real para guardar, e o keystore do sistema não
  // existe em teste — memória serve para os dois casos.
  if (Ambiente.usarFalsos) return TokenStorageEmMemoria();
  return TokenStorageSeguro();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  if (Ambiente.usarFalsos) {
    throw StateError(
      'ApiClient pedido em modo de fixtures. Rode com '
      '--dart-define=API_BASE_URL=http://localhost:8080 para falar com a API.',
    );
  }
  return ApiClient(
    baseUrl: Ambiente.apiBaseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// O estado que os dois repositórios falsos compartilham.
///
/// Um provider, e não um singleton: cada `ProviderScope` tem o seu, então um
/// teste nunca vê o usuário que outro cadastrou. Só existe no modo de fixtures —
/// com a API no ar, quem guarda estado é o Postgres.
final bancoFalsoProvider = Provider<BancoFalso>((ref) => BancoFalso());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Ambiente.usarFalsos) {
    return FakeAuthRepository(ref.watch(bancoFalsoProvider));
  }
  return ApiAuthRepository(ref.watch(apiClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (Ambiente.usarFalsos) {
    return FakeProfileRepository(ref.watch(bancoFalsoProvider));
  }
  return ApiProfileRepository(ref.watch(apiClientProvider));
});
