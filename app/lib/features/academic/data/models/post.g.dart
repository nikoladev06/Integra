// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InstituicaoDoPost _$InstituicaoDoPostFromJson(Map<String, dynamic> json) =>
    _InstituicaoDoPost(
      id: json['id'] as String,
      nome: json['nome'] as String,
      sigla: json['sigla'] as String,
      fotoUrl: json['fotoUrl'] as String?,
    );

Map<String, dynamic> _$InstituicaoDoPostToJson(_InstituicaoDoPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'sigla': instance.sigla,
      'fotoUrl': instance.fotoUrl,
    };

_Post _$PostFromJson(Map<String, dynamic> json) => _Post(
  id: json['id'] as String,
  instituicao: InstituicaoDoPost.fromJson(
    json['instituicao'] as Map<String, dynamic>,
  ),
  visibilidade: $enumDecode(_$VisibilidadeEnumMap, json['visibilidade']),
  conteudo: json['conteudo'] as String,
  criadoEm: DateTime.parse(json['criadoEm'] as String),
  curso: json['curso'] == null
      ? null
      : Curso.fromJson(json['curso'] as Map<String, dynamic>),
  totalDeCurtidas: (json['totalDeCurtidas'] as num?)?.toInt() ?? 0,
  totalDeComentarios: (json['totalDeComentarios'] as num?)?.toInt() ?? 0,
  curtidoPorMim: json['curtidoPorMim'] as bool? ?? false,
  podeEditar: json['podeEditar'] as bool? ?? false,
  editadoEm: json['editadoEm'] == null
      ? null
      : DateTime.parse(json['editadoEm'] as String),
);

Map<String, dynamic> _$PostToJson(_Post instance) => <String, dynamic>{
  'id': instance.id,
  'instituicao': instance.instituicao,
  'visibilidade': _$VisibilidadeEnumMap[instance.visibilidade]!,
  'conteudo': instance.conteudo,
  'criadoEm': instance.criadoEm.toIso8601String(),
  'curso': instance.curso,
  'totalDeCurtidas': instance.totalDeCurtidas,
  'totalDeComentarios': instance.totalDeComentarios,
  'curtidoPorMim': instance.curtidoPorMim,
  'podeEditar': instance.podeEditar,
  'editadoEm': instance.editadoEm?.toIso8601String(),
};

const _$VisibilidadeEnumMap = {
  Visibilidade.publico: 'publico',
  Visibilidade.institucional: 'institucional',
  Visibilidade.curso: 'curso',
};

_AutorDeComentario _$AutorDeComentarioFromJson(Map<String, dynamic> json) =>
    _AutorDeComentario(
      id: json['id'] as String,
      nomeCompleto: json['nomeCompleto'] as String,
      username: json['username'] as String,
      fotoUrl: json['fotoUrl'] as String?,
    );

Map<String, dynamic> _$AutorDeComentarioToJson(_AutorDeComentario instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nomeCompleto': instance.nomeCompleto,
      'username': instance.username,
      'fotoUrl': instance.fotoUrl,
    };

_Comentario _$ComentarioFromJson(Map<String, dynamic> json) => _Comentario(
  id: json['id'] as String,
  postId: json['postId'] as String,
  autor: AutorDeComentario.fromJson(json['autor'] as Map<String, dynamic>),
  conteudo: json['conteudo'] as String,
  criadoEm: DateTime.parse(json['criadoEm'] as String),
  podeRemover: json['podeRemover'] as bool? ?? false,
);

Map<String, dynamic> _$ComentarioToJson(_Comentario instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'autor': instance.autor,
      'conteudo': instance.conteudo,
      'criadoEm': instance.criadoEm.toIso8601String(),
      'podeRemover': instance.podeRemover,
    };

_PaginaDePosts _$PaginaDePostsFromJson(Map<String, dynamic> json) =>
    _PaginaDePosts(
      itens:
          (json['itens'] as List<dynamic>?)
              ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Post>[],
      proximoCursor: json['proximoCursor'] as String?,
    );

Map<String, dynamic> _$PaginaDePostsToJson(_PaginaDePosts instance) =>
    <String, dynamic>{
      'itens': instance.itens,
      'proximoCursor': instance.proximoCursor,
    };

_PaginaDeComentarios _$PaginaDeComentariosFromJson(Map<String, dynamic> json) =>
    _PaginaDeComentarios(
      itens:
          (json['itens'] as List<dynamic>?)
              ?.map((e) => Comentario.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Comentario>[],
      proximoCursor: json['proximoCursor'] as String?,
    );

Map<String, dynamic> _$PaginaDeComentariosToJson(
  _PaginaDeComentarios instance,
) => <String, dynamic>{
  'itens': instance.itens,
  'proximoCursor': instance.proximoCursor,
};
