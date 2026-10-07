// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_profissional.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AutorDePost _$AutorDePostFromJson(Map<String, dynamic> json) => _AutorDePost(
  id: json['id'] as String,
  nomeCompleto: json['nomeCompleto'] as String,
  username: json['username'] as String,
  tipo: $enumDecode(_$TipoDeAutorEnumMap, json['tipo']),
  fotoUrl: json['fotoUrl'] as String?,
);

Map<String, dynamic> _$AutorDePostToJson(_AutorDePost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nomeCompleto': instance.nomeCompleto,
      'username': instance.username,
      'tipo': _$TipoDeAutorEnumMap[instance.tipo]!,
      'fotoUrl': instance.fotoUrl,
    };

const _$TipoDeAutorEnumMap = {
  TipoDeAutor.aluno: 'aluno',
  TipoDeAutor.empresa: 'empresa',
};

_PostProfissional _$PostProfissionalFromJson(Map<String, dynamic> json) =>
    _PostProfissional(
      id: json['id'] as String,
      autor: AutorDePost.fromJson(json['autor'] as Map<String, dynamic>),
      conteudo: json['conteudo'] as String,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      imagemUrl: json['imagemUrl'] as String?,
      origem: $enumDecodeNullable(_$OrigemNoFeedEnumMap, json['origem']),
      totalDeCurtidas: (json['totalDeCurtidas'] as num?)?.toInt() ?? 0,
      totalDeComentarios: (json['totalDeComentarios'] as num?)?.toInt() ?? 0,
      curtidoPorMim: json['curtidoPorMim'] as bool? ?? false,
      podeEditar: json['podeEditar'] as bool? ?? false,
      editadoEm: json['editadoEm'] == null
          ? null
          : DateTime.parse(json['editadoEm'] as String),
    );

Map<String, dynamic> _$PostProfissionalToJson(_PostProfissional instance) =>
    <String, dynamic>{
      'id': instance.id,
      'autor': instance.autor,
      'conteudo': instance.conteudo,
      'criadoEm': instance.criadoEm.toIso8601String(),
      'imagemUrl': instance.imagemUrl,
      'origem': _$OrigemNoFeedEnumMap[instance.origem],
      'totalDeCurtidas': instance.totalDeCurtidas,
      'totalDeComentarios': instance.totalDeComentarios,
      'curtidoPorMim': instance.curtidoPorMim,
      'podeEditar': instance.podeEditar,
      'editadoEm': instance.editadoEm?.toIso8601String(),
    };

const _$OrigemNoFeedEnumMap = {
  OrigemNoFeed.seguindo: 'seguindo',
  OrigemNoFeed.recomendado: 'recomendado',
};

_AutorDeComentarioProfissional _$AutorDeComentarioProfissionalFromJson(
  Map<String, dynamic> json,
) => _AutorDeComentarioProfissional(
  id: json['id'] as String,
  nomeCompleto: json['nomeCompleto'] as String,
  username: json['username'] as String,
  fotoUrl: json['fotoUrl'] as String?,
);

Map<String, dynamic> _$AutorDeComentarioProfissionalToJson(
  _AutorDeComentarioProfissional instance,
) => <String, dynamic>{
  'id': instance.id,
  'nomeCompleto': instance.nomeCompleto,
  'username': instance.username,
  'fotoUrl': instance.fotoUrl,
};

_ComentarioProfissional _$ComentarioProfissionalFromJson(
  Map<String, dynamic> json,
) => _ComentarioProfissional(
  id: json['id'] as String,
  postId: json['postId'] as String,
  autor: AutorDeComentarioProfissional.fromJson(
    json['autor'] as Map<String, dynamic>,
  ),
  conteudo: json['conteudo'] as String,
  criadoEm: DateTime.parse(json['criadoEm'] as String),
  podeRemover: json['podeRemover'] as bool? ?? false,
);

Map<String, dynamic> _$ComentarioProfissionalToJson(
  _ComentarioProfissional instance,
) => <String, dynamic>{
  'id': instance.id,
  'postId': instance.postId,
  'autor': instance.autor,
  'conteudo': instance.conteudo,
  'criadoEm': instance.criadoEm.toIso8601String(),
  'podeRemover': instance.podeRemover,
};

_PaginaDePostsProfissionais _$PaginaDePostsProfissionaisFromJson(
  Map<String, dynamic> json,
) => _PaginaDePostsProfissionais(
  itens:
      (json['itens'] as List<dynamic>?)
          ?.map((e) => PostProfissional.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PostProfissional>[],
  proximoCursor: json['proximoCursor'] as String?,
);

Map<String, dynamic> _$PaginaDePostsProfissionaisToJson(
  _PaginaDePostsProfissionais instance,
) => <String, dynamic>{
  'itens': instance.itens,
  'proximoCursor': instance.proximoCursor,
};

_PaginaDeComentariosProfissionais _$PaginaDeComentariosProfissionaisFromJson(
  Map<String, dynamic> json,
) => _PaginaDeComentariosProfissionais(
  itens:
      (json['itens'] as List<dynamic>?)
          ?.map(
            (e) => ComentarioProfissional.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ComentarioProfissional>[],
  proximoCursor: json['proximoCursor'] as String?,
);

Map<String, dynamic> _$PaginaDeComentariosProfissionaisToJson(
  _PaginaDeComentariosProfissionais instance,
) => <String, dynamic>{
  'itens': instance.itens,
  'proximoCursor': instance.proximoCursor,
};
