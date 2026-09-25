import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:integra/features/profile/data/models/perfil.dart';

part 'instituicao.freezed.dart';
part 'instituicao.g.dart';

/// A tela de universidade que o aluno alcança pela busca.
///
/// Espelha `components.schemas.PerfilDeUniversidade`. [temVinculo] e [seguindo]
/// são calculados **no serviço**, para o leitor do lado do aluno: sem eles a
/// tela teria que cruzar duas respostas para saber o que o menu deve oferecer.
@freezed
abstract class PerfilDeUniversidade with _$PerfilDeUniversidade {
  const factory PerfilDeUniversidade({
    required String id,
    required String nome,
    required String sigla,

    /// Se o leitor tem vínculo ativo com esta instituição. Decide se o menu
    /// oferece "inserir CPF" ou "encerrar vínculo".
    required bool temVinculo,
    required bool seguindo,

    /// Quantos têm vínculo ativo. Agregado, sem expor quem.
    @Default(0) int totalDeAlunos,
    String? bio,
    String? fotoUrl,
  }) = _PerfilDeUniversidade;

  factory PerfilDeUniversidade.fromJson(Map<String, dynamic> json) =>
      _$PerfilDeUniversidadeFromJson(json);
}

/// Uma universidade na lista de seguidas.
///
/// [propria] marca a do vínculo ativo, que entra na lista mesmo sem o usuário
/// ter clicado em seguir — e não é removível enquanto o vínculo existir.
@freezed
abstract class UniversidadeSeguida with _$UniversidadeSeguida {
  const factory UniversidadeSeguida({
    required String id,
    required String nome,
    required String sigla,
    required bool propria,
    @Default(false) bool temConta,
    DateTime? seguidaEm,
  }) = _UniversidadeSeguida;

  factory UniversidadeSeguida.fromJson(Map<String, dynamic> json) =>
      _$UniversidadeSeguidaFromJson(json);
}

extension UniversidadeSeguidaX on UniversidadeSeguida {
  Universidade get universidade =>
      Universidade(id: id, nome: nome, sigla: sigla, temConta: temConta);
}

/// Resultado de `GET /busca` — a busca do cabeçalho.
///
/// Os três grupos vêm sempre, ainda que vazios. Omitir um faria o cliente ter
/// que distinguir "não achei" de "não pedi este tipo", e a ausência de chave é
/// ambígua para as duas coisas.
@freezed
abstract class ResultadoDeBusca with _$ResultadoDeBusca {
  const factory ResultadoDeBusca({
    @Default(<Universidade>[]) List<Universidade> universidades,
    @Default(<Perfil>[]) List<Perfil> empresas,
    @Default(<Perfil>[]) List<Perfil> pessoas,
  }) = _ResultadoDeBusca;

  factory ResultadoDeBusca.fromJson(Map<String, dynamic> json) =>
      _$ResultadoDeBuscaFromJson(json);
}

extension ResultadoDeBuscaX on ResultadoDeBusca {
  bool get vazio =>
      universidades.isEmpty && empresas.isEmpty && pessoas.isEmpty;

  int get total => universidades.length + empresas.length + pessoas.length;
}
