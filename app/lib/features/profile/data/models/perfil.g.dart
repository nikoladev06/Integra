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
      temConta: json['temConta'] as bool? ?? false,
    );

Map<String, dynamic> _$UniversidadeToJson(_Universidade instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'sigla': instance.sigla,
      'temConta': instance.temConta,
    };

_Curso _$CursoFromJson(Map<String, dynamic> json) =>
    _Curso(id: json['id'] as String, nome: json['nome'] as String);

Map<String, dynamic> _$CursoToJson(_Curso instance) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
};

_Formacao _$FormacaoFromJson(Map<String, dynamic> json) => _Formacao(
  id: json['id'] as String,
  universidade: Universidade.fromJson(
    json['universidade'] as Map<String, dynamic>,
  ),
  curso: Curso.fromJson(json['curso'] as Map<String, dynamic>),
  criadoEm: DateTime.parse(json['criadoEm'] as String),
  verificadaEm: json['verificadaEm'] == null
      ? null
      : DateTime.parse(json['verificadaEm'] as String),
);

Map<String, dynamic> _$FormacaoToJson(_Formacao instance) => <String, dynamic>{
  'id': instance.id,
  'universidade': instance.universidade,
  'curso': instance.curso,
  'criadoEm': instance.criadoEm.toIso8601String(),
  'verificadaEm': instance.verificadaEm?.toIso8601String(),
};

_Vinculo _$VinculoFromJson(Map<String, dynamic> json) => _Vinculo(
  universidade: Universidade.fromJson(
    json['universidade'] as Map<String, dynamic>,
  ),
  curso: Curso.fromJson(json['curso'] as Map<String, dynamic>),
  criadoEm: DateTime.parse(json['criadoEm'] as String),
);

Map<String, dynamic> _$VinculoToJson(_Vinculo instance) => <String, dynamic>{
  'universidade': instance.universidade,
  'curso': instance.curso,
  'criadoEm': instance.criadoEm.toIso8601String(),
};

_Perfil _$PerfilFromJson(Map<String, dynamic> json) => _Perfil(
  id: json['id'] as String,
  nomeCompleto: json['nomeCompleto'] as String,
  username: json['username'] as String,
  tipo: $enumDecode(_$TipoContaEnumMap, json['tipo']),
  criadoEm: DateTime.parse(json['criadoEm'] as String),
  formacoes:
      (json['formacoes'] as List<dynamic>?)
          ?.map((e) => Formacao.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Formacao>[],
  vinculo: json['vinculo'] == null
      ? null
      : Vinculo.fromJson(json['vinculo'] as Map<String, dynamic>),
  fotoUrl: json['fotoUrl'] as String?,
  bio: json['bio'] as String?,
  email: json['email'] as String?,
  cpf: json['cpf'] as String?,
  cnpj: json['cnpj'] as String?,
  telefone: json['telefone'] as String?,
  ativadaEm: json['ativadaEm'] == null
      ? null
      : DateTime.parse(json['ativadaEm'] as String),
  alteradoEm: json['alteradoEm'] == null
      ? null
      : DateTime.parse(json['alteradoEm'] as String),
);

Map<String, dynamic> _$PerfilToJson(_Perfil instance) => <String, dynamic>{
  'id': instance.id,
  'nomeCompleto': instance.nomeCompleto,
  'username': instance.username,
  'tipo': _$TipoContaEnumMap[instance.tipo]!,
  'criadoEm': instance.criadoEm.toIso8601String(),
  'formacoes': instance.formacoes,
  'vinculo': instance.vinculo,
  'fotoUrl': instance.fotoUrl,
  'bio': instance.bio,
  'email': instance.email,
  'cpf': instance.cpf,
  'cnpj': instance.cnpj,
  'telefone': instance.telefone,
  'ativadaEm': instance.ativadaEm?.toIso8601String(),
  'alteradoEm': instance.alteradoEm?.toIso8601String(),
};

const _$TipoContaEnumMap = {
  TipoConta.aluno: 'aluno',
  TipoConta.faculdade: 'faculdade',
  TipoConta.empresa: 'empresa',
};
