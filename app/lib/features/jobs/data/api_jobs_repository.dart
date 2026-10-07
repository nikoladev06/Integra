import 'package:integra/core/network/api_client.dart';
import 'package:integra/features/jobs/data/jobs_repository.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';

/// [JobsRepository] contra o `jobs-service` real.
class ApiJobsRepository implements JobsRepository {
  ApiJobsRepository(this._api);

  final ApiClient _api;

  // ──────────────────────────────  vagas  ──────────────────────────────

  @override
  Future<PaginaDeVagas> vagas({
    FiltroDeVagas filtro = const FiltroDeVagas(),
    String? cursor,
  }) async => PaginaDeVagas.fromJson(
    await _api.get(
      '/jobs/vagas',
      query: {
        'estado': filtro.estado.name,
        if (filtro.tipo != null) 'tipo': filtro.tipo!.name,
        if (filtro.modalidade != null) 'modalidade': filtro.modalidade!.name,
        if (filtro.empresaId != null) 'empresaId': filtro.empresaId,
        if (cursor != null) 'cursor': cursor,
      },
    ),
  );

  @override
  Future<Vaga> vaga(String vagaId) async =>
      Vaga.fromJson(await _api.get('/jobs/vagas/$vagaId'));

  @override
  Future<Vaga> publicar({
    required String titulo,
    required String descricao,
    required TipoDeVaga tipo,
    required Modalidade modalidade,
    String? local,
  }) async => Vaga.fromJson(
    await _api.post(
      '/jobs/vagas',
      corpo: {
        'titulo': titulo,
        'descricao': descricao,
        'tipo': tipo.name,
        'modalidade': modalidade.name,
        // Só vai quando a modalidade exige: o serviço **recusa** `local` em
        // `remoto`, em vez de ignorá-lo. Mandar sempre renderia 422 numa vaga
        // remota, e o formulário destacaria um campo que o usuário deixou vazio
        // de propósito.
        if (modalidade.exigeLocal && local != null) 'local': local,
      },
    ),
  );

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
    // `local` acompanha a modalidade, como `cursoId` acompanha a visibilidade no
    // pilar Acadêmico: passar a `remoto` **limpa** o local no servidor, então
    // mandar o local antigo junto de `modalidade: remoto` renderia 422 — o que é a
    // resposta certa, porque o servidor não adivinha qual dos dois está errado.
    final corpo = <String, dynamic>{
      if (titulo != null) 'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      if (tipo != null) 'tipo': tipo.name,
      if (modalidade != null) 'modalidade': modalidade.name,
      if ((modalidade?.exigeLocal ?? true) && local != null) 'local': local,
      if (estado != null) 'estado': estado.name,
    };
    return Vaga.fromJson(await _api.patch('/jobs/vagas/$vagaId', corpo: corpo));
  }

  // ──────────────────────────  candidaturas  ──────────────────────────

  @override
  Future<({Candidatura candidatura, bool criada})> candidatar(
    String vagaId,
  ) async {
    // O contrato responde 201 quando cria e 200 quando já existia, e a tela usa a
    // diferença: confirma "candidatura enviada" só no primeiro caso. `postComStatus`
    // existe no [ApiClient] por causa desta rota — é a única do app em que o código
    // de sucesso carrega informação.
    final (corpo, status) = await _api.postComStatus(
      '/jobs/vagas/$vagaId/candidaturas',
    );
    return (candidatura: Candidatura.fromJson(corpo), criada: status == 201);
  }

  @override
  Future<PaginaDeCandidaturas> candidaturasDaVaga(
    String vagaId, {
    String? cursor,
  }) async => PaginaDeCandidaturas.fromJson(
    await _api.get(
      '/jobs/vagas/$vagaId/candidaturas',
      query: {if (cursor != null) 'cursor': cursor},
    ),
  );

  @override
  Future<PaginaDeCandidaturas> minhasCandidaturas({String? cursor}) async =>
      PaginaDeCandidaturas.fromJson(
        await _api.get(
          '/jobs/candidaturas/me',
          query: {if (cursor != null) 'cursor': cursor},
        ),
      );

  @override
  Future<Candidatura> marcarVisualizada(String candidaturaId) async =>
      Candidatura.fromJson(
        await _api.patch(
          '/jobs/candidaturas/$candidaturaId',
          // `visualizada` é o único valor que o contrato aceita: o estado não volta
          // atrás. Um parâmetro aqui só permitiria mandar o valor que o servidor
          // recusa.
          corpo: {'estado': 'visualizada'},
        ),
      );
}
