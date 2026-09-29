import 'package:freezed_annotation/freezed_annotation.dart';

part 'vaga.freezed.dart';
part 'vaga.g.dart';

/// O recorte do Integra: quem está na faculdade ou acabou de sair.
///
/// Não há `pleno` nem `senior`, e a ausência é decisão de produto: seriam vagas para
/// quem o app não atende, e a primeira delas na lista já muda o que o produto parece
/// ser.
@JsonEnum(fieldRename: FieldRename.none)
enum TipoDeVaga {
  estagio('Estágio'),
  junior('Júnior'),
  trainee('Trainee');

  const TipoDeVaga(this.rotulo);

  final String rotulo;
}

@JsonEnum(fieldRename: FieldRename.none)
enum Modalidade {
  presencial('Presencial', 'Exige estar no local'),
  hibrido('Híbrido', 'Parte no local, parte remoto'),
  remoto('Remoto', 'De qualquer lugar');

  const Modalidade(this.rotulo, this.explicacao);

  final String rotulo;

  /// Frase para o formulário, onde a escolha é consequente — ela decide se o campo
  /// de local é obrigatório ou recusado.
  final String explicacao;

  /// Se esta modalidade **exige** um local. O formulário lê isto em vez de comparar
  /// com `remoto` em três lugares, e o servidor aplica a mesma regra nos dois
  /// sentidos: local obrigatório aqui, recusado em `remoto`.
  bool get exigeLocal => this != Modalidade.remoto;
}

@JsonEnum(fieldRename: FieldRename.none)
enum EstadoDaVaga {
  aberta('Aberta'),
  fechada('Encerrada');

  const EstadoDaVaga(this.rotulo);

  final String rotulo;
}

/// Os dois estados de uma candidatura.
///
/// Não há `aceita` nem `recusada`: sem mensagens diretas, que não têm serviço,
/// "aceita" é um estado que não leva a lugar nenhum — o aluno ficaria esperando um
/// contato que o app não sabe entregar.
@JsonEnum(fieldRename: FieldRename.none)
enum EstadoDaCandidatura {
  enviada('Enviada', 'A empresa ainda não abriu sua candidatura'),
  visualizada('Visualizada', 'A empresa viu sua candidatura');

  const EstadoDaCandidatura(this.rotulo, this.explicacao);

  final String rotulo;

  /// O que o **aluno** lê. É a razão de o estado existir: sem algo que muda, a tela
  /// dele não tem o que dizer depois de se candidatar.
  final String explicacao;
}

/// A empresa que publicou, resolvida na leitura pelo serviço.
@freezed
abstract class EmpresaDaVaga with _$EmpresaDaVaga {
  const factory EmpresaDaVaga({
    required String id,
    required String nome,
    required String username,
    String? fotoUrl,
  }) = _EmpresaDaVaga;

  factory EmpresaDaVaga.fromJson(Map<String, dynamic> json) =>
      _$EmpresaDaVagaFromJson(json);
}

extension EmpresaDaVagaX on EmpresaDaVaga {
  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (partes.isEmpty) return '?';
    if (partes.length == 1) {
      final unico = partes.first;
      return (unico.length >= 2 ? unico.substring(0, 2) : unico).toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}

/// O que a empresa vê de quem se candidatou: **o mesmo resumo de qualquer card**.
///
/// Nem CPF, nem telefone, nem e-mail — e a garantia é o tipo não ter os campos, em
/// vez de a tela lembrar de não exibi-los. Para o resto, a empresa abre o perfil
/// público dele, onde o currículo já é público.
@freezed
abstract class CandidatoResumo with _$CandidatoResumo {
  const factory CandidatoResumo({
    required String id,
    required String nomeCompleto,
    required String username,
    String? fotoUrl,
  }) = _CandidatoResumo;

  factory CandidatoResumo.fromJson(Map<String, dynamic> json) =>
      _$CandidatoResumoFromJson(json);
}

extension CandidatoResumoX on CandidatoResumo {
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
}

/// Uma vaga.
///
/// Vaga não é post, e os dois campos que o post não tem dizem por quê: [estado] e
/// [totalDeCandidaturas]. Um post não encerra e não tem relação N:N com alunos — o
/// protótipo chamava as duas coisas de `ProfessionalPost`, e o resultado era uma
/// lista em que "candidatar-se" e "curtir" eram a mesma ação com nomes diferentes.
@freezed
abstract class Vaga with _$Vaga {
  const factory Vaga({
    required String id,
    required EmpresaDaVaga empresa,
    required String titulo,
    required String descricao,
    required TipoDeVaga tipo,
    required Modalidade modalidade,
    required EstadoDaVaga estado,
    required DateTime criadoEm,

    /// Nulo exatamente quando [modalidade] é [Modalidade.remoto].
    String? local,
    @Default(0) int totalDeCandidaturas,

    /// Estado **por leitor**. **Nulo para quem não é aluno** — uma empresa não tem
    /// o que responder aqui, e `false` a faria parecer elegível a se candidatar.
    bool? candidaturaEnviada,

    /// Se o leitor é a empresa autora. Vem do servidor: é o que decide os botões de
    /// editar e encerrar, e inferir no cliente é como um botão aparece e é recusado.
    @Default(false) bool podeEditar,
    DateTime? editadoEm,
  }) = _Vaga;

