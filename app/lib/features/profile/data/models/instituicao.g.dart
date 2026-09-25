// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instituicao.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PerfilDeUniversidade _$PerfilDeUniversidadeFromJson(
  Map<String, dynamic> json,
) => _PerfilDeUniversidade(
  id: json['id'] as String,
  nome: json['nome'] as String,
  sigla: json['sigla'] as String,
  temVinculo: json['temVinculo'] as bool,
  seguindo: json['seguindo'] as bool,
  totalDeAlunos: (json['totalDeAlunos'] as num?)?.toInt() ?? 0,
  bio: json['bio'] as String?,
  fotoUrl: json['fotoUrl'] as String?,
);

Map<String, dynamic> _$PerfilDeUniversidadeToJson(
  _PerfilDeUniversidade instance,
) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
  'sigla': instance.sigla,
  'temVinculo': instance.temVinculo,
  'seguindo': instance.seguindo,
  'totalDeAlunos': instance.totalDeAlunos,
  'bio': instance.bio,
  'fotoUrl': instance.fotoUrl,
};

_UniversidadeSeguida _$UniversidadeSeguidaFromJson(Map<String, dynamic> json) =>
    _UniversidadeSeguida(
      id: json['id'] as String,
      nome: json['nome'] as String,
      sigla: json['sigla'] as String,
      propria: json['propria'] as bool,
      temConta: json['temConta'] as bool? ?? false,
      seguidaEm: json['seguidaEm'] == null
          ? null
          : DateTime.parse(json['seguidaEm'] as String),
    );

Map<String, dynamic> _$UniversidadeSeguidaToJson(
  _UniversidadeSeguida instance,
) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
  'sigla': instance.sigla,
  'propria': instance.propria,
  'temConta': instance.temConta,
  'seguidaEm': instance.seguidaEm?.toIso8601String(),
};

_ResultadoDeBusca _$ResultadoDeBuscaFromJson(Map<String, dynamic> json) =>
    _ResultadoDeBusca(
      universidades:
          (json['universidades'] as List<dynamic>?)
              ?.map((e) => Universidade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Universidade>[],
      empresas:
          (json['empresas'] as List<dynamic>?)
              ?.map((e) => Perfil.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Perfil>[],
      pessoas:
          (json['pessoas'] as List<dynamic>?)
              ?.map((e) => Perfil.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Perfil>[],
    );

Map<String, dynamic> _$ResultadoDeBuscaToJson(_ResultadoDeBusca instance) =>
    <String, dynamic>{
      'universidades': instance.universidades,
      'empresas': instance.empresas,
      'pessoas': instance.pessoas,
    };
