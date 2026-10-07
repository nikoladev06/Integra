import 'package:integra/core/error/failure.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';
import 'package:integra/features/profile/data/fixtures.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// Uma matrícula na lista da instituição: CPF e curso, **sem chave estrangeira
/// para usuário**.
///
/// A faculdade matricula quem ainda não tem conta, e o encontro acontece depois
/// — quando alguém informa aquele CPF no perfil dela. O banco de verdade tem a
/// mesma forma, pelo mesmo motivo.
class MatriculaFalsa {
  const MatriculaFalsa({
    required this.id,
    required this.universidadeId,
    required this.cpf,
    required this.cursoId,
  });

  /// Existe porque a tela de administração remove matrícula **por id**, como o
  /// contrato (`DELETE /universidades/me/matriculas/{id}`). Identificar pelo par
  /// universidade+CPF funcionaria, mas poria o CPF na URL — e CPF não circula em
  /// caminho de requisição, onde acaba em log de proxy.
  final String id;

  final String universidadeId;
  final String cpf;
  final String cursoId;
}

/// Um comunicado no banco falso.
///
/// Guarda os mesmos campos da tabela `academic.posts`, e **não** o `Post` já
/// montado: `instituicao` e `curso` são resolvidos na leitura, como o serviço
/// real faz. Guardar o objeto pronto faria o falso não reproduzir o efeito que
/// mais importa — renomear a instituição alcança o que já foi publicado.
class PostFalso {
  PostFalso({
    required this.id,
    required this.universidadeId,
    required this.autorId,
    required this.visibilidade,
    required this.conteudo,
    required this.criadoEm,
    this.cursoId,
    this.editadoEm,
  });

  final String id;
  final String universidadeId;
  final String autorId;
  final DateTime criadoEm;

  /// Mutáveis: a faculdade autora edita o texto e **o alcance** de um post
  /// publicado, e `editadoEm` é o que deixa a mudança visível na tela.
  ///
  /// Quem **não** é mutável diz o resto: `universidadeId` e `autorId` são finais,
  /// então nenhuma edição consegue mover o post para outra instituição.
  String conteudo;
  Visibilidade visibilidade;
  String? cursoId;
  DateTime? editadoEm;

  /// Ids de quem curtiu. Um `Set`, e não um contador: `curtidoPorMim` é estado
  /// por leitor, e com contador saber se **este** leitor curtiu exigiria guardar
  /// a lista em outro lugar de qualquer forma.
  final Set<String> curtidas = {};
}

class ComentarioFalso {
  ComentarioFalso({
    required this.id,
    required this.postId,
    required this.autorId,
    required this.conteudo,
    required this.criadoEm,
  });

  final String id;
  final String postId;
  final String autorId;
  final String conteudo;
  final DateTime criadoEm;
}

/// O estado em memória que os dois repositórios falsos compartilham.
///
/// Existe porque sem ele os falsos mentem de um jeito que a API real não mente:
/// o de autenticação cadastrava um usuário que o de perfil nunca via, e
/// Um post do feed profissional no banco falso.
///
/// Guarda os mesmos campos da tabela `feed.posts` — inclusive
/// [autorUniversidadeId], que e o vinculo do autor **no momento da publicacao**. Sem
/// ele o falso nao reproduz o efeito que mais importa neste pilar: um post e
/// `recomendado` para a comunidade da universidade em que foi escrito, e trocar de
/// faculdade depois nao o move.
class PostProfissionalFalso {
  PostProfissionalFalso({
    required this.id,
    required this.autorId,
    required this.autorTipo,
    required this.criadoEm,
    required this.conteudo,
    this.autorUniversidadeId,
    this.imagemUrl,
    this.editadoEm,
  });

  final String id;
  final String autorId;
  final TipoDeAutor autorTipo;
  final DateTime criadoEm;

  /// Nulo em post de empresa e de aluno sem vinculo — e o nulo e o que os mantem
  /// fora de `recomendado`: eles alcancam apenas quem segue o autor.
  final String? autorUniversidadeId;