  factory Vaga.fromJson(Map<String, dynamic> json) => _$VagaFromJson(json);
}

extension VagaX on Vaga {
  bool get aberta => estado == EstadoDaVaga.aberta;
  bool get editada => editadoEm != null;

  /// Se o botão de candidatar-se deve aparecer habilitado.
  ///
  /// Três condições, e cada uma tem uma resposta diferente na tela: não é aluno (o
  /// botão não existe), já se candidatou (mostra o estado), vaga encerrada (diz
  /// isso). Um booleano só forçaria a tela a recalcular os três casos.
  bool get podeCandidatar =>
      aberta && candidaturaEnviada == false;

  /// "Remoto" ou "Híbrido · Ribeirão Preto, SP". Uma linha só, porque o card não
  /// tem espaço para duas e as duas informações se leem juntas.
  String get ondeE => local == null
      ? modalidade.rotulo
      : '${modalidade.rotulo} · $local';
}

/// Uma candidatura, com a vaga inteira dentro.
///
/// A vaga vem completa, e não só o id: a lista do aluno é de "onde me candidatei", e
/// um item sem título de vaga não é uma linha legível.
@freezed
abstract class Candidatura with _$Candidatura {
  const factory Candidatura({
    required String id,
    required Vaga vaga,
    required CandidatoResumo candidato,
    required EstadoDaCandidatura estado,
    required DateTime criadoEm,

    /// A data da **primeira** vez que a empresa abriu. Marcar de novo não a move: é
    /// o que o aluno lê como "foi vista", e uma data que andasse contaria quantas
    /// vezes olharam.
    DateTime? visualizadaEm,
  }) = _Candidatura;

  factory Candidatura.fromJson(Map<String, dynamic> json) =>
      _$CandidaturaFromJson(json);
}

extension CandidaturaX on Candidatura {
  bool get vista => estado == EstadoDaCandidatura.visualizada;
}

@freezed
abstract class PaginaDeVagas with _$PaginaDeVagas {
  const factory PaginaDeVagas({
    @Default(<Vaga>[]) List<Vaga> itens,
    String? proximoCursor,
  }) = _PaginaDeVagas;

  factory PaginaDeVagas.fromJson(Map<String, dynamic> json) =>
      _$PaginaDeVagasFromJson(json);
}

@freezed
abstract class PaginaDeCandidaturas with _$PaginaDeCandidaturas {
  const factory PaginaDeCandidaturas({
    @Default(<Candidatura>[]) List<Candidatura> itens,
    String? proximoCursor,
  }) = _PaginaDeCandidaturas;

  factory PaginaDeCandidaturas.fromJson(Map<String, dynamic> json) =>
      _$PaginaDeCandidaturasFromJson(json);
}

/// O filtro da área de vagas.
///
/// `tipo` e `modalidade` são colunas da vaga. **Não há filtro por universidade nem
/// por curso**, que o rascunho do contrato previa: ele exigiria a empresa escolher
/// cursos de instituições que ela não administra, e nenhuma tela desta sprint pede
/// isso.
@freezed
abstract class FiltroDeVagas with _$FiltroDeVagas {
  const factory FiltroDeVagas({
    TipoDeVaga? tipo,
    Modalidade? modalidade,

    /// As vagas de uma empresa — a aba de vagas do perfil dela.
    String? empresaId,

    /// Abertas por padrão. `fechada` existe para a empresa ver o que encerrou, e
    /// **não é filtro de autorização**: vaga fechada não é conteúdo restrito, só
    /// conteúdo velho.
    @Default(EstadoDaVaga.aberta) EstadoDaVaga estado,
  }) = _FiltroDeVagas;
}

extension FiltroDeVagasX on FiltroDeVagas {
  /// Se há algum filtro além do padrão. A tela usa isto para pintar o ícone de
  /// filtro — é o mesmo princípio do botão de escopo: uma lista filtrada não deve
  /// ser lida como uma lista vazia.
  bool get ativo =>
      tipo != null || modalidade != null || estado != EstadoDaVaga.aberta;
}
