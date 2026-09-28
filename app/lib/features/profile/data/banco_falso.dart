import 'package:integra/core/error/failure.dart';
import 'package:integra/features/academic/data/models/post.dart';
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
}
