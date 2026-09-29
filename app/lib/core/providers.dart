import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integra/core/config/ambiente.dart';
import 'package:integra/core/network/api_client.dart';
import 'package:integra/core/storage/token_storage.dart';
import 'package:integra/features/academic/data/academic_repository.dart';
import 'package:integra/features/academic/data/api_academic_repository.dart';
import 'package:integra/features/academic/data/fake_academic_repository.dart';
import 'package:integra/features/auth/data/api_auth_repository.dart';
import 'package:integra/features/auth/data/auth_repository.dart';
import 'package:integra/features/auth/data/fake_auth_repository.dart';
import 'package:integra/features/profile/data/api_profile_repository.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/fake_profile_repository.dart';
import 'package:integra/features/jobs/data/api_jobs_repository.dart';
import 'package:integra/features/jobs/data/fake_jobs_repository.dart';
import 'package:integra/features/jobs/data/jobs_repository.dart';
import 'package:integra/features/professional/data/api_feed_repository.dart';
import 'package:integra/features/professional/data/fake_feed_repository.dart';
import 'package:integra/features/professional/data/feed_repository.dart';
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

/// O pilar Acadêmico. Mesmo `BancoFalso` dos outros dois — e isso não é detalhe:
/// publicar um comunicado restrito a um curso só faz sentido se o vínculo que o
/// destrava for o mesmo que o "inserir CPF" criou.
final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  if (Ambiente.usarFalsos) {
    return FakeAcademicRepository(ref.watch(bancoFalsoProvider));
  }
  return ApiAcademicRepository(ref.watch(apiClientProvider));
});

/// O pilar Profissional. Mesmo `BancoFalso` dos outros — e aqui isso importa por um
/// motivo que nao existia no Academico: o feed profissional recomenda por
/// **universidade do vinculo**, e o vinculo e o que o "inserir CPF" da tela de
/// instituicao cria. Com estados separados, recomendacao nunca funcionaria no falso.
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  if (Ambiente.usarFalsos) {
    return FakeFeedRepository(ref.watch(bancoFalsoProvider));
  }
  return ApiFeedRepository(ref.watch(apiClientProvider));
});

/// A area de vagas. Mesmo `BancoFalso`: a candidatura liga uma conta `empresa` a uma
/// conta `aluno`, e as duas vivem no mapa de usuarios que os outros falsos usam.
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  if (Ambiente.usarFalsos) {
    return FakeJobsRepository(ref.watch(bancoFalsoProvider));
  }
  return ApiJobsRepository(ref.watch(apiClientProvider));
});
