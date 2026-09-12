// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'par_de_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ParDeTokens _$ParDeTokensFromJson(Map<String, dynamic> json) => _ParDeTokens(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresIn: (json['expiresIn'] as num).toInt(),
  tokenType: json['tokenType'] as String? ?? 'Bearer',
);

Map<String, dynamic> _$ParDeTokensToJson(_ParDeTokens instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'tokenType': instance.tokenType,
    };
