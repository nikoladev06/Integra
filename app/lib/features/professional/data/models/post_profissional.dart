import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_profissional.freezed.dart';
part 'post_profissional.g.dart';

/// O tipo da conta que publicou, e o que o escopo da tela filtra.
///
/// Espelha `components.schemas.TipoDeAutor` em `contracts/feed.openapi.yaml`.
/// `faculdade` **não** está aqui, e a ausência é a regra: comunicado de instituição
/// é o pilar Acadêmico. Uma faculdade publicando no feed profissional diria a mesma
/// coisa duas vezes em dois lugares, e o aluno leria o comunicado dela duas vezes
/// por motivos diferentes.
@JsonEnum(fieldRename: FieldRename.none)
enum TipoDeAutor {
  aluno('Aluno'),
  empresa('Empresa');

  const TipoDeAutor(this.rotulo);

  final String rotulo;
}

/// Por que este post está no feed.
///
/// A tela marca os `recomendado` visualmente. Sem a marca, o usuário não entende
/// por que vê alguém que não segue — e a reação costuma ser desconfiança, não
/// descoberta.
///
/// **Nulo fora do feed.** No detalhe de um post, na publicação e na aba de
/// publicações de um perfil o servidor não preenche o campo: ali ninguém fez a
/// pergunta "por que estou vendo isto?", e responder custaria uma ida ao
/// user-service por post aberto só para descobrir se o leitor segue o autor.
@JsonEnum(fieldRename: FieldRename.none)
enum OrigemNoFeed {
  /// Quem o leitor segue — **e os próprios posts dele**. Quem publicou não precisa
  /// de explicação para se ver no próprio feed.
  seguindo('Você segue'),

  /// Aluno com vínculo ativo numa universidade que o leitor tem vínculo ou segue.
  /// Empresa nunca aparece aqui: empresa não tem vínculo, então só alcança quem a
  /// segue.
  recomendado('Recomendado');

  const OrigemNoFeed(this.rotulo);

  final String rotulo;
}

/// Quem publicou.
///
/// Nome e foto são resolvidos **na leitura** pelo serviço, em lote — não copiados
/// para dentro do post. O protótipo denormalizava `nomeCompleto` e o nome
/// envelhecia ali. O `tipo`, ao contrário, é coluna do post: é o que o escopo
/// filtra na consulta paginada, e resolvê-lo depois faria uma página de 20 vir com
/// 3 itens.
@freezed
abstract class AutorDePost with _$AutorDePost {
  const factory AutorDePost({
    required String id,
    required String nomeCompleto,
    required String username,
    required TipoDeAutor tipo,
    String? fotoUrl,
  }) = _AutorDePost;

  factory AutorDePost.fromJson(Map<String, dynamic> json) =>
      _$AutorDePostFromJson(json);
}

extension AutorDePostX on AutorDePost {
  /// Iniciais para o avatar sem foto. Mesma regra de [PerfilX.iniciais] e de
  /// [AutorDeComentarioX.iniciais] — duplicada de propósito: são tipos diferentes,
  /// e generalizar exigiria uma interface só para isto.
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

/// Um post do feed profissional.
///
/// **Não há alcance.** Ao contrário do comunicado institucional, todo post aqui é
/// legível por qualquer conta autenticada — não existe `visibilidade`, não existe
/// vínculo a consultar, e `GET /feed/posts/{id}` nunca responde 404 por permissão.
@freezed
abstract class PostProfissional with _$PostProfissional {
  const factory PostProfissional({
    required String id,
    required AutorDePost autor,
    required String conteudo,
    required DateTime criadoEm,

    /// A imagem no storage, enviada pelo cliente antes de publicar. Nula na grande
    /// maioria: o card é de texto por padrão.
    String? imagemUrl,

    /// Nula fora do feed — ver [OrigemNoFeed].
    OrigemNoFeed? origem,
    @Default(0) int totalDeCurtidas,
    @Default(0) int totalDeComentarios,

    /// Estado **por leitor**, calculado na consulta. O `isLiked` do protótipo fazia
    /// a curtida de uma pessoa aparecer para todas.
    @Default(false) bool curtidoPorMim,

    /// Se o leitor é o autor. Vem do servidor em vez de a tela comparar ids — e
    /// concluir diferente dele num caso de borda.
    @Default(false) bool podeEditar,
    DateTime? editadoEm,
  }) = _PostProfissional;

