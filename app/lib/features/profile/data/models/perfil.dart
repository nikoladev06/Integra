import 'package:freezed_annotation/freezed_annotation.dart';

part 'perfil.freezed.dart';
part 'perfil.g.dart';

/// Tipo de conta. Espelha `components.schemas.TipoConta` em
/// `contracts/user.openapi.yaml`.
///
/// Os três nascem por autocadastro desde a v2: `aluno` em `POST /auth/register`,
/// `faculdade` e `empresa` em `POST /auth/register/instituicao`. O que separa os
/// dois caminhos é o documento — CPF de um lado, CNPJ do outro — e o fato de a
/// conta institucional nascer pendente de ativação.
@JsonEnum(fieldRename: FieldRename.none)
enum TipoConta {
  aluno('Aluno'),
  faculdade('Faculdade'),
  empresa('Empresa');

  const TipoConta(this.rotulo);

  final String rotulo;

  /// `true` para os tipos que se cadastram com CNPJ.
  bool get eInstitucional => this != TipoConta.aluno;
}

@freezed
abstract class Universidade with _$Universidade {
  const factory Universidade({
    required String id,
    required String nome,
    required String sigla,

    /// Se já existe conta institucional administrando esta universidade.
    ///
    /// O perfil de uma sem conta não tem posts nem matrículas — e a tela diz
    /// isso, em vez de mostrar um feed vazio sem explicação.
    @Default(false) bool temConta,
  }) = _Universidade;

  factory Universidade.fromJson(Map<String, dynamic> json) =>
      _$UniversidadeFromJson(json);
}

@freezed
abstract class Curso with _$Curso {
  const factory Curso({required String id, required String nome}) = _Curso;

  factory Curso.fromJson(Map<String, dynamic> json) => _$CursoFromJson(json);
}

/// Uma linha do currículo — **autodeclarada e cosmética**.
///
/// Substitui a `Afiliacao` da v1, que era única, obrigatória e concedia acesso
/// aos posts internos da instituição. Bastava *dizer* que se estudava numa
/// faculdade para ler os comunicados dela. Agora declarar não concede nada:
/// quem concede é o [Vinculo].
///
/// [verificadaEm] não nulo é o selo, e o selo é **permanente** — quem se formou
/// realmente estudou lá. A tela mostra apenas o selo, sem rótulo algum nas não
/// verificadas: a ausência já comunica o suficiente.
@freezed
abstract class Formacao with _$Formacao {
  const factory Formacao({
    required String id,
    required Universidade universidade,
    required Curso curso,
    required DateTime criadoEm,
    DateTime? verificadaEm,
  }) = _Formacao;

  factory Formacao.fromJson(Map<String, dynamic> json) =>
      _$FormacaoFromJson(json);
}

extension FormacaoX on Formacao {
  bool get verificada => verificadaEm != null;
}

/// O laço ativo com a instituição — **o único que concede visibilidade**.
///
/// No máximo um por usuário: no banco, `vinculos.usuario_id` é a chave
/// primária, então não existe estado com dois vínculos nem por condição de
/// corrida. Nasce quando o aluno informa o CPF no perfil da faculdade e aquele
/// CPF consta na lista de matrículas dela.
///
/// A regra que nenhuma tela pode esquecer: **formação verificada sem vínculo
/// ativo não concede nada.** Quem se formou mantém o selo e volta a ver só os
/// posts públicos.
@freezed
abstract class Vinculo with _$Vinculo {
  const factory Vinculo({
    required Universidade universidade,
    required Curso curso,
    required DateTime criadoEm,
  }) = _Vinculo;

  factory Vinculo.fromJson(Map<String, dynamic> json) =>
      _$VinculoFromJson(json);
}

/// Perfil de usuário.
///
/// Uma classe só para `PerfilPublico` e `Perfil` do contrato: os campos que só
/// existem no próprio perfil — [email], [cpf], [cnpj], [telefone], [ativadaEm]
/// — são nulos quando o perfil vem de `GET /users/{id}`. Duas classes quase
/// idênticas custariam mais do que o campo nulo, e [eOProprioPerfil] resolve a
/// distinção onde ela importa.
@freezed
abstract class Perfil with _$Perfil {
  const factory Perfil({
    required String id,
    required String nomeCompleto,
    required String username,
    required TipoConta tipo,
    required DateTime criadoEm,

    /// O currículo. Pode estar vazio — é o estado de quem acabou de entrar.
    @Default(<Formacao>[]) List<Formacao> formacoes,

    /// A instituição atual, quando há. Público de propósito: é o equivalente a
    /// "trabalha em" num perfil profissional.
    Vinculo? vinculo,
    String? fotoUrl,
    String? bio,

    // ---- só em `GET /users/me` ----
    String? email,

    /// Apenas dígitos. Nulo em conta `faculdade` e `empresa`.
    String? cpf,

    /// Apenas dígitos. Nulo em conta de aluno. Uma conta nunca tem os dois.
    String? cnpj,
    String? telefone,

    /// Quando a conta passou a poder agir. **Nulo significa pendente**, e só
    /// acontece em conta institucional: a de aluno nasce ativa.
    DateTime? ativadaEm,
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

  /// Conta institucional ainda em análise: entra e edita o perfil, mas não
  /// publica nem matricula. A tela usa isto para mostrar o aviso.
  ///
  /// Conta de aluno nasce ativa, então nunca cai aqui.
  bool get aguardandoAtivacao => tipo.eInstitucional && ativadaEm == null;

  /// As formações com selo, na ordem em que vieram do serviço.
  List<Formacao> get formacoesVerificadas =>
      formacoes.where((f) => f.verificada).toList();
}
