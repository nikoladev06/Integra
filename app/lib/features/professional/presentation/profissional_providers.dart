import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integra/core/providers.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/professional/data/feed_repository.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';

/// As duas abas do pilar Profissional.
///
/// Um enum, e não um `int`: a barra de abas é genérica sobre o valor, e um índice
/// faria a terceira aba — candidaturas, que só o aluno tem — mudar o número da
/// segunda dependendo do tipo de conta. Foi exatamente o erro que o botão de
/// publicar no rodapé evitou ao não ser um ramo de navegação.
enum AbaDoProfissional { feed, vagas, candidaturas }

/// O escopo escolhido no botão do cabeçalho.
///
/// Existia antes do `feed-service`, guardando a escolha para o botão não ser uma
/// decoração. Agora o valor vai na query string do jeito que já estava escrito — e
/// o provider não mudou de forma, que era a aposta.
final escopoDoProfissionalProvider =
    NotifierProvider<EscopoDoProfissionalNotifier, EscopoDoProfissional>(
      EscopoDoProfissionalNotifier.new,
    );

class EscopoDoProfissionalNotifier extends Notifier<EscopoDoProfissional> {
  @override
  EscopoDoProfissional build() => EscopoDoProfissional.geral;

  void trocar(EscopoDoProfissional escopo) => state = escopo;
}

final abaDoProfissionalProvider =
    NotifierProvider<AbaDoProfissionalNotifier, AbaDoProfissional>(
      AbaDoProfissionalNotifier.new,
    );

class AbaDoProfissionalNotifier extends Notifier<AbaDoProfissional> {
  @override
  AbaDoProfissional build() => AbaDoProfissional.feed;

  void trocar(AbaDoProfissional aba) => state = aba;
}

/// Uma lista paginada de posts profissionais, com o cursor guardado.
///
/// Mesma forma do `FeedState` do Acadêmico, e a repetição é deliberada: são dois
/// tipos de item diferentes, e generalizar sobre `T` renderia um estado genérico que
/// nenhuma das duas telas leria melhor. O que foi compartilhado de verdade — o cursor
/// opaco, a data relativa — mora fora das duas.
class FeedProfissionalState {
  const FeedProfissionalState({
    this.itens = const [],
    this.proximoCursor,
    this.carregandoMais = false,
  });

  final List<PostProfissional> itens;
  final String? proximoCursor;

  /// Distinto do `AsyncLoading` do provider: aquele é a carga inicial, que troca a
  /// tela por um indicador. Este é o rodapé da lista, com os itens à vista.
  final bool carregandoMais;

  bool get temMais => proximoCursor != null;

  FeedProfissionalState copyWith({
    List<PostProfissional>? itens,
    String? proximoCursor,
    bool? carregandoMais,
  }) => FeedProfissionalState(
    itens: itens ?? this.itens,
    // Nulo explícito é o fim da lista, então `??` não serve: ele leria o fim como
    // "mantenha o cursor anterior", e o botão de carregar mais nunca sumiria.
    proximoCursor: proximoCursor,
    carregandoMais: carregandoMais ?? this.carregandoMais,
  );
}

/// O feed profissional, já no escopo escolhido.
final feedProfissionalProvider =
    AsyncNotifierProvider<FeedProfissionalNotifier, FeedProfissionalState>(
      FeedProfissionalNotifier.new,
    );

class FeedProfissionalNotifier extends AsyncNotifier<FeedProfissionalState> {
  late FeedRepository _repo;
  late EscopoDoProfissional _escopo;

  @override
  Future<FeedProfissionalState> build() async {
    _repo = ref.watch(feedRepositoryProvider);
    _escopo = ref.watch(escopoDoProfissionalProvider);

    // O feed depende do **vínculo**, e não só de quem o leitor segue: é o vínculo que
    // decide quais universidades tornam um autor recomendado. Sem observar a sessão,
    // criar o vínculo pelo "inserir CPF" não faria as recomendações aparecerem até a
    // próxima troca de aba — e o usuário concluiria que a função não existe.
    ref.watch(perfilAtualProvider);

    final pagina = await _repo.feed(escopo: _escopo);
    return FeedProfissionalState(
      itens: pagina.itens,
      proximoCursor: pagina.proximoCursor,
    );
  }

  Future<void> carregarMais() async {
    final atual = state.value;
    if (atual == null || !atual.temMais || atual.carregandoMais) return;

    state = AsyncData(
      atual.copyWith(carregandoMais: true, proximoCursor: atual.proximoCursor),
    );
    try {
      final pagina = await _repo.feed(
        escopo: _escopo,
        cursor: atual.proximoCursor,
      );
      state = AsyncData(
        FeedProfissionalState(
          itens: [...atual.itens, ...pagina.itens],
          proximoCursor: pagina.proximoCursor,
        ),
      );
    } catch (erro, pilha) {
      // A falha da página seguinte não apaga o que já está na tela: o usuário
      // perderia a posição de rolagem por um erro que só afeta o rodapé.
      state = AsyncData(
        atual.copyWith(
          carregandoMais: false,
          proximoCursor: atual.proximoCursor,
        ),
      );
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  /// Substitui um post na lista sem recarregar a página.
  ///
  /// Curtir devolve a contagem nova, e recarregar o feed inteiro por causa de um
  /// coração faria a lista pular de posição.
  void substituir(PostProfissional post) {
    final atual = state.value;
    if (atual == null) return;

    state = AsyncData(
      atual.copyWith(
        itens: [
          for (final p in atual.itens)
            if (p.id == post.id) post else p,
        ],
        proximoCursor: atual.proximoCursor,
      ),
    );
  }

  void retirar(String postId) {
    final atual = state.value;
    if (atual == null) return;

    state = AsyncData(
      atual.copyWith(
        itens: atual.itens.where((p) => p.id != postId).toList(),
        proximoCursor: atual.proximoCursor,
      ),
    );
  }
}

/// Os posts de um usuário — a aba "publicações" do perfil dele.
///
/// A aba que a Sprint 4 deixou como vazio honesto. Uma família por usuário, então
/// abrir dois perfis não faz o segundo herdar a lista do primeiro.
final postsDoUsuarioProvider = FutureProvider.autoDispose
    .family<PaginaDePostsProfissionais, String>(
      (ref, userId) =>
          ref.watch(feedRepositoryProvider).postsDoUsuario(userId),
    );

/// Um post profissional por id, para a tela de detalhe.
final postProfissionalProvider = FutureProvider.autoDispose
    .family<PostProfissional, String>(
      (ref, postId) => ref.watch(feedRepositoryProvider).post(postId),
    );

/// Os comentários de um post profissional.
final comentariosProfissionaisProvider = FutureProvider.autoDispose
    .family<PaginaDeComentariosProfissionais, String>(
      (ref, postId) => ref.watch(feedRepositoryProvider).comentarios(postId),
    );