  /// Mutaveis: o autor edita o texto e a imagem. Quem **nao** e mutavel diz o resto
  /// — `autorTipo` e `autorUniversidadeId` sao finais, entao nenhuma edicao move o
  /// post para outro escopo nem para a comunidade de outra universidade.
  String conteudo;
  String? imagemUrl;
  DateTime? editadoEm;

  /// Ids de quem curtiu. Um `Set`, e nao um contador, pelo mesmo motivo do
  /// [PostFalso]: `curtidoPorMim` e estado por leitor.
  final Set<String> curtidas = {};
}

class ComentarioProfissionalFalso {
  ComentarioProfissionalFalso({
    required this.id,
    required this.postId,
    required this.autorId,
    required this.conteudo,
    required this.criadoEm,
  });

  final String id;
  final String postId;
  final String autorId;
  final String conteudo;
  final DateTime criadoEm;
}

/// Uma vaga no banco falso.
///
/// `estado` e mutavel e nao ha remocao, como na tabela `jobs.vagas`: encerrar e
/// mudar o estado, e as candidaturas recebidas continuam existindo.
class VagaFalsa {
  VagaFalsa({
    required this.id,
    required this.empresaId,
    required this.criadoEm,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.modalidade,
    this.local,
    this.estado = EstadoDaVaga.aberta,
    this.editadoEm,
  });

  final String id;
  final String empresaId;
  final DateTime criadoEm;

  String titulo;
  String descricao;
  TipoDeVaga tipo;
  Modalidade modalidade;

  /// Nulo exatamente quando [modalidade] e `remoto` — a mesma invariante que o
  /// `CheckConstraint` do banco garante nos dois sentidos.
  String? local;

  EstadoDaVaga estado;
  DateTime? editadoEm;
}

class CandidaturaFalsa {
  CandidaturaFalsa({
    required this.id,
    required this.vagaId,
    required this.candidatoId,
    required this.criadoEm,
  });

  final String id;
  final String vagaId;
  final String candidatoId;
  final DateTime criadoEm;

  /// Passa a `visualizada` quando a empresa marca, e **nao volta**. A data e a da
  /// primeira vez: marcar de novo nao a move.
  EstadoDaCandidatura estado = EstadoDaCandidatura.enviada;
  DateTime? visualizadaEm;
}

/// `GET /users/me` devolvia a conta de exemplo independentemente de quem tinha
/// entrado. Cadastrar e então logar mostrava o nome de outra pessoa — e o portão
/// da sprint é exatamente "cadastro, login e edição de perfil ponta a ponta pelo
/// app".
///
/// Um objeto por `ProviderScope`: em teste, cada caso ganha o seu e nenhum vê o
/// estado que o anterior deixou.
class BancoFalso {
  BancoFalso() {
    for (final conta in Fixtures.contas) {
      usuarios[conta.id] = conta;
    }
    senhas.addAll(Fixtures.senhas);
    for (final (universidadeId, cpf, cursoId) in Fixtures.matriculas) {
      matriculas.add(
        MatriculaFalsa(
          id: proximoId('matricula'),
          universidadeId: universidadeId,
          cpf: cpf,
          cursoId: cursoId,
        ),
      );
    }
    posts.addAll(Fixtures.posts(proximoId));
    postsProfissionais.addAll(Fixtures.postsProfissionais(proximoId));
    vagas.addAll(Fixtures.vagas(proximoId));
    // Ana segue a empresa; a Carla não. É o que faz o post da empresa aparecer
    // num feed e não no outro, que é a regra "empresa nunca é recomendada"
    // visível ao trocar de conta na demo.
    seguindoUsuarios[Fixtures.perfilDemo.id] = {Fixtures.perfilEmpresaAtiva.id};
  }

