import 'package:integra/core/error/failure.dart';
import 'package:integra/features/jobs/data/jobs_repository.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// [JobsRepository] em memória, sobre o [BancoFalso].
///
/// **As três recusas do serviço estão aqui, e são o que este falso existe para
/// reproduzir:**
///
/// 1. quem não é `aluno` não se candidata (403);
/// 2. vaga encerrada recusa candidatura nova com 409 — mas **quem já se candidatou
///    continua recebendo a própria candidatura**, porque recusar aí faria a tela dele
///    perder o item ao recarregar;
/// 3. quem não é a empresa autora recebe 404 na lista de candidaturas, e não 403 —
///    um 403 confirmaria que a vaga existe e tem candidatos.
///
/// Um falso que só entregasse o caminho feliz deixaria as três telas sem os estados
/// que elas precisam tratar, e o erro só apareceria contra o servidor.
class FakeJobsRepository implements JobsRepository {
  FakeJobsRepository(this._banco, {Duration? latencia})
    : _latencia = latencia ?? const Duration(milliseconds: 300);

  final BancoFalso _banco;
  final Duration _latencia;

  static const _porPagina = 20;

  Future<void> _esperar() => Future<void>.delayed(_latencia);

  // ──────────────────────────────  montagem  ──────────────────────────────

  /// Monta a [Vaga] resolvendo a empresa **na leitura**.
  ///
  /// Devolve nulo quando a conta não existe mais — o mesmo que o serviço faz: a vaga
  /// fica fora da resposta em vez de derrubá-la.
  Vaga? _montar(VagaFalsa vaga, Perfil leitor) {
    final empresa = _banco.usuarios[vaga.empresaId];
    if (empresa == null) return null;

    return Vaga(
      id: vaga.id,
      empresa: EmpresaDaVaga(
        id: empresa.id,
        nome: empresa.nomeCompleto,
        username: empresa.username,
        fotoUrl: empresa.fotoUrl,
      ),
      titulo: vaga.titulo,
      descricao: vaga.descricao,
      tipo: vaga.tipo,
      modalidade: vaga.modalidade,
      local: vaga.local,
      estado: vaga.estado,
      totalDeCandidaturas: _banco.totalDeCandidaturas(vaga.id),
      // **Nulo para quem não é aluno**, e não `false`: uma empresa não tem o que
      // responder aqui, e `false` a faria parecer elegível a se candidatar à própria
      // vaga. É a mesma conversão que a apresentação do serviço faz.
      candidaturaEnviada: leitor.tipo == TipoConta.aluno
          ? _banco.candidaturaDe(vaga.id, leitor.id) != null
          : null,
      podeEditar: vaga.empresaId == leitor.id,
      criadoEm: vaga.criadoEm,
      editadoEm: vaga.editadoEm,
    );
  }

  Candidatura? _montarCandidatura(CandidaturaFalsa candidatura, Perfil leitor) {
    final vaga = _banco.vagaPorId(candidatura.vagaId);
    final candidato = _banco.usuarios[candidatura.candidatoId];
    if (vaga == null || candidato == null) return null;

    final montada = _montar(vaga, leitor);
    if (montada == null) return null;

    return Candidatura(
      id: candidatura.id,
      vaga: montada,
      candidato: CandidatoResumo(
        id: candidato.id,
        nomeCompleto: candidato.nomeCompleto,
        username: candidato.username,
        fotoUrl: candidato.fotoUrl,
      ),
      estado: candidatura.estado,
      criadoEm: candidatura.criadoEm,
      visualizadaEm: candidatura.visualizadaEm,
    );
  }

  // ──────────────────────────────  vagas  ──────────────────────────────

  @override
  Future<PaginaDeVagas> vagas({
    FiltroDeVagas filtro = const FiltroDeVagas(),
    String? cursor,
  }) async {
    await _esperar();
    final leitor = _banco.usuarioAtual;

    final candidatas =
        _banco.vagas
            .where((v) => v.estado == filtro.estado)
            .where((v) => filtro.tipo == null || v.tipo == filtro.tipo)
            .where(
              (v) =>
                  filtro.modalidade == null ||
                  v.modalidade == filtro.modalidade,
            )
            .where(
              (v) => filtro.empresaId == null || v.empresaId == filtro.empresaId,
            )
            .toList()
          ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

    var inicio = 0;
    if (cursor != null) {
      final posicao = candidatas.indexWhere((v) => v.id == cursor);
      inicio = posicao == -1 ? 0 : posicao + 1;
    }

    final fatia = candidatas.skip(inicio).take(_porPagina).toList();
    final itens = <Vaga>[];
    for (final vaga in fatia) {
      final montada = _montar(vaga, leitor);
      if (montada != null) itens.add(montada);
    }

    final temMais = candidatas.length > inicio + fatia.length;
    return PaginaDeVagas(
      itens: itens,
      proximoCursor: temMais && fatia.isNotEmpty ? fatia.last.id : null,
    );
  }

