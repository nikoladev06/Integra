import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:integra/core/providers.dart';
import 'package:integra/core/storage/token_storage.dart';
import 'package:integra/features/auth/data/auth_repository.dart';
import 'package:integra/features/auth/data/fake_auth_repository.dart';
import 'package:integra/features/profile/data/profile_repository.dart';
import 'package:integra/main.dart';

/// Sobe o app inteiro com dependências controladas.
///
/// É o que faz o portão desta sprint ser verificável: o app completo — tema,
/// roteador, guarda de sessão e repositórios — roda em teste **sem servidor e
/// sem tocar no keystore do sistema**, porque tudo que sai da máquina está
/// atrás de uma interface que o `ProviderScope` substitui aqui.
Future<void> bombearApp(
  WidgetTester tester, {
  AuthRepository? auth,
  ProfileRepository? perfis,
  TokenStorage? tokens,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Latência zero: os falsos simulam 300–400 ms em desenvolvimento para
        // os estados de carregamento serem visíveis, o que em teste só gastaria
        // tempo de espera.
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository(latencia: Duration.zero),
        ),
        profileRepositoryProvider.overrideWithValue(
          perfis ?? FakeProfileRepository(latencia: Duration.zero),
        ),
        tokenStorageProvider.overrideWithValue(
          tokens ?? TokenStorageEmMemoria(),
        ),
      ],
      child: const IntegraApp(),
    ),
  );
  // Duas passadas: a primeira monta, a segunda deixa o `restaurar()` do
  // post-frame resolver e o `redirect` reavaliar.
  await tester.pumpAndSettle();
}