  final Map<String, Perfil> usuarios = {};
  final Map<String, String> senhas = {};
  final List<MatriculaFalsa> matriculas = [];
  final List<Universidade> universidades = [...Fixtures.universidades];
  final Map<String, List<Curso>> cursos = {
    for (final entrada in Fixtures.cursosPorUniversidade.entries)
      entrada.key: [...entrada.value],
  };

  /// universidade → conta `faculdade` que a administra.
  ///
  /// No banco de verdade é a coluna `universidades.conta_id`, e a direção é a
  /// mesma: uma universidade tem no máximo uma conta. A maioria das semeadas não
  /// tem nenhuma — existe no catálogo e não publica.
  final Map<String, String> contaDaUniversidade = {
    ...Fixtures.contasInstitucionais,
  };

  final List<PostFalso> posts = [];
  final List<ComentarioFalso> comentarios = [];

  // ───────────────────────  pilar Profissional (Sprint 5)  ───────────────────────
  //
  // Mesmo objeto dos outros pilares, e isso nao e detalhe: o feed profissional
  // recomenda por universidade do vinculo, e o vinculo e o que o "inserir CPF" da
  // tela de instituicao cria. Com estados separados, recomendacao nunca funcionaria
  // no falso — e a divergencia so apareceria contra o servidor.

  final List<PostProfissionalFalso> postsProfissionais = [];
  final List<ComentarioProfissionalFalso> comentariosProfissionais = [];
  final List<VagaFalsa> vagas = [];
  final List<CandidaturaFalsa> candidaturas = [];

  /// usuário → universidades que ele segue explicitamente. A do vínculo entra
  /// na listagem sem estar aqui, como no `user-service`.
  final Map<String, Set<String>> seguindoUniversidades = {};
  final Map<String, Set<String>> seguindoUsuarios = {};

  /// Quem está autenticado. É o que faz `meuPerfil()` devolver a conta certa —
  /// o falso de autenticação escreve aqui ao entrar e limpa ao sair.
  String? usuarioAtualId;

  int _sequencia = 0;

  /// Identificador novo. Não é UUID de propósito: `user-ana` num log de
  /// desenvolvimento diz mais do que 36 caracteres de hexadecimal, e o app
  /// trata id como string opaca em todo lugar.
  String proximoId(String prefixo) => '$prefixo-${++_sequencia}';

  /// O perfil de quem está autenticado.
  ///
  /// Sem sessão lança [FalhaDeAutenticacao], e não um `StateError`: é o que a
  /// API responde (401), e é o que o controlador de sessão sabe tratar. Um erro
  /// de programação escaparia do `catch` e derrubaria a abertura do app com um
  /// token guardado que não vale mais.
  Perfil get usuarioAtual {
    final id = usuarioAtualId;
    final perfil = id == null ? null : usuarios[id];
    if (perfil == null) {
      throw const FalhaDeAutenticacao('Sessão expirada. Entre novamente.');
    }
    return perfil;
  }

  Universidade? universidadePorId(String id) =>
      universidades.where((u) => u.id == id).firstOrNull;

  Curso? cursoPorId(String universidadeId, String cursoId) =>
      (cursos[universidadeId] ?? const [])
          .where((c) => c.id == cursoId)
          .firstOrNull;

  MatriculaFalsa? matriculaDe(String universidadeId, String cpf) => matriculas
      .where((m) => m.universidadeId == universidadeId && m.cpf == cpf)
      .firstOrNull;

  void salvar(Perfil perfil) => usuarios[perfil.id] = perfil;

  // ───────────────────────  pilar Acadêmico  ───────────────────────

  PostFalso? postPorId(String postId) =>
      posts.where((p) => p.id == postId).firstOrNull;

  /// A universidade que esta conta `faculdade` administra, ou nulo.
  ///
  /// É o que o `academic-service` pede ao `user-service` antes de deixar alguém
  /// publicar — a universidade do post é a da conta autora, nunca um campo que o
  /// cliente manda.
  String? universidadeDaConta(String contaId) => contaDaUniversidade.entries
      .where((e) => e.value == contaId)
      .map((e) => e.key)
      .firstOrNull;

