import 'package:integra/core/error/failure.dart';
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
    required this.universidadeId,
    required this.cpf,
    required this.cursoId,
  });

  final String universidadeId;
  final String cpf;
  final String cursoId;
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
          universidadeId: universidadeId,
          cpf: cpf,
          cursoId: cursoId,
        ),
      );
    }
  }

  final Map<String, Perfil> usuarios = {};
  final Map<String, String> senhas = {};
  final List<MatriculaFalsa> matriculas = [];
  final List<Universidade> universidades = [...Fixtures.universidades];
  final Map<String, List<Curso>> cursos = {
    for (final entrada in Fixtures.cursosPorUniversidade.entries)
      entrada.key: [...entrada.value],
  };

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

  int totalDeAlunos(String universidadeId) => usuarios.values
      .where((u) => u.vinculo?.universidade.id == universidadeId)
      .length;

  void salvar(Perfil perfil) => usuarios[perfil.id] = perfil;
}
