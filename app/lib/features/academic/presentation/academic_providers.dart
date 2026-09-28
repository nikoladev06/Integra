import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integra/core/providers.dart';
import 'package:integra/features/academic/data/academic_repository.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// O escopo escolhido na barra retrátil do topo do feed.
///
/// Fora do controlador do feed de propósito: a barra e o feed são widgets
/// diferentes, e a barra não deve precisar de uma referência ao feed para dizer
/// que a escolha mudou. O feed observa este provider e recarrega.
final escopoDoFeedProvider = NotifierProvider<EscopoNotifier, EscopoDoFeed>(
  EscopoNotifier.new,
);

class EscopoNotifier extends Notifier<EscopoDoFeed> {
  @override
  EscopoDoFeed build() => EscopoDoFeed.geral;

  void trocar(EscopoDoFeed escopo) => state = escopo;
}

/// Uma lista paginada de posts, com o cursor guardado.
///
/// `AsyncValue<List<Post>>` seria mais simples, mas perderia o cursor: sem ele a
/// tela não sabe se existe página seguinte, e "carregar mais" viraria ou um botão
/// sempre presente ou um `COUNT` a cada rolagem.
class FeedState {
  const FeedState({
    this.itens = const [],
    this.proximoCursor,
    this.carregandoMais = false,
  });

  final List<Post> itens;
  final String? proximoCursor;

  /// Distinto do `AsyncLoading` do provider: aquele é a carga inicial, que troca
  /// a tela por um indicador. Este é o rodapé da lista, com os itens à vista.
  final bool carregandoMais;

  bool get temMais => proximoCursor != null;

  FeedState copyWith({
    List<Post>? itens,
    String? proximoCursor,
    bool? carregandoMais,
  }) => FeedState(
    itens: itens ?? this.itens,
    // Nulo explícito é o fim da lista, então `??` não serve: ele leria o fim
    // como "mantenha o cursor anterior", e o botão de carregar mais nunca sumiria.
    proximoCursor: proximoCursor,
    carregandoMais: carregandoMais ?? this.carregandoMais,
  );
}

/// O feed institucional, já no escopo escolhido.
///
/// Observa [escopoDoFeedProvider], então trocar de escopo reconstrói o notifier e
/// a primeira página vem de novo — que é o comportamento certo: a lista antiga
/// era de outro conjunto de instituições, e manter os itens enquanto a nova
/// carrega mostraria posts que já não pertencem ao filtro.
final feedProvider = AsyncNotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);

class FeedNotifier extends AsyncNotifier<FeedState> {
  late AcademicRepository _repo;
  late EscopoDoFeed _escopo;

  @override
  Future<FeedState> build() async {
    _repo = ref.watch(academicRepositoryProvider);
    _escopo = ref.watch(escopoDoFeedProvider);

    // O feed depende do vínculo — é ele que decide o que o serviço devolve. Sem
    // observar a sessão, criar o vínculo pelo "inserir CPF" não faria o feed
    // mudar até a próxima troca de aba.
    ref.watch(perfilAtualProvider);

    final pagina = await _repo.feed(escopo: _escopo);
    return FeedState(itens: pagina.itens, proximoCursor: pagina.proximoCursor);
  }

  /// A página seguinte, anexada à lista atual.
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
        FeedState(
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
  /// coração faria a lista pular de posição. Quem chama já tem o post atualizado.
  void substituir(Post post) {
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

/// A chave das abas do perfil da instituição: universidade + alcance.
///
/// Um record, e não duas famílias encadeadas: as duas partes mudam juntas quando o
/// usuário troca de aba, e um `family` por universidade com estado de aba dentro
/// faria a segunda aba herdar a página da primeira.
typedef AbaDaUniversidade = ({
  String universidadeId,
  Visibilidade visibilidade,
});

/// Os posts de uma universidade num alcance, para uma aba do perfil dela.
///
/// Separado do feed porque o feed é limitado ao vínculo e às seguidas: quem chegou
/// pela busca não é nenhum dos dois, e ainda assim vê os públicos.
///
/// Uma família por aba significa que cada uma tem o próprio estado de carga — e
/// que trocar de aba não descarta o que a anterior já havia trazido.
final postsDaUniversidadeProvider = FutureProvider.autoDispose
    .family<PaginaDePosts, AbaDaUniversidade>(
      (ref, aba) => ref
          .watch(academicRepositoryProvider)
          .postsDaUniversidade(
            aba.universidadeId,
            visibilidade: aba.visibilidade,
          ),
    );

/// Um post por id, para a tela de detalhe.
final postProvider = FutureProvider.autoDispose.family<Post, String>(
  (ref, postId) => ref.watch(academicRepositoryProvider).post(postId),
);

/// Os comentários de um post.
final comentariosProvider = FutureProvider.autoDispose
    .family<PaginaDeComentarios, String>(
      (ref, postId) =>
          ref.watch(academicRepositoryProvider).comentarios(postId),
    );

/// Os cursos que a **própria** instituição cadastrou.
///
/// Distinto de `cursosDaUniversidadeProvider`, que é público e serve ao combobox
/// do cadastro. Este exige conta `faculdade` e alimenta duas telas: a de
/// administração e o seletor de curso na composição de um post restrito.
final meusCursosProvider = FutureProvider.autoDispose<List<Curso>>(
  (ref) => ref.watch(profileRepositoryProvider).meusCursos(),
);
