// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vaga.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmpresaDaVaga _$EmpresaDaVagaFromJson(Map<String, dynamic> json) =>
    _EmpresaDaVaga(
      id: json['id'] as String,
      nome: json['nome'] as String,
      username: json['username'] as String,
      fotoUrl: json['fotoUrl'] as String?,
    );

Map<String, dynamic> _$EmpresaDaVagaToJson(_EmpresaDaVaga instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'username': instance.username,
      'fotoUrl': instance.fotoUrl,
    };

_CandidatoResumo _$CandidatoResumoFromJson(Map<String, dynamic> json) =>
    _CandidatoResumo(
      id: json['id'] as String,
      nomeCompleto: json['nomeCompleto'] as String,
      username: json['username'] as String,
      fotoUrl: json['fotoUrl'] as String?,
    );

Map<String, dynamic> _$CandidatoResumoToJson(_CandidatoResumo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nomeCompleto': instance.nomeCompleto,
      'username': instance.username,
      'fotoUrl': instance.fotoUrl,
    };

_Vaga _$VagaFromJson(Map<String, dynamic> json) => _Vaga(
  id: json['id'] as String,
  empresa: EmpresaDaVaga.fromJson(json['empresa'] as Map<String, dynamic>),
  titulo: json['titulo'] as String,
  descricao: json['descricao'] as String,
  tipo: $enumDecode(_$TipoDeVagaEnumMap, json['tipo']),
  modalidade: $enumDecode(_$ModalidadeEnumMap, json['modalidade']),
  estado: $enumDecode(_$EstadoDaVagaEnumMap, json['estado']),
  criadoEm: DateTime.parse(json['criadoEm'] as String),
  local: json['local'] as String?,
  totalDeCandidaturas: (json['totalDeCandidaturas'] as num?)?.toInt() ?? 0,
  candidaturaEnviada: json['candidaturaEnviada'] as bool?,
  podeEditar: json['podeEditar'] as bool? ?? false,
  editadoEm: json['editadoEm'] == null
      ? null
      : DateTime.parse(json['editadoEm'] as String),
);

Map<String, dynamic> _$VagaToJson(_Vaga instance) => <String, dynamic>{
  'id': instance.id,
  'empresa': instance.empresa,
  'titulo': instance.titulo,
  'descricao': instance.descricao,
  'tipo': _$TipoDeVagaEnumMap[instance.tipo]!,
  'modalidade': _$ModalidadeEnumMap[instance.modalidade]!,
  'estado': _$EstadoDaVagaEnumMap[instance.estado]!,
  'criadoEm': instance.criadoEm.toIso8601String(),
  'local': instance.local,
  'totalDeCandidaturas': instance.totalDeCandidaturas,
  'candidaturaEnviada': instance.candidaturaEnviada,
  'podeEditar': instance.podeEditar,
  'editadoEm': instance.editadoEm?.toIso8601String(),
};

const _$TipoDeVagaEnumMap = {
  TipoDeVaga.estagio: 'estagio',
  TipoDeVaga.junior: 'junior',
  TipoDeVaga.trainee: 'trainee',
};

const _$ModalidadeEnumMap = {
  Modalidade.presencial: 'presencial',
  Modalidade.hibrido: 'hibrido',
  Modalidade.remoto: 'remoto',
};

const _$EstadoDaVagaEnumMap = {
  EstadoDaVaga.aberta: 'aberta',
  EstadoDaVaga.fechada: 'fechada',
};

_Candidatura _$CandidaturaFromJson(Map<String, dynamic> json) => _Candidatura(
  id: json['id'] as String,
  vaga: Vaga.fromJson(json['vaga'] as Map<String, dynamic>),
  candidato: CandidatoResumo.fromJson(
    json['candidato'] as Map<String, dynamic>,
  ),
  estado: $enumDecode(_$EstadoDaCandidaturaEnumMap, json['estado']),
  criadoEm: DateTime.parse(json['criadoEm'] as String),
  visualizadaEm: json['visualizadaEm'] == null
      ? null
      : DateTime.parse(json['visualizadaEm'] as String),
);

Map<String, dynamic> _$CandidaturaToJson(_Candidatura instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vaga': instance.vaga,
      'candidato': instance.candidato,
      'estado': _$EstadoDaCandidaturaEnumMap[instance.estado]!,
      'criadoEm': instance.criadoEm.toIso8601String(),
      'visualizadaEm': instance.visualizadaEm?.toIso8601String(),
    };

const _$EstadoDaCandidaturaEnumMap = {
  EstadoDaCandidatura.enviada: 'enviada',
  EstadoDaCandidatura.visualizada: 'visualizada',
};

_PaginaDeVagas _$PaginaDeVagasFromJson(Map<String, dynamic> json) =>
    _PaginaDeVagas(
      itens:
          (json['itens'] as List<dynamic>?)
              ?.map((e) => Vaga.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Vaga>[],
      proximoCursor: json['proximoCursor'] as String?,
    );

Map<String, dynamic> _$PaginaDeVagasToJson(_PaginaDeVagas instance) =>
    <String, dynamic>{
      'itens': instance.itens,
      'proximoCursor': instance.proximoCursor,
    };

_PaginaDeCandidaturas _$PaginaDeCandidaturasFromJson(
  Map<String, dynamic> json,
) => _PaginaDeCandidaturas(
  itens:
      (json['itens'] as List<dynamic>?)
          ?.map((e) => Candidatura.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Candidatura>[],
  proximoCursor: json['proximoCursor'] as String?,
);

Map<String, dynamic> _$PaginaDeCandidaturasToJson(
  _PaginaDeCandidaturas instance,
) => <String, dynamic>{
  'itens': instance.itens,
  'proximoCursor': instance.proximoCursor,
};
