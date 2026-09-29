import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integra/core/providers.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/jobs/data/jobs_repository.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';

/// O filtro em vigor na área de vagas.
///
/// Fora do controlador da lista, como o escopo do feed: o popover de filtro e a lista
/// são widgets diferentes, e o popover não deve precisar de uma referência à lista
/// para dizer que a escolha mudou.
final filtroDeVagasProvider =
    NotifierProvider<FiltroDeVagasNotifier, FiltroDeVagas>(
      FiltroDeVagasNotifier.new,
    );

class FiltroDeVagasNotifier extends Notifier<FiltroDeVagas> {
  @override
  FiltroDeVagas build() => const FiltroDeVagas();

  void trocar(FiltroDeVagas filtro) => state = filtro;

  void limpar() => state = const FiltroDeVagas();
}

/// Uma lista paginada de vagas, com o cursor guardado.
class VagasState {
  const VagasState({
    this.itens = const [],
    this.proximoCursor,
    this.carregandoMais = false,
  });

  final List<Vaga> itens;
  final String? proximoCursor;
  final bool carregandoMais;

  bool get temMais => proximoCursor != null;

  VagasState copyWith({
    List<Vaga>? itens,
    String? proximoCursor,
    bool? carregandoMais,
  }) => VagasState(
    itens: itens ?? this.itens,
    proximoCursor: proximoCursor,
    carregandoMais: carregandoMais ?? this.carregandoMais,
  );
}

/// A lista de vagas, já filtrada.
final vagasProvider = AsyncNotifierProvider<VagasNotifier, VagasState>(
  VagasNotifier.new,
);

class VagasNotifier extends AsyncNotifier<VagasState> {
  late JobsRepository _repo;
  late FiltroDeVagas _filtro;

  @override
  Future<VagasState> build() async {
    _repo = ref.watch(jobsRepositoryProvider);
    _filtro = ref.watch(filtroDeVagasProvider);

    // A lista depende de quem está lendo: `candidaturaEnviada` é estado por leitor, e
    // é o que decide o texto do botão de cada card. Sem observar a sessão, sair e
    // entrar com outra conta mostraria os botões da conta anterior.
    ref.watch(perfilAtualProvider);

    final pagina = await _repo.vagas(filtro: _filtro);
    return VagasState(itens: pagina.itens, proximoCursor: pagina.proximoCursor);
  }

  Future<void> carregarMais() async {
    final atual = state.value;
    if (atual == null || !atual.temMais || atual.carregandoMais) return;

    state = AsyncData(
      atual.copyWith(carregandoMais: true, proximoCursor: atual.proximoCursor),
    );
    try {
      final pagina = await _repo.vagas(
        filtro: _filtro,
        cursor: atual.proximoCursor,
      );
      state = AsyncData(
        VagasState(
          itens: [...atual.itens, ...pagina.itens],
          proximoCursor: pagina.proximoCursor,
        ),
      );
    } catch (erro, pilha) {
      state = AsyncData(
        atual.copyWith(
          carregandoMais: false,
          proximoCursor: atual.proximoCursor,
        ),
      );
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  /// Substitui uma vaga na lista sem recarregar a página.
  ///
  /// Candidatar-se devolve a candidatura com a vaga atualizada dentro — o total subiu
  /// e `candidaturaEnviada` virou `true`. Recarregar a lista inteira por causa de um
  /// botão faria a rolagem pular.
  void substituir(Vaga vaga) {
    final atual = state.value;
    if (atual == null) return;

    state = AsyncData(
      atual.copyWith(
        itens: [
          for (final v in atual.itens)
            if (v.id == vaga.id) vaga else v,
        ],
        proximoCursor: atual.proximoCursor,
      ),
    );
  }
}

/// Uma vaga por id, para a tela de detalhe.
final vagaProvider = FutureProvider.autoDispose.family<Vaga, String>(
  (ref, vagaId) => ref.watch(jobsRepositoryProvider).vaga(vagaId),
);

/// As candidaturas recebidas numa vaga. **Só a empresa autora recebe conteúdo** —
/// qualquer outra conta recebe 404, que a tela traduz em "não encontrada".
final candidaturasDaVagaProvider = FutureProvider.autoDispose
    .family<PaginaDeCandidaturas, String>(
      (ref, vagaId) =>
          ref.watch(jobsRepositoryProvider).candidaturasDaVaga(vagaId),
    );

/// As candidaturas do aluno autenticado.
///
/// Observa a sessão: são as candidaturas **de quem está logado**, e o id sai do
/// token. Sem observar, trocar de conta mostraria a lista da anterior.
final minhasCandidaturasProvider = FutureProvider<PaginaDeCandidaturas>((
  ref,
) async {
  ref.watch(perfilAtualProvider);
  return ref.watch(jobsRepositoryProvider).minhasCandidaturas();
});
