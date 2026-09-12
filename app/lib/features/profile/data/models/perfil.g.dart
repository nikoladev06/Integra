// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perfil.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Universidade _$UniversidadeFromJson(Map<String, dynamic> json) =>
    _Universidade(
      id: json['id'] as String,
      nome: json['nome'] as String,
      sigla: json['sigla'] as String,
    );

Map<String, dynamic> _$UniversidadeToJson(_Universidade instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'sigla': instance.sigla,
    };

_Curso _$CursoFromJson(Map<String, dynamic> json) =>
    _Curso(id: json['id'] as String, nome: json['nome'] as String);

Map<String, dynamic> _$CursoToJson(_Curso instance) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
};

_Afiliacao _$AfiliacaoFromJson(Map<String, dynamic> json) => _Afiliacao(
  universidade: Universidade.fromJson(
    json['universidade'] as Map<String, dynamic>,
  ),
  curso: Curso.fromJson(json['curso'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AfiliacaoToJson(_Afiliacao instance) =>
    <String, dynamic>{
      'universidade': instance.universidade,
      'curso': instance.curso,
    };

_Perfil _$PerfilFromJson(Map<String, dynamic> json) => _Perfil(
  id: json['id'] as String,
  nomeCompleto: json['nomeCompleto'] as String,
  username: json['username'] as String,
  tipo: $enumDecode(_$TipoContaEnumMap, json['tipo']),
  afiliacao: Afiliacao.fromJson(json['afiliacao'] as Map<String, dynamic>),
  criadoEm: DateTime.parse(json['criadoEm'] as String),
  fotoUrl: json['fotoUrl'] as String?,
  bio: json['bio'] as String?,
  email: json['email'] as String?,
  telefone: json['telefone'] as String?,
  alteradoEm: json['alteradoEm'] == null
      ? null
      : DateTime.parse(json['alteradoEm'] as String),
);

Map<String, dynamic> _$PerfilToJson(_Perfil instance) => <String, dynamic>{
  'id': instance.id,
  'nomeCompleto': instance.nomeCompleto,
  'username': instance.username,
  'tipo': _$TipoContaEnumMap[instance.tipo]!,
  'afiliacao': instance.afiliacao,
  'criadoEm': instance.criadoEm.toIso8601String(),
  'fotoUrl': instance.fotoUrl,
  'bio': instance.bio,
  'email': instance.email,
  'telefone': instance.telefone,
  'alteradoEm': instance.alteradoEm?.toIso8601String(),
};

const _$TipoContaEnumMap = {
  TipoConta.aluno: 'aluno',
  TipoConta.faculdade: 'faculdade',
  TipoConta.empresa: 'empresa',
};
