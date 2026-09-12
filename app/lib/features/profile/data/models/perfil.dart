import 'package:freezed_annotation/freezed_annotation.dart';

part 'perfil.freezed.dart';
part 'perfil.g.dart';

/// Tipo de conta. Espelha `components.schemas.TipoConta` em
/// `contracts/user.openapi.yaml`.
///
/// Só `aluno` nasce por autocadastro; `faculdade` e `empresa` são provisionados
/// à mão enquanto não existe verificação institucional.
@JsonEnum(fieldRename: FieldRename.none)
enum TipoConta {
  aluno('Aluno'),
  faculdade('Faculdade'),
  empresa('Empresa');

  const TipoConta(this.rotulo);

  final String rotulo;
}

@freezed
abstract class Universidade with _$Universidade {
  const factory Universidade({
    required String id,
    required String nome,
    required String sigla,
  }) = _Universidade;

  factory Universidade.fromJson(Map<String, dynamic> json) =>
      _$UniversidadeFromJson(json);
}

@freezed
abstract class Curso with _$Curso {
  const factory Curso({required String id, required String nome}) = _Curso;

  factory Curso.fromJson(Map<String, dynamic> json) => _$CursoFromJson(json);
}

/// O vínculo aluno↔faculdade↔curso.
///
/// No protótipo eram duas `String` livres dentro do `UserModel`, o que torna
/// impossível responder "quais alunos são desta faculdade" ou "restrito a este
/// curso" — as duas perguntas centrais do pilar Acadêmico.
@freezed
abstract class Afiliacao with _$Afiliacao {
  const factory Afiliacao({
    required Universidade universidade,
    required Curso curso,
  }) = _Afiliacao;

  factory Afiliacao.fromJson(Map<String, dynamic> json) =>
      _$AfiliacaoFromJson(json);
}

/// Perfil de usuário.
///
/// `email` e `telefone` são nulos quando o perfil vem de
/// `GET /users/{id}` — o contrato omite dados de contato no perfil público, e
/// eles só chegam preenchidos em `GET /users/me`. O tipo carrega essa diferença
/// em vez de duas classes quase idênticas.
@freezed
abstract class Perfil with _$Perfil {
  const factory Perfil({
    required String id,
    required String nomeCompleto,
    required String username,
    required TipoConta tipo,
    required Afiliacao afiliacao,
    required DateTime criadoEm,
    String? fotoUrl,
    String? bio,
    String? email,
    String? telefone,
    DateTime? alteradoEm,
  }) = _Perfil;

  factory Perfil.fromJson(Map<String, dynamic> json) => _$PerfilFromJson(json);
}

extension PerfilX on Perfil {
  /// Iniciais para o avatar quando não há foto.
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

  /// `true` quando vindo de `/users/me` — só aí os dados de contato existem.
  bool get eOProprioPerfil => email != null;
}
