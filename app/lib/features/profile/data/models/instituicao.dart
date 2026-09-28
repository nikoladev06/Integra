import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/shared/domain/documentos.dart';

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
    /// oferece "inserir CPF" ou "encerrar vínculo", e o texto do vazio de cada aba
    /// restrita.
    ///
    /// **Não aparece como selo na tela.** "Você tem vínculo aqui" era redundante: o
    /// menu e as abas já respondem a mesma pergunta onde ela é feita.
    required bool temVinculo,
    required bool seguindo,

    // Não há contagem de alunos. Ela existiu até o contrato de `user` 2.1.0 e saiu
    // da **resposta da API**, não só daqui: quantos alunos uma faculdade tem no
    // Integra é informação dela.
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

/// Um aluno na lista de matrículas da instituição.
///
/// Espelha `components.schemas.Matricula`. Duas coisas a notar, e as duas são do
/// modelo e não da tela:
///
/// [cpf] vem **só para a instituição que o cadastrou** — foi ela que o digitou.
/// Nunca aparece em resposta pública nem para outra instituição.
///
/// [usuario] é nulo enquanto ninguém reivindicou aquele CPF. É o caso comum: a
/// faculdade matricula quem **ainda não tem conta**, e o encontro acontece quando
/// a pessoa informa o CPF no perfil dela. Por isso não existe chave estrangeira
/// para usuário no banco — o CPF é o único elo.
@freezed
abstract class Matricula with _$Matricula {
  const factory Matricula({
    required String id,
    required String cpf,
    required Curso curso,
    required DateTime criadoEm,

    /// Se já existe conta com este CPF **e vínculo ativo** aqui.
    @Default(false) bool vinculada,
    Perfil? usuario,
  }) = _Matricula;

  factory Matricula.fromJson(Map<String, dynamic> json) =>
      _$MatriculaFromJson(json);
}

extension MatriculaX on Matricula {
  /// CPF formatado para leitura da secretaria: `000.000.000-00`.
  ///
  /// Sem máscara parcial. Mascarar o CPF **nesta** tela seria teatro: a
  /// instituição digitou o número, e esconder um dígito não protege de quem já o
  /// tem — só dificulta conferir a lista.
  String get cpfFormatado => formatarCpf(cpf);

  /// Aguardando a pessoa informar o CPF no perfil da instituição.
  bool get pendente => !vinculada;
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
