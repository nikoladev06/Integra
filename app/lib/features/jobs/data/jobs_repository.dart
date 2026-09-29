import 'package:integra/features/jobs/data/models/vaga.dart';

/// Contrato da área de vagas, espelhando `contracts/jobs.openapi.yaml` v1.
///
/// Duas assimetrias atravessam a interface, e as duas são deliberadas:
///
/// **Leitura é aberta; escrita é da empresa autora.** Qualquer conta lê qualquer
/// vaga, inclusive encerrada — quem se candidatou precisa poder abrir a vaga que
/// aparece em "minhas candidaturas". Editar, encerrar e ver candidaturas são da
/// autora.
///
/// **Não existe `remover`.** Encerrar é [editar] com [EstadoDaVaga.fechada]: as
/// candidaturas recebidas continuam existindo, e os dois lados continuam vendo o
/// histórico. Um `DELETE` que as levasse junto apagaria o histórico de todos para
/// encerrar um processo que terminou normal — e é por isso que o método não está
/// aqui, em vez de existir e ser evitado pelas telas.
abstract interface class JobsRepository {
  // ──────────────────────────────  vagas  ──────────────────────────────

  /// `GET /jobs/vagas`. Abertas por padrão, da mais recente para a mais antiga.
  ///
  /// `candidaturaEnviada` vem preenchido em cada item, para o botão da lista já
  /// nascer no estado certo — sem ele a tela mostraria "candidatar-se" em vagas a
  /// que o aluno já se candidatou, e descobriria o contrário só no toque.
  Future<PaginaDeVagas> vagas({
    FiltroDeVagas filtro = const FiltroDeVagas(),
    String? cursor,
  });

  /// `GET /jobs/vagas/{id}`. Legível por qualquer conta, **inclusive fechada**.
  Future<Vaga> vaga(String vagaId);

  /// `POST /jobs/vagas`. Só conta `empresa` **ativada**.
  ///
  /// A empresa **não** é parâmetro: é a conta autenticada. [local] é obrigatório
  /// fora de [Modalidade.remoto] e **recusado** em `remoto` — aceito em silêncio
  /// numa vaga remota, ele pareceria uma restrição geográfica que não existe.
  Future<Vaga> publicar({
    required String titulo,
    required String descricao,
    required TipoDeVaga tipo,
    required Modalidade modalidade,
    String? local,
  });

  /// `PATCH /jobs/vagas/{id}`. Só a empresa autora; encerrar é `estado: fechada`.
  ///
  /// As invariantes da publicação continuam valendo: passar a `remoto` **limpa** o
  /// local, e sair de `remoto` exige um — informado agora ou já presente na vaga.
  Future<Vaga> editar(
    String vagaId, {
    String? titulo,
    String? descricao,
    TipoDeVaga? tipo,
    Modalidade? modalidade,
    String? local,
    EstadoDaVaga? estado,
  });

  // ──────────────────────────  candidaturas  ──────────────────────────

  /// `POST /jobs/vagas/{id}/candidaturas`. Só conta `aluno`, e idempotente.
  ///
  /// Devolve `(candidatura, criada)`. O booleano é o 201 vs 200 do contrato, e a
  /// diferença não é cosmética: a tela confirma "candidatura enviada" quando criou e
  /// fica calada quando já existia, porque avisar duas vezes faz o usuário achar que
  /// se candidatou duas vezes.
  ///
  /// Vaga encerrada lança [FalhaDeConflito] (409) — a tela diz que a vaga encerrou,
  /// em vez de pedir uma correção que não existe.
  Future<({Candidatura candidatura, bool criada})> candidatar(String vagaId);

  /// `GET /jobs/vagas/{id}/candidaturas`. **Só a empresa autora da vaga.**
  ///
  /// Qualquer outra conta recebe 404, e não 403: um 403 confirmaria que existe uma
  /// vaga com aquele id e que ela tem candidatos.
  ///
  /// **Listar não marca como visualizada** — a transição é [marcarVisualizada].
  Future<PaginaDeCandidaturas> candidaturasDaVaga(
    String vagaId, {
    String? cursor,
  });

  /// `GET /jobs/candidaturas/me`. As do aluno autenticado.
  ///
  /// Não há parâmetro de candidato: o id sai do token, e é o que torna impossível
  /// pedir as candidaturas de outra pessoa.
  Future<PaginaDeCandidaturas> minhasCandidaturas({String? cursor});

  /// `PATCH /jobs/candidaturas/{id}`. Só a empresa autora da vaga.
  ///
  /// O único estado que alguém transiciona, e num sentido só. Marcar de novo é
  /// idempotente e não move `visualizadaEm`.
  Future<Candidatura> marcarVisualizada(String candidaturaId);
}