  @override
  Future<Vaga> vaga(String vagaId) async {
    await _esperar();
    final leitor = _banco.usuarioAtual;
    final vaga = _banco.vagaPorId(vagaId);
    // Sem filtro por estado: **vaga encerrada é legível por id**. Esconder faria
    // "minhas candidaturas" apontar para 404.
    final montada = vaga == null ? null : _montar(vaga, leitor);
    if (montada == null) throw _naoEncontrada();
    return montada;
  }

  @override
  Future<Vaga> publicar({
    required String titulo,
    required String descricao,
    required TipoDeVaga tipo,
    required Modalidade modalidade,
    String? local,
  }) async {
    await _esperar();
    final empresa = _banco.usuarioAtual;

    if (empresa.tipo != TipoConta.empresa) {
      throw const FalhaDePermissao(
        'Sua conta não tem permissão para esta ação',
      );
    }
    if (!_banco.contaAtiva(empresa.id)) {
      throw const FalhaDePermissao(
        'Sua conta ainda está em análise. Você será avisado quando for ativada.',
      );
    }

    final limpo = local?.trim();
    _conferirLocal(modalidade, limpo?.isEmpty ?? true ? null : limpo);

    final vaga = VagaFalsa(
      id: _banco.proximoId('vaga'),
      empresaId: empresa.id,
      titulo: titulo.trim(),
      descricao: descricao.trim(),
      tipo: tipo,
      modalidade: modalidade,
      local: modalidade.exigeLocal ? limpo : null,
      criadoEm: DateTime.now(),
    );
    _banco.vagas.add(vaga);
    return _montar(vaga, empresa)!;
  }

  @override
  Future<Vaga> editar(
    String vagaId, {
    String? titulo,
    String? descricao,
    TipoDeVaga? tipo,
    Modalidade? modalidade,
    String? local,
    EstadoDaVaga? estado,
  }) async {
    await _esperar();
    final empresa = _banco.usuarioAtual;
    final vaga = _exigirDaEmpresa(vagaId, empresa.id);

    if (titulo == null &&
        descricao == null &&
        tipo == null &&
        modalidade == null &&
        local == null &&
        estado == null) {
      throw const FalhaDeValidacao(
        campos: {'_': ['Informe ao menos um campo para alterar']},
        mensagem: 'Verifique os campos destacados',
      );
    }

    final novaModalidade = modalidade ?? vaga.modalidade;
    final informado = local?.trim();

    // As invariantes da publicação continuam valendo na edição, e as duas regras são
    // as do serviço: passar a `remoto` **limpa** o local em vez de deixar um órfão, e
    // sair de `remoto` usa o que foi informado agora ou o que já estava na vaga.
    final novoLocal = novaModalidade.exigeLocal
        ? (informado != null && informado.isNotEmpty ? informado : vaga.local)
        : null;

    _conferirLocal(novaModalidade, novoLocal);

    if (titulo != null) vaga.titulo = titulo.trim();
    if (descricao != null) vaga.descricao = descricao.trim();
    if (tipo != null) vaga.tipo = tipo;
    if (estado != null) vaga.estado = estado;
    vaga.modalidade = novaModalidade;
    vaga.local = novoLocal;
    vaga.editadoEm = DateTime.now();

    return _montar(vaga, empresa)!;
  }

  /// A invariante do local, nos dois sentidos.
  ///
  /// Recusar o local sobrando, em vez de ignorá-lo, é o ponto: aceito em silêncio
  /// numa vaga remota, ele pareceria uma restrição geográfica que não existe — e o
  /// candidato descartaria a vaga por causa dela.
  void _conferirLocal(Modalidade modalidade, String? local) {
    if (!modalidade.exigeLocal) {
      if (local != null && local.isNotEmpty) {
        throw const FalhaDeValidacao(
          campos: {'local': ['Vaga remota não leva local']},
          mensagem: 'Verifique os campos destacados',
        );
      }
      return;
    }
    if (local == null || local.isEmpty) {
      throw const FalhaDeValidacao(
        campos: {'local': ['Informe a cidade da vaga']},
        mensagem: 'Verifique os campos destacados',
      );
    }
  }

  // ──────────────────────────  candidaturas  ──────────────────────────

