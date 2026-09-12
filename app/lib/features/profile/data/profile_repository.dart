import 'package:integra/core/error/failure.dart';
import 'package:integra/features/profile/data/fixtures.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// Contrato de perfil e vínculo institucional, espelhando
/// `contracts/user.openapi.yaml`.
abstract interface class ProfileRepository {
  /// `GET /users/me`. Vem com `email` e `telefone` preenchidos.
  Future<Perfil> meuPerfil();

  /// `GET /users/{id}`. Perfil público — sem dados de contato.
  Future<Perfil> perfilDe(String userId);

  /// `PATCH /users/me`. Envie só o que mudou.
  Future<Perfil> atualizarMeuPerfil({
    String? nomeCompleto,
    String? username,
    String? telefone,
    String? bio,
    String? universidadeId,
    String? cursoId,
  });

  /// `GET /users?q=`. Busca por username ou nome.
  ///
  /// `universidadeId` é o filtro que sustenta "ver outros alunos da mesma
  /// instituição", do pilar Acadêmico.
  Future<List<Perfil>> buscar(String termo, {String? universidadeId});

  /// `GET /universidades`. Sem autenticação — alimenta o cadastro.
  Future<List<Universidade>> universidades();

  /// `GET /universidades/{id}/cursos`.
  Future<List<Curso>> cursosDe(String universidadeId);
}

/// Implementação em memória, sobre as [Fixtures].
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({Duration? latencia})
    : _latencia = latencia ?? const Duration(milliseconds: 300);

  final Duration _latencia;

  late Perfil _meuPerfil = Fixtures.perfilDemo;

  Future<void> _esperar() => Future<void>.delayed(_latencia);

  List<Perfil> get _todos => [_meuPerfil, ...Fixtures.outrosAlunos];

  @override
  Future<Perfil> meuPerfil() async {
    await _esperar();
    return _meuPerfil;
  }

  @override
  Future<Perfil> perfilDe(String userId) async {
    await _esperar();
    final encontrado = _todos.where((p) => p.id == userId).firstOrNull;
    if (encontrado == null) {
      throw const FalhaNaoEncontrado('Usuário não encontrado');
    }
    // O contrato omite contato no perfil público. O falso respeita isso, senão
    // a tela seria escrita assumindo dados que a API real não vai mandar.
    return encontrado.copyWith(email: null, telefone: null);
  }

  @override
  Future<Perfil> atualizarMeuPerfil({
    String? nomeCompleto,
    String? username,
    String? telefone,
    String? bio,
    String? universidadeId,
    String? cursoId,
  }) async {
    await _esperar();

    if (username != null) {
      final emUso = Fixtures.outrosAlunos.any(
        (p) => p.username == username.toLowerCase(),
      );
      if (emUso) throw const FalhaDeConflito('Username já existe');
    }

    var afiliacao = _meuPerfil.afiliacao;
    if (universidadeId != null) {
      final uni = Fixtures.universidades
          .where((u) => u.id == universidadeId)
          .firstOrNull;
      if (uni == null) {
        throw const FalhaDeValidacao(
          campos: {'universidadeId': ['Universidade é obrigatória']},
        );
      }
      afiliacao = afiliacao.copyWith(universidade: uni);
    }
    if (cursoId != null) {
      final cursos =
          Fixtures.cursosPorUniversidade[afiliacao.universidade.id] ?? const [];
      final curso = cursos.where((c) => c.id == cursoId).firstOrNull;
      // O contrato exige que o curso pertença à universidade vigente. Sem esta
      // checagem o falso aceitaria um par inválido que a API real recusa.
      if (curso == null) {
        throw const FalhaDeValidacao(
          campos: {'cursoId': ['Curso é obrigatório']},
        );
      }
      afiliacao = afiliacao.copyWith(curso: curso);
    }

    _meuPerfil = _meuPerfil.copyWith(
      nomeCompleto: nomeCompleto ?? _meuPerfil.nomeCompleto,
      username: username?.toLowerCase() ?? _meuPerfil.username,
      telefone: telefone ?? _meuPerfil.telefone,
      bio: bio ?? _meuPerfil.bio,
      afiliacao: afiliacao,
      alteradoEm: DateTime.now().toUtc(),
    );
    return _meuPerfil;
  }

  @override
  Future<List<Perfil>> buscar(String termo, {String? universidadeId}) async {
    await _esperar();
    if (termo.trim().length < 2) return const [];

    final t = termo.toLowerCase();
    return _todos
        .where(
          (p) =>
              p.username.toLowerCase().contains(t) ||
              p.nomeCompleto.toLowerCase().contains(t),
        )
        .where(
          (p) =>
              universidadeId == null ||
              p.afiliacao.universidade.id == universidadeId,
        )
        .map((p) => p.copyWith(email: null, telefone: null))
        .toList();
  }

  @override
  Future<List<Universidade>> universidades() async {
    await _esperar();
    return Fixtures.universidades;
  }

  @override
  Future<List<Curso>> cursosDe(String universidadeId) async {
    await _esperar();
    final cursos = Fixtures.cursosPorUniversidade[universidadeId];
    if (cursos == null) {
      throw const FalhaNaoEncontrado('Universidade não encontrada');
    }
    return cursos;
  }
}
