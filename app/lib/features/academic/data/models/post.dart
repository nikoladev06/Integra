import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:integra/features/profile/data/models/perfil.dart';

part 'post.freezed.dart';
part 'post.g.dart';

/// O alcance de um comunicado. Espelha `components.schemas.Visibilidade` em
/// `contracts/academic.openapi.yaml`.
///
/// **Isto não é um filtro de tela.** Quem decide o que o leitor vê é o serviço,
/// na consulta, a partir do vínculo no token — um post fora do alcance nunca
/// chega ao app. O enum existe aqui para dois usos, e nenhum deles é esconder
/// conteúdo: mostrar ao leitor **a quem** aquele post foi dirigido, e oferecer a
/// escolha a quem publica.
///
/// Se alguma tela passar a filtrar por este campo, é sinal de que a regra
/// escorregou para o cliente — e no cliente ela é contornável por quem ler o
/// JSON em vez de olhar a tela.
@JsonEnum(fieldRename: FieldRename.none)
enum Visibilidade {
  /// Qualquer conta autenticada. É o que aparece no perfil da instituição para
  /// quem chegou pela busca, sem vínculo nem seguir.
  publico('Público', 'Qualquer pessoa no Integra'),

  /// Quem tem **vínculo ativo** com esta universidade. O padrão do formulário.
  institucional('Institucional', 'Apenas quem tem vínculo com a instituição'),

  /// Quem tem vínculo ativo **neste curso** dela.
  curso('Restrito a curso', 'Apenas quem tem vínculo neste curso');

  const Visibilidade(this.rotulo, this.explicacao);

  /// Texto curto, para a etiqueta no card.
  final String rotulo;

  /// Frase para o formulário de publicação, onde a escolha é consequente.
  final String explicacao;
}

/// A universidade que publicou.
///
/// Resolvida **na leitura** pelo serviço, a partir do id guardado no post — não
/// copiada para dentro dele na publicação. O protótipo denormalizava
/// `nomeCompleto` dentro de cada post, e o nome envelhecia ali: trocá-lo não
/// alcançava o que já estava publicado.
@freezed
abstract class InstituicaoDoPost with _$InstituicaoDoPost {
  const factory InstituicaoDoPost({
    required String id,
    required String nome,
    required String sigla,
    String? fotoUrl,
  }) = _InstituicaoDoPost;

  factory InstituicaoDoPost.fromJson(Map<String, dynamic> json) =>
      _$InstituicaoDoPostFromJson(json);
}

