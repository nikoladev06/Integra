import 'package:integra/features/academic/data/models/post.dart';

/// Contrato do pilar Acadêmico, espelhando `contracts/academic.openapi.yaml` v1.
///
/// **Nenhum método recebe filtro de visibilidade, e isso é intencional.** O que o
/// leitor pode ver sai do vínculo que viaja no token, resolvido no serviço. Se
/// esta interface tivesse um parâmetro do tipo `apenasPublicos`, a regra passaria
/// a depender de a tela pedir certo — e uma tela nova que esquecesse mostraria o
/// que não devia.
///
/// O que existe é [EscopoDoFeed], que é outra coisa: escolhe **quais
/// instituições** entram no feed, nunca **qual conteúdo** dentro delas.
abstract interface class AcademicRepository {
  // ──────────────────────────────  leitura  ──────────────────────────────

  /// `GET /academic/posts`. Uma página do feed, do mais recente para o mais antigo.
  ///
  /// [cursor] é o `proximoCursor` da página anterior, repassado como veio.
  Future<PaginaDePosts> feed({
    EscopoDoFeed escopo = EscopoDoFeed.geral,
    String? cursor,
  });

  /// `GET /academic/universidades/{id}/posts`. As abas do perfil da instituição.
  ///
  /// Separado do feed porque o feed é limitado ao vínculo e às seguidas: quem
  /// chegou pela busca não é nenhum dos dois, e ainda assim vê os públicos.
  ///
  /// [visibilidade] é o que separa as três abas, e é **filtro de apresentação**:
  /// ele estreita o que a matriz de visibilidade já autorizou e nunca amplia.
  /// Pedir [Visibilidade.curso] sem vínculo naquele curso devolve lista vazia, não
  /// os restritos — é por isso que este parâmetro pode sair do cliente, ao
  /// contrário do vínculo, que viaja no token justamente para não poder.
  Future<PaginaDePosts> postsDaUniversidade(
    String universidadeId, {
    Visibilidade? visibilidade,
    String? cursor,
  });

  /// `GET /academic/posts/{id}`. Fora do alcance responde 404 — o mesmo de
  /// inexistente, para a rota não virar sonda de comunicados restritos.
  Future<Post> post(String postId);

  /// `GET /academic/posts/{id}/comentarios`. Do mais antigo para o mais novo.
  Future<PaginaDeComentarios> comentarios(String postId, {String? cursor});

  // ─────────────────────────────  publicação  ─────────────────────────────

  /// `POST /academic/posts`. Só conta `faculdade` **ativada**.
  ///
  /// A universidade **não** é parâmetro: é a da conta autora, resolvida no
  /// serviço. [cursoId] é obrigatório quando [visibilidade] é
  /// [Visibilidade.curso], e recusado nos outros dois alcances.
  Future<Post> publicar({
    required String conteudo,
    required Visibilidade visibilidade,
    String? cursoId,
  });

  /// `PATCH /academic/posts/{id}`. Só a faculdade autora, e **inclui o alcance**.
  ///
  /// Foi decisão da Sprint 4 permitir mudar o alcance depois de publicado. O
  /// custo: quem já leu não é avisado. `editadoEm` passa a não nulo e a tela
  /// mostra "editado", que é o que mantém a mudança visível.
  Future<Post> editar(
    String postId, {
    String? conteudo,
    Visibilidade? visibilidade,
    String? cursoId,
  });

  /// `DELETE /academic/posts/{id}`. Leva curtidas e comentários junto.
  Future<void> remover(String postId);

  // ──────────────────────  curtidas e comentários  ──────────────────────

  /// `PUT`/`DELETE /academic/posts/{id}/curtidas`. Idempotente nos dois sentidos.
  Future<void> curtir(String postId, {required bool curtir});

  /// `POST /academic/posts/{id}/comentarios`. Só quem pode **ver** o post.
  Future<Comentario> comentar(String postId, String conteudo);

  /// `DELETE /academic/comentarios/{id}`. Autor do comentário, ou a faculdade
  /// autora do post.
  Future<void> removerComentario(String comentarioId);
}