  /// Quem o aluno segue, mais a do vínculo, mais a que ele administra.
  ///
  /// O conjunto do escopo `geral`. As três parcelas estão aqui pelo mesmo motivo
  /// que no `user-service`: a do vínculo não é opcional enquanto o vínculo
  /// existir, e a administrada não é opcional para a conta institucional — sem
  /// ela a faculdade não veria o que acabou de publicar, porque conta
  /// institucional não tem vínculo.
  Set<String> universidadesDoEscopo(String usuarioId) {
    final vinculo = usuarios[usuarioId]?.vinculo;
    final administrada = universidadeDaConta(usuarioId);

    return {
      ...?seguindoUniversidades[usuarioId],
      if (vinculo != null) vinculo.universidade.id,
      if (administrada != null) administrada,
    };
  }

  int totalDeComentarios(String postId) =>
      comentarios.where((c) => c.postId == postId).length;

  // ───────────────────────  pilar Profissional  ───────────────────────

  PostProfissionalFalso? postProfissionalPorId(String postId) =>
      postsProfissionais.where((p) => p.id == postId).firstOrNull;

  int totalDeComentariosProfissionais(String postId) =>
      comentariosProfissionais.where((c) => c.postId == postId).length;

  /// O conjunto do feed profissional: quem o leitor segue, **mais ele mesmo**.
  ///
  /// O proprio leitor entra sempre. Sem isso, quem instala o app, publica e abre o
  /// feed ve vazio — e o pior lugar para mostrar vazio e logo depois da primeira
  /// acao do usuario. O `feed-service` tem a mesma clausula, pelo mesmo motivo.
  Set<String> autoresSeguidos(String usuarioId) => {
    usuarioId,
    ...?seguindoUsuarios[usuarioId],
  };

  /// Se um post e **recomendado** a este leitor: o autor tinha vinculo, ao publicar,
  /// numa universidade que o leitor tem vinculo ou segue.
  ///
  /// Empresa nunca e recomendada — `autorUniversidadeId` nulo nao pertence a
  /// conjunto nenhum, que e a mesma garantia que o `NULL IN (...)` da no Postgres.
  bool recomendadoPara(PostProfissionalFalso post, String leitorId) {
    final universidade = post.autorUniversidadeId;
    if (universidade == null) return false;
    return universidadesDoEscopo(leitorId).contains(universidade);
  }

  /// A conta institucional esta ativada? Conta `aluno` nasce ativada.
  ///
  /// E o que o `feed-service` e o `jobs-service` perguntam ao `user-service` antes de
  /// deixar alguem publicar. Aqui a resposta sai do mesmo mapa de usuarios, o que faz
  /// o falso recusar a empresa em analise igual ao servidor — e e essa recusa que a
  /// tela de publicar mostra como motivo.
  bool contaAtiva(String contaId) => usuarios[contaId]?.ativadaEm != null;

  // ─────────────────────────────  vagas  ─────────────────────────────

  VagaFalsa? vagaPorId(String vagaId) =>
      vagas.where((v) => v.id == vagaId).firstOrNull;

  CandidaturaFalsa? candidaturaPorId(String id) =>
      candidaturas.where((c) => c.id == id).firstOrNull;

  /// A candidatura deste aluno nesta vaga, se existir.
  ///
  /// E o que torna o `POST` idempotente: no banco de verdade a garantia e
  /// `UNIQUE (vaga, candidato)`, e aqui e esta consulta — as duas respondem a mesma
  /// pergunta, e e por isso que o falso devolve 200 em vez de criar uma segunda.
  CandidaturaFalsa? candidaturaDe(String vagaId, String candidatoId) =>
      candidaturas
          .where((c) => c.vagaId == vagaId && c.candidatoId == candidatoId)
          .firstOrNull;

  int totalDeCandidaturas(String vagaId) =>
      candidaturas.where((c) => c.vagaId == vagaId).length;
}