/// Um comunicado institucional.
@freezed
abstract class Post with _$Post {
  const factory Post({
    required String id,
    required InstituicaoDoPost instituicao,
    required Visibilidade visibilidade,
    required String conteudo,
    required DateTime criadoEm,

    /// Presente **somente** quando [visibilidade] é [Visibilidade.curso]. A tela
    /// mostra o nome ao lado do alcance: o aluno precisa saber que aquilo não é
    /// público, e para qual turma foi.
    Curso? curso,
    @Default(0) int totalDeCurtidas,
    @Default(0) int totalDeComentarios,

    /// Estado **por leitor**, calculado na consulta. O protótipo guardava
    /// `isLiked` dentro do post, e a curtida de uma pessoa aparecia para todas.
    @Default(false) bool curtidoPorMim,

    /// Se o leitor é a conta autora. Vem do servidor em vez de a tela comparar
    /// ids — e concluir diferente dele num caso de borda.
    @Default(false) bool podeEditar,

    /// Não nulo depois de uma edição. A tela mostra "editado" ao lado da data,
    /// porque a faculdade pode mudar até o alcance de um post publicado e quem
    /// já leu não é avisado.
    DateTime? editadoEm,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

extension PostX on Post {
  bool get editado => editadoEm != null;

  /// A etiqueta de alcance do card. `Restrito a ADS` diz mais que `Restrito a
  /// curso` quando o curso é conhecido.
  String get alcance => switch (visibilidade) {
    Visibilidade.curso => 'Restrito a ${curso?.nome ?? 'um curso'}',
    _ => visibilidade.rotulo,
  };

  /// Alcance que não é público — o que justifica mostrar a etiqueta em destaque.
  bool get restrito => visibilidade != Visibilidade.publico;
}

/// Quem comentou: nome, arroba e foto, e nada além.
@freezed
abstract class AutorDeComentario with _$AutorDeComentario {
  const factory AutorDeComentario({
    required String id,
    required String nomeCompleto,
    required String username,
    String? fotoUrl,
  }) = _AutorDeComentario;

  factory AutorDeComentario.fromJson(Map<String, dynamic> json) =>
      _$AutorDeComentarioFromJson(json);
}

extension AutorDeComentarioX on AutorDeComentario {
  /// Iniciais para o avatar sem foto. Mesma regra de [PerfilX.iniciais] — e
  /// duplicada de propósito: são dois tipos diferentes, e generalizar exigiria
  /// uma interface só para isto.
  String get iniciais {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (partes.isEmpty) return '?';
    if (partes.length == 1) {
      final unico = partes.first;
      return (unico.length >= 2 ? unico.substring(0, 2) : unico).toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}

@freezed
abstract class Comentario with _$Comentario {
  const factory Comentario({
    required String id,
    required String postId,
    required AutorDeComentario autor,
    required String conteudo,
    required DateTime criadoEm,

    /// Autor do comentário, ou a faculdade autora do post (moderação). Vem do
    /// servidor: um botão que a tela decide mostrar e o servidor recusa é
    /// exatamente o que duas cópias da regra produzem.
    @Default(false) bool podeRemover,
  }) = _Comentario;

  factory Comentario.fromJson(Map<String, dynamic> json) =>
      _$ComentarioFromJson(json);
}

/// Uma página do feed.
///
/// [proximoCursor] nulo é o fim da lista. O cursor é **opaco**: codifica a data e
/// o id do último item, e a tela só o devolve como veio. Com deslocamento
/// numérico, um post publicado entre duas páginas repetiria um item na segunda.
@freezed
abstract class PaginaDePosts with _$PaginaDePosts {
  const factory PaginaDePosts({
    @Default(<Post>[]) List<Post> itens,
    String? proximoCursor,
  }) = _PaginaDePosts;

  factory PaginaDePosts.fromJson(Map<String, dynamic> json) =>
      _$PaginaDePostsFromJson(json);
}

@freezed
abstract class PaginaDeComentarios with _$PaginaDeComentarios {
  const factory PaginaDeComentarios({
    @Default(<Comentario>[]) List<Comentario> itens,
    String? proximoCursor,
  }) = _PaginaDeComentarios;

  factory PaginaDeComentarios.fromJson(Map<String, dynamic> json) =>
      _$PaginaDeComentariosFromJson(json);
}

/// O seletor de escopo do feed acadêmico.
///
/// Espelha o parâmetro `escopo` de `GET /academic/posts`, e o nome dos dois
/// valores importa: **escopo escolhe quais instituições entram, nunca qual
/// conteúdo**. A matriz de visibilidade vale igual nos dois casos.
enum EscopoDoFeed {
  geral('geral', 'Geral', 'Sua instituição e as que você segue'),
  minha('minha', 'Minha instituição', 'Só a instituição do seu vínculo');

  const EscopoDoFeed(this.valor, this.rotulo, this.descricao);

  /// O valor que vai na query string.
  final String valor;
  final String rotulo;
  final String descricao;
}

/// O seletor de escopo do pilar Profissional.
///
/// Mora aqui, ao lado do acadêmico, porque os dois alimentam o mesmo widget de
/// botão e porque lê-los lado a lado deixa claro que **filtram coisas diferentes**:
/// o acadêmico escolhe instituições, este escolhe **quem publica**.
///
/// Existe antes do `feed-service`, que entra na Sprint 5. Nenhum valor chega a um
/// servidor hoje: a escolha fica no provider e a tela de vazio a repete, para o
/// controle ser real em vez de decorativo. Quando o serviço subir, `valor` vai na
/// query string do jeito que já está escrito.
enum EscopoDoProfissional {
  geral('geral', 'Geral', 'Posts de pessoas e de empresas, com recomendações'),
  empresas('empresas', 'Só empresas', 'Vagas e comunicados de quem contrata'),
  pessoas(
    'pessoas',
    'Só pessoas',
    'Posts de quem você segue e de outros alunos',
  );

  const EscopoDoProfissional(this.valor, this.rotulo, this.descricao);

  final String valor;
  final String rotulo;
  final String descricao;
}