  factory PostProfissional.fromJson(Map<String, dynamic> json) =>
      _$PostProfissionalFromJson(json);
}

extension PostProfissionalX on PostProfissional {
  bool get editado => editadoEm != null;
  bool get temImagem => imagemUrl != null && imagemUrl!.isNotEmpty;

  /// Se vale mostrar a etiqueta de origem. Só `recomendado` justifica: "você
  /// segue" é o caso esperado, e etiquetar o esperado polui o card sem informar.
  bool get explicaOrigem => origem == OrigemNoFeed.recomendado;
}

/// Quem comentou: nome, arroba e foto. **Sem `tipo`.**
///
/// Nenhum escopo filtra comentário, então o tipo do autor não é coluna de
/// `feed.comentarios` — e o contrato não promete um campo que o serviço não tem
/// como preencher corretamente. É o mesmo formato do `AutorDeComentario` do
/// pilar Acadêmico.
@freezed
abstract class AutorDeComentarioProfissional
    with _$AutorDeComentarioProfissional {
  const factory AutorDeComentarioProfissional({
    required String id,
    required String nomeCompleto,
    required String username,
    String? fotoUrl,
  }) = _AutorDeComentarioProfissional;

  factory AutorDeComentarioProfissional.fromJson(Map<String, dynamic> json) =>
      _$AutorDeComentarioProfissionalFromJson(json);
}

extension AutorDeComentarioProfissionalX on AutorDeComentarioProfissional {
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
abstract class ComentarioProfissional with _$ComentarioProfissional {
  const factory ComentarioProfissional({
    required String id,
    required String postId,
    required AutorDeComentarioProfissional autor,
    required String conteudo,
    required DateTime criadoEm,

    /// Autor do comentário, **ou autor do post** (moderação). No Acadêmico quem
    /// modera é a faculdade autora do comunicado; aqui é a pessoa ou empresa que
    /// publicou. Vem do servidor: um botão que a tela mostra e o servidor recusa é
    /// exatamente o que duas cópias da regra produzem.
    @Default(false) bool podeRemover,
  }) = _ComentarioProfissional;

  factory ComentarioProfissional.fromJson(Map<String, dynamic> json) =>
      _$ComentarioProfissionalFromJson(json);
}

/// Uma página do feed profissional.
///
/// [proximoCursor] nulo é o fim. O cursor é **opaco**: a tela o devolve como veio.
@freezed
abstract class PaginaDePostsProfissionais with _$PaginaDePostsProfissionais {
  const factory PaginaDePostsProfissionais({
    @Default(<PostProfissional>[]) List<PostProfissional> itens,
    String? proximoCursor,
  }) = _PaginaDePostsProfissionais;

  factory PaginaDePostsProfissionais.fromJson(Map<String, dynamic> json) =>
      _$PaginaDePostsProfissionaisFromJson(json);
}

@freezed
abstract class PaginaDeComentariosProfissionais
    with _$PaginaDeComentariosProfissionais {
  const factory PaginaDeComentariosProfissionais({
    @Default(<ComentarioProfissional>[]) List<ComentarioProfissional> itens,
    String? proximoCursor,
  }) = _PaginaDeComentariosProfissionais;

  factory PaginaDeComentariosProfissionais.fromJson(Map<String, dynamic> json) =>
      _$PaginaDeComentariosProfissionaisFromJson(json);
}

/// O que `POST /feed/posts/imagem/upload-url` e
/// `POST /users/me/avatar/upload-url` devolvem.
///
/// Um tipo para as duas rotas: o formato é o mesmo, e o nome do campo final muda
/// (`imagemUrl` num, `fotoUrl` no outro) — os repositórios traduzem, porque dois
/// tipos idênticos divergiriam no primeiro campo novo.
///
/// O fluxo é de três passos, e o serviço só participa do primeiro: pedir a URL,
/// fazer `PUT` do arquivo direto no storage, e então gravar [urlFinal] no post ou
/// no perfil. **Bytes de imagem nunca atravessam os serviços.**
@freezed
abstract class UrlDeUpload with _$UrlDeUpload {
  const factory UrlDeUpload({
    /// Destino do `PUT`, com assinatura de curta validade. O `PUT` tem que levar
    /// exatamente o `Content-Type` e o `Content-Length` declarados ao pedir — os
    /// dois entram na assinatura, e é o que faz o limite de tamanho ser do
    /// storage e não uma promessa do cliente.
    required String uploadUrl,

    /// A URL a gravar depois que o `PUT` tiver sucesso.
    required String urlFinal,
    required DateTime expiraEm,
  }) = _UrlDeUpload;
}