  @override
  Future<({Candidatura candidatura, bool criada})> candidatar(
    String vagaId,
  ) async {
    await _esperar();
    final aluno = _banco.usuarioAtual;

    if (aluno.tipo != TipoConta.aluno) {
      throw const FalhaDePermissao(
        'Sua conta não tem permissão para esta ação',
      );
    }

    // A ordem das conferências é a do serviço: **vaga existe** antes de **vaga
    // aberta**. Uma vaga inexistente respondendo 409 diria que existe uma vaga
    // fechada com aquele id.
    final vaga = _banco.vagaPorId(vagaId);
    if (vaga == null) throw _naoEncontrada();

    final existente = _banco.candidaturaDe(vagaId, aluno.id);
    if (existente != null) {
      // Antes da checagem de vaga fechada, de propósito: quem já se candidatou
      // continua vendo a própria candidatura depois de a empresa encerrar o processo.
      return (candidatura: _montarCandidatura(existente, aluno)!, criada: false);
    }

    if (vaga.estado != EstadoDaVaga.aberta) {
      throw const FalhaDeConflito(
        'Esta vaga não está mais recebendo candidaturas',
      );
    }

    final candidatura = CandidaturaFalsa(
      id: _banco.proximoId('candidatura'),
      vagaId: vagaId,
      candidatoId: aluno.id,
      criadoEm: DateTime.now(),
    );
    _banco.candidaturas.add(candidatura);
    return (candidatura: _montarCandidatura(candidatura, aluno)!, criada: true);
  }

  @override
  Future<PaginaDeCandidaturas> candidaturasDaVaga(
    String vagaId, {
    String? cursor,
  }) async {
    await _esperar();
    final empresa = _banco.usuarioAtual;
    // O portão: existir **e** ser desta empresa. 404 nos dois casos.
    _exigirDaEmpresa(vagaId, empresa.id);

    // Listar **não** marca como visualizada. A transição é [marcarVisualizada], e um
    // efeito colateral aqui seria disparado pelo pre-fetch de qualquer tela.
    return _paginarCandidaturas(
      _banco.candidaturas.where((c) => c.vagaId == vagaId).toList(),
      empresa,
      cursor,
    );
  }

  @override
  Future<PaginaDeCandidaturas> minhasCandidaturas({String? cursor}) async {
    await _esperar();
    final leitor = _banco.usuarioAtual;

    // Sem checagem de tipo: uma conta `empresa` que chame isto recebe lista vazia,
    // que é a verdade — ela não se candidatou a nada. Um 403 seria dizer "você não
    // pode perguntar" sobre uma pergunta cuja resposta é "nada".
    return _paginarCandidaturas(
      _banco.candidaturas.where((c) => c.candidatoId == leitor.id).toList(),
      leitor,
      cursor,
    );
  }

  PaginaDeCandidaturas _paginarCandidaturas(
    List<CandidaturaFalsa> candidatas,
    Perfil leitor,
    String? cursor,
  ) {
    final ordenadas = candidatas.toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

    var inicio = 0;
    if (cursor != null) {
      final posicao = ordenadas.indexWhere((c) => c.id == cursor);
      inicio = posicao == -1 ? 0 : posicao + 1;
    }

    final fatia = ordenadas.skip(inicio).take(_porPagina).toList();
    final itens = <Candidatura>[];
    for (final candidatura in fatia) {
      final montada = _montarCandidatura(candidatura, leitor);
      if (montada != null) itens.add(montada);
    }

    final temMais = ordenadas.length > inicio + fatia.length;
    return PaginaDeCandidaturas(
      itens: itens,
      proximoCursor: temMais && fatia.isNotEmpty ? fatia.last.id : null,
    );
  }

  @override
  Future<Candidatura> marcarVisualizada(String candidaturaId) async {
    await _esperar();
    final empresa = _banco.usuarioAtual;

    final candidatura = _banco.candidaturaPorId(candidaturaId);
    if (candidatura == null) throw _candidaturaNaoEncontrada();

    // Autoriza pela **vaga**, e não pela candidatura: quem marca é a empresa autora,
    // que não aparece na linha da candidatura.
    final vaga = _banco.vagaPorId(candidatura.vagaId);
    if (vaga == null || vaga.empresaId != empresa.id) {
      throw _candidaturaNaoEncontrada();
    }

    // Idempotente, e **não move a data**: ela é a da primeira vez, que é o que o
    // aluno lê como "foi vista".
    if (candidatura.estado != EstadoDaCandidatura.visualizada) {
      candidatura.estado = EstadoDaCandidatura.visualizada;
      candidatura.visualizadaEm = DateTime.now();
    }

    return _montarCandidatura(candidatura, empresa)!;
  }

  // ──────────────────────────────  auxiliares  ──────────────────────────────

  /// A vaga, se existir **e** for desta empresa. Caso contrário, 404 e não 403.
  VagaFalsa _exigirDaEmpresa(String vagaId, String empresaId) {
    final vaga = _banco.vagaPorId(vagaId);
    if (vaga == null || vaga.empresaId != empresaId) throw _naoEncontrada();
    return vaga;
  }

  FalhaNaoEncontrado _naoEncontrada() =>
      const FalhaNaoEncontrado('Vaga não encontrada');

  FalhaNaoEncontrado _candidaturaNaoEncontrada() =>
      const FalhaNaoEncontrado('Candidatura não encontrada');
}
