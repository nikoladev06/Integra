import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integra/core/providers.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/profile/data/models/instituicao.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// O catálogo de universidades. Sem autenticação — é o que alimenta o combobox
/// da tela de cadastro, antes de existir sessão.
final universidadesProvider = FutureProvider.autoDispose<List<Universidade>>(
  (ref) => ref.watch(profileRepositoryProvider).universidades(),
);

/// Os cursos de uma universidade, e **só os que ela cadastrou**.
///
/// Encadeado ao combobox anterior de propósito: no protótipo curso era texto
/// livre, e cada aluno escrevia "ADS", "A.D.S." ou "Análise e Desenvolvimento".
/// Nenhuma consulta por curso era possível sobre aquilo.
final cursosDaUniversidadeProvider = FutureProvider.autoDispose
    .family<List<Curso>, String>(
      (ref, universidadeId) =>
          ref.watch(profileRepositoryProvider).cursosDe(universidadeId),
    );

/// O perfil público de uma universidade, com `temVinculo` e `seguindo` já
/// resolvidos para quem está lendo.
final perfilDeUniversidadeProvider = FutureProvider.autoDispose
    .family<PerfilDeUniversidade, String>(
      (ref, universidadeId) => ref
          .watch(profileRepositoryProvider)
          .perfilDaUniversidade(universidadeId),
    );

/// A instituição da conta `faculdade` autenticada — **o próprio perfil dela**.
///
/// Separado do de cima porque o id não existe no cliente: o elo conta →
/// universidade é uma coluna do `user-service`, e é a rota `/universidades/me` que o
/// resolve. Observa a sessão, senão trocar de conta mostraria a instituição da
/// anterior.
final minhaUniversidadeProvider = FutureProvider<PerfilDeUniversidade>((
  ref,
) async {
  ref.watch(perfilAtualProvider);
  return ref.watch(profileRepositoryProvider).minhaUniversidade();
});
