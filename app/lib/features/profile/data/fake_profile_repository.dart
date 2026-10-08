import 'dart:typed_data';

import 'package:integra/core/error/failure.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/models/instituicao.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/data/profile_repository.dart';
import 'package:integra/shared/domain/documentos.dart';

/// [ProfileRepository] em memória, sobre o [BancoFalso].
///
/// Reproduz as regras do `user-service` que as telas precisam tratar, não só o
/// caminho feliz: formação duplicada em 409, formação verificada que não se
/// apaga, e as **duas conferências do CPF na ordem certa** — primeiro contra a
/// conta, depois contra a lista da instituição.
///
/// Essa ordem é o que impede a escalada, e por isso está reproduzida aqui: um
/// falso que só consultasse a lista ensinaria à tela um fluxo que a API real não
/// tem, e o erro só apareceria contra o servidor.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this._banco, {Duration? latencia})
    : _latencia = latencia ?? const Duration(milliseconds: 300);

  final BancoFalso _banco;
  final Duration _latencia;

  Future<void> _esperar() => Future<void>.delayed(_latencia);

  /// O contrato omite contato e documento em toda resposta pública. O falso
  /// respeita isso, senão a tela seria escrita assumindo dados que a API real
  /// não manda.
  Perfil _publico(Perfil p) => p.copyWith(
    email: null,
    telefone: null,
    cpf: null,
    cnpj: null,
    ativadaEm: null,
    alteradoEm: null,
  );

  // ──────────────────────────────  perfil  ──────────────────────────────

  @override
  Future<Perfil> meuPerfil() async {
    await _esperar();
    return _banco.usuarioAtual;
  }

  @override
  Future<Perfil> perfilDe(String userId) async {
    await _esperar();
    final encontrado = _banco.usuarios[userId];
    if (encontrado == null) {
      throw const FalhaNaoEncontrado('Usuário não encontrado');
    }
    return _publico(encontrado);
  }

  @override
  Future<Perfil> atualizarMeuPerfil({
    String? nomeCompleto,
    String? username,
    String? telefone,
    String? bio,
    String? fotoUrl,
  }) async {
    await _esperar();

    final eu = _banco.usuarioAtual;

    if (username != null) {
      final emUso = _banco.usuarios.values.any(
        (p) => p.id != eu.id && p.username == username.toLowerCase(),
      );
      if (emUso) throw const FalhaDeConflito('Username já existe');
    }
    if (bio != null && bio.length > 280) {
      throw const FalhaDeValidacao(
        campos: {
          'bio': ['Bio deve ter no máximo 280 caracteres'],
        },
      );
    }

    final atualizado = eu.copyWith(
      nomeCompleto: nomeCompleto ?? eu.nomeCompleto,
      username: username?.toLowerCase() ?? eu.username,
      telefone: telefone ?? eu.telefone,
      bio: bio ?? eu.bio,
      fotoUrl: fotoUrl ?? eu.fotoUrl,
      alteradoEm: DateTime.now().toUtc(),
    );
    _banco.salvar(atualizado);
    return atualizado;
  }

  // ────────────────────────────  formação  ────────────────────────────

  @override
  Future<Formacao> declararFormacao({
    required String universidadeId,
    required String cursoId,
  }) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    final universidade = _banco.universidadePorId(universidadeId);
    final curso = _banco.cursoPorId(universidadeId, cursoId);

    if (universidade == null) {
      throw const FalhaNaoEncontrado('Universidade não encontrada');
    }
    if (curso == null) {
      throw const FalhaDeValidacao(
        campos: {
          'cursoId': ['Curso não pertence a esta universidade'],
        },
      );
    }

    final duplicada = eu.formacoes.any(
      (f) => f.universidade.id == universidadeId && f.curso.id == cursoId,
    );
    if (duplicada) {
      throw const FalhaDeConflito('Esta formação já consta no seu perfil');
    }

    final nova = Formacao(
      id: _banco.proximoId('form'),
      universidade: universidade,
      curso: curso,
      criadoEm: DateTime.now().toUtc(),
      // Sem selo: declarar não é ser verificado.
    );
    _banco.salvar(eu.copyWith(formacoes: [nova, ...eu.formacoes]));
    return nova;
  }

  @override
  Future<void> removerFormacao(String formacaoId) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    final alvo = eu.formacoes.where((f) => f.id == formacaoId).firstOrNull;

    if (alvo == null) {
      throw const FalhaNaoEncontrado('Formação não encontrada no seu perfil');
    }
    if (alvo.verificada) {
      throw const FalhaDeConflito(
        'Formações verificadas pela instituição não podem ser removidas',
      );
    }

    _banco.salvar(
      eu.copyWith(
        formacoes: eu.formacoes.where((f) => f.id != formacaoId).toList(),
      ),
    );
  }

  // ─────────────────────────────  vínculo  ─────────────────────────────

  @override
  Future<Vinculo?> meuVinculo() async {
    await _esperar();
    return _banco.usuarioAtual.vinculo;
  }

  @override
  Future<Vinculo> criarVinculo({
    required String universidadeId,
    required String cpf,
  }) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    final digitos = normalizarCpf(cpf);

    // Passo 1 — o CPF é o da própria conta? **É o que impede a escalada.** CPF
    // circula em vazamentos; conferir só contra a lista da faculdade
    // transformaria o número em senha de acesso aos comunicados internos dela.
    if (eu.cpf == null || eu.cpf != digitos) {
      throw const FalhaDePermissao(
        'Não encontramos esse CPF na lista desta instituição',
      );
    }

    final universidade = _banco.universidadePorId(universidadeId);
    if (universidade == null) {
      throw const FalhaNaoEncontrado('Universidade não encontrada');
    }

    // Passo 2 — esse CPF consta nas matrículas desta universidade? A recusa tem
    // a **mesma mensagem** do passo 1, para a rota não virar sonda da lista.
    final matricula = _banco.matriculaDe(universidadeId, digitos);
    if (matricula == null) {
      throw const FalhaNaoEncontrado(
        'Não encontramos esse CPF na lista desta instituição',
      );
    }

    final curso = _banco.cursoPorId(universidadeId, matricula.cursoId)!;
    final agora = DateTime.now().toUtc();

    // Um vínculo por vez: o novo substitui o anterior, e quem troca de
    // faculdade não precisa que a antiga o remova primeiro.
    final vinculo = Vinculo(
      universidade: universidade,
      curso: curso,
      criadoEm: agora,
    );

    _banco.salvar(
      eu.copyWith(
        vinculo: vinculo,
        formacoes: _comFormacaoVerificada(eu.formacoes, vinculo, agora),
      ),
    );
    return vinculo;
  }

  /// Estampa o selo na formação correspondente, criando-a se o aluno não a
  /// declarou. **Não apaga nem desmarca as anteriores**: quem trocou de
  /// faculdade fica com duas verificadas, porque estudou nas duas.
  List<Formacao> _comFormacaoVerificada(
    List<Formacao> atuais,
    Vinculo vinculo,
    DateTime quando,
  ) {
    final indice = atuais.indexWhere(
      (f) =>
          f.universidade.id == vinculo.universidade.id &&
          f.curso.id == vinculo.curso.id,
    );

    if (indice >= 0) {
      final copia = [...atuais];
      copia[indice] = copia[indice].copyWith(verificadaEm: quando);
      return copia;
    }

    return [
      Formacao(
        id: _banco.proximoId('form'),
        universidade: vinculo.universidade,
        curso: vinculo.curso,
        criadoEm: quando,
        verificadaEm: quando,
      ),
      ...atuais,
    ];
  }

  @override
  Future<void> encerrarVinculo() async {
    await _esperar();
    // A formação **segue verificada**: encerrar o vínculo não desfaz o fato de
    // ter estudado lá, e reinserir o CPF recria o vínculo.
    _banco.salvar(_banco.usuarioAtual.copyWith(vinculo: null));
  }

  // ───────────────────────────  catálogo e busca  ───────────────────────────

  @override
  Future<List<Universidade>> universidades({String? termo}) async {
    await _esperar();
    final t = termo?.trim().toLowerCase() ?? '';
    if (t.isEmpty) return List.unmodifiable(_banco.universidades);
    return _banco.universidades
        .where(
          (u) =>
              u.nome.toLowerCase().contains(t) ||
              u.sigla.toLowerCase().contains(t),
        )
        .toList();
  }

  @override
  Future<List<Curso>> cursosDe(String universidadeId) async {
    await _esperar();
    final cursos = _banco.cursos[universidadeId];
    if (cursos == null) {
      throw const FalhaNaoEncontrado('Universidade não encontrada');
    }
    return List.unmodifiable(cursos);
  }

  @override
  Future<PerfilDeUniversidade> perfilDaUniversidade(
    String universidadeId,
  ) async {
    await _esperar();

    final universidade = _banco.universidadePorId(universidadeId);
    if (universidade == null) {
      throw const FalhaNaoEncontrado('Universidade não encontrada');
    }

    final eu = _banco.usuarioAtual;
    return PerfilDeUniversidade(
      id: universidade.id,
      nome: universidade.nome,
      sigla: universidade.sigla,
      // Vínculo **com esta** instituição: ter vínculo com outra não vale.
      temVinculo: eu.vinculo?.universidade.id == universidadeId,
      seguindo:
          _banco.seguindoUniversidades[eu.id]?.contains(universidadeId) ??
          false,
    );
  }

  @override
  Future<ResultadoDeBusca> buscar(String termo) async {
    await _esperar();

    final t = termo.trim().toLowerCase();
    // Mesmo mínimo do serviço: abaixo dele a consulta nem sai, em vez de
    // devolver meia base.
    if (t.length < 2) return const ResultadoDeBusca();

    bool casa(Perfil p) =>
        p.nomeCompleto.toLowerCase().contains(t) ||
        p.username.toLowerCase().contains(t);

    return ResultadoDeBusca(
      universidades: _banco.universidades
          .where(
            (u) =>
                u.nome.toLowerCase().contains(t) ||
                u.sigla.toLowerCase().contains(t),
          )
          .take(5)
          .toList(),
      empresas: _banco.usuarios.values
          .where((p) => p.tipo == TipoConta.empresa && casa(p))
          .map(_publico)
          .take(5)
          .toList(),
      // `faculdade` não entra em "Pessoas": a conta institucional já aparece no
      // grupo de universidades, e listá-la duas vezes com nomes diferentes
      // confunde mais do que ajuda.
      pessoas: _banco.usuarios.values
          .where((p) => p.tipo == TipoConta.aluno && casa(p))
          .map(_publico)
          .take(5)
          .toList(),
    );
  }

  @override
  Future<List<Perfil>> buscarPessoas(
    String termo, {
    String? universidadeId,
    String? cursoId,
  }) async {
    await _esperar();

    final t = termo.trim().toLowerCase();
    if (t.length < 2) return const [];

    return _banco.usuarios.values
        .where(
          (p) =>
              p.tipo == TipoConta.aluno &&
              (p.nomeCompleto.toLowerCase().contains(t) ||
                  p.username.toLowerCase().contains(t)),
        )
        // O filtro é por **vínculo**, não por formação declarada: "outros alunos
        // da minha instituição" é sobre quem a faculdade confirmou, e qualquer
        // um pode declarar qualquer coisa.
        .where(
          (p) =>
              universidadeId == null ||
              p.vinculo?.universidade.id == universidadeId,
        )
        .where((p) => cursoId == null || p.vinculo?.curso.id == cursoId)
        .map(_publico)
        .toList();
  }

  // ─────────────────────────────  seguir  ─────────────────────────────

  @override
  Future<List<UniversidadeSeguida>> universidadesSeguidas() async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    final explicitas = _banco.seguindoUniversidades[eu.id] ?? const <String>{};
    final saida = <UniversidadeSeguida>[];

    UniversidadeSeguida montar(Universidade u, {required bool propria}) =>
        UniversidadeSeguida(
          id: u.id,
          nome: u.nome,
          sigla: u.sigla,
          temConta: u.temConta,
          propria: propria,
          seguidaEm: explicitas.contains(u.id) ? eu.criadoEm : null,
        );

    // A do vínculo entra sempre, mesmo sem registro: ela não é opcional
    // enquanto o vínculo existir, e deixá-la de fora faria o escopo "geral" do
    // feed excluir justamente a instituição do aluno.
    final propria = eu.vinculo?.universidade;
    if (propria != null) saida.add(montar(propria, propria: true));

    for (final id in explicitas) {
      if (id == propria?.id) continue;
      final u = _banco.universidadePorId(id);
      if (u != null) saida.add(montar(u, propria: false));
    }

    saida.sort((a, b) => a.sigla.compareTo(b.sigla));
    return saida;
  }

  @override
  Future<void> seguirUniversidade(
    String universidadeId, {
    required bool seguir,
  }) async {
    await _esperar();

    if (_banco.universidadePorId(universidadeId) == null) {
      throw const FalhaNaoEncontrado('Universidade não encontrada');
    }

    final conjunto = _banco.seguindoUniversidades.putIfAbsent(
      _banco.usuarioAtual.id,
      () => <String>{},
    );
    if (seguir) {
      conjunto.add(universidadeId);
    } else {
      conjunto.remove(universidadeId);
    }
  }

  @override
  Future<List<Perfil>> usuariosSeguidos() async {
    await _esperar();

    final ids =
        _banco.seguindoUsuarios[_banco.usuarioAtual.id] ?? const <String>{};

    return [
      for (final id in ids)
        if (_banco.usuarios[id] case final encontrado?) _publico(encontrado),
    ]..sort((a, b) => a.nomeCompleto.compareTo(b.nomeCompleto));
  }

  @override
  Future<void> seguirUsuario(String userId, {required bool seguir}) async {
    await _esperar();

    if (!_banco.usuarios.containsKey(userId)) {
      throw const FalhaNaoEncontrado('Usuário não encontrado');
    }
    if (userId == _banco.usuarioAtual.id) {
      // O 409 do serviço. A tela não oferece o botão no próprio perfil, e por isso
      // esta recusa nunca deveria aparecer — mas o falso que a omitisse deixaria a
      // tela ser escrita sem saber que ela existe.
      throw const FalhaDeConflito('Você não pode seguir a si mesmo');
    }

    final conjunto = _banco.seguindoUsuarios.putIfAbsent(
      _banco.usuarioAtual.id,
      () => <String>{},
    );
    if (seguir) {
      conjunto.add(userId);
    } else {
      conjunto.remove(userId);
    }
  }

  // ───────────────  administração da própria instituição  ───────────────

  /// A universidade da conta autenticada, exigindo `faculdade` **ativada**.
  ///
  /// As três recusas do serviço, na mesma ordem: tipo errado, conta pendente, e
  /// conta institucional sem instituição associada. A do meio é a que o falso
  /// mais precisa reproduzir — a conta de empresa das fixtures nasce pendente, e
  /// é com ela que se vê o aviso de análise na tela.
  String _minhaInstituicao() {
    final eu = _banco.usuarioAtual;

    if (eu.tipo != TipoConta.faculdade) {
      throw const FalhaDePermissao(
        'Sua conta não tem permissão para esta ação',
      );
    }
    if (eu.ativadaEm == null) {
      throw const FalhaDePermissao(
        'Sua instituição ainda está em análise. Você será avisado quando for ativada.',
      );
    }

    final universidadeId = _banco.universidadeDaConta(eu.id);
    if (universidadeId == null) {
      throw const FalhaDePermissao(
        'Esta conta não administra nenhuma instituição',
      );
    }
    return universidadeId;
  }

  @override
  Future<List<Curso>> meusCursos() async {
    await _esperar();
    return List.unmodifiable(_banco.cursos[_minhaInstituicao()] ?? const []);
  }

  @override
  Future<Curso> criarCurso(String nome) async {
    await _esperar();

    final universidadeId = _minhaInstituicao();
    final limpo = nome.trim();

    if (limpo.length < 2) {
      throw const FalhaDeValidacao(
        campos: {
          'nome': ['O nome do curso precisa ter ao menos 2 caracteres'],
        },
      );
    }

    final lista = _banco.cursos.putIfAbsent(universidadeId, () => <Curso>[]);
    // Unicidade do **par** universidade + nome, e sem diferenciar maiúsculas: o
    // mesmo curso existe em várias faculdades, mas "ADS" e "ads" na mesma seriam
    // duas entradas para a mesma coisa no combobox do aluno.
    if (lista.any((c) => c.nome.toLowerCase() == limpo.toLowerCase())) {
      throw const FalhaDeConflito(
        'Já existe um curso com este nome na instituição',
      );
    }

    final curso = Curso(id: _banco.proximoId('curso'), nome: limpo);
    lista.add(curso);
    lista.sort((a, b) => a.nome.compareTo(b.nome));
    return curso;
  }

  @override
  Future<void> removerCurso(String cursoId) async {
    await _esperar();

    final universidadeId = _minhaInstituicao();
    final lista = _banco.cursos[universidadeId] ?? const <Curso>[];

    if (!lista.any((c) => c.id == cursoId)) {
      throw const FalhaNaoEncontrado('Curso não encontrado nesta instituição');
    }

    // `ON DELETE RESTRICT` no banco, reproduzido aqui. Apagar um curso com
    // matrícula apagaria o selo de quem se formou nele — e a tela precisa
    // aprender a tratar esta recusa, não a supor que remover sempre dá certo.
    final emUso =
        _banco.matriculas.any(
          (m) => m.universidadeId == universidadeId && m.cursoId == cursoId,
        ) ||
        _banco.usuarios.values.any(
          (u) => u.formacoes.any(
            (f) => f.universidade.id == universidadeId && f.curso.id == cursoId,
          ),
        );

    if (emUso) {
      throw const FalhaDeConflito(
        'Este curso tem matrículas ou formações e não pode ser removido',
      );
    }

    _banco.cursos[universidadeId] = lista
        .where((c) => c.id != cursoId)
        .toList();
  }

  @override
  Future<List<Matricula>> minhasMatriculas({
    String? cursoId,
    String situacao = 'todas',
  }) async {
    await _esperar();

    final universidadeId = _minhaInstituicao();

    final linhas =
        _banco.matriculas
            .where((m) => m.universidadeId == universidadeId)
            .where((m) => cursoId == null || m.cursoId == cursoId)
            .map((m) => _montarMatricula(m, universidadeId))
            .where(
              (m) => switch (situacao) {
                'pendentes' => m.pendente,
                'vinculadas' => m.vinculada,
                _ => true,
              },
            )
            .toList()
          ..sort((a, b) => a.cpf.compareTo(b.cpf));

    return linhas;
  }

  Matricula _montarMatricula(MatriculaFalsa matricula, String universidadeId) {
    // O dono do CPF, **se** já existe conta com ele. Nulo é o caso comum: a
    // faculdade matricula quem ainda não baixou o app.
    final dono = _banco.usuarios.values
        .where((u) => u.cpf == matricula.cpf)
        .firstOrNull;

    // `vinculada` é sobre o vínculo **com esta** instituição. Um aluno que migrou
    // para outra faculdade continua na lista antiga, e pendente nela.
    final vinculada = dono?.vinculo?.universidade.id == universidadeId;

    return Matricula(
      id: matricula.id,
      cpf: matricula.cpf,
      curso:
          _banco.cursoPorId(universidadeId, matricula.cursoId) ??
          Curso(id: matricula.cursoId, nome: 'Curso removido'),
      vinculada: vinculada,
      usuario: dono == null ? null : _publico(dono),
      criadoEm: dono?.criadoEm ?? DateTime.now().toUtc(),
    );
  }

  @override
  Future<Matricula> criarMatricula({
    required String cpf,
    required String cursoId,
  }) async {
    await _esperar();

    final universidadeId = _minhaInstituicao();
    final digitos = normalizarCpf(cpf);

    if (!cpfEValido(digitos)) {
      throw const FalhaDeValidacao(
        campos: {
          'cpf': ['CPF inválido'],
        },
      );
    }
    if (_banco.cursoPorId(universidadeId, cursoId) == null) {
      throw const FalhaDeValidacao(
        campos: {
          'cursoId': ['Este curso não é da sua instituição'],
        },
      );
    }
    // Um CPF uma vez por instituição. Nada impede o mesmo CPF constar em várias
    // faculdades — é o aluno que só pode ter vínculo com uma por vez.
    if (_banco.matriculaDe(universidadeId, digitos) != null) {
      throw const FalhaDeConflito('Este CPF já está matriculado aqui');
    }

    final matricula = MatriculaFalsa(
      id: _banco.proximoId('matricula'),
      universidadeId: universidadeId,
      cpf: digitos,
      cursoId: cursoId,
    );
    _banco.matriculas.add(matricula);

    return _montarMatricula(matricula, universidadeId);
  }

  @override
  Future<void> removerMatricula(String matriculaId) async {
    await _esperar();

    final universidadeId = _minhaInstituicao();
    final matricula = _banco.matriculas
        .where((m) => m.id == matriculaId && m.universidadeId == universidadeId)
        .firstOrNull;

    if (matricula == null) {
      throw const FalhaNaoEncontrado('Matrícula não encontrada');
    }

    _banco.matriculas.remove(matricula);

    // Encerra o vínculo do dono daquele CPF **com esta** universidade, e mantém a
    // formação verificada: o caso comum é o aluno ter se formado, e ele realmente
    // estudou lá. Se já migrou para outra, a matrícula antiga sendo apagada não
    // derruba o vínculo novo.
    final dono = _banco.usuarios.values
        .where((u) => u.cpf == matricula.cpf)
        .firstOrNull;

    if (dono != null && dono.vinculo?.universidade.id == universidadeId) {
      _banco.salvar(dono.copyWith(vinculo: null));
    }
  }

  // ──────────────────────────  foto de perfil  ──────────────────────────

  @override
  Future<UrlDeUpload> urlDeUploadDeAvatar({
    required String contentType,
    required int tamanhoBytes,
  }) async {
    await _esperar();
    final conta = _banco.usuarioAtual;

    // As duas validacoes do servico, com as mesmas mensagens. Sem elas, escolher um
    // GIF de 20 MB pareceria funcionar no modo de fixtures e falharia contra a API.
    final extensao = _extensoesDeImagem[contentType];
    if (extensao == null) {
      throw const FalhaDeValidacao(
        campos: {
          'contentType': ['Envie uma imagem JPEG, PNG ou WebP'],
        },
      );
    }
    if (tamanhoBytes <= 0 || tamanhoBytes > _tamanhoMaximoDeImagem) {
      throw const FalhaDeValidacao(
        campos: {
          'tamanhoBytes': ['A imagem deve ter ate 5 MB'],
        },
      );
    }

    // O caminho e derivado do id de quem pede, como no servidor: o cliente nao o
    // escolhe, e por isso nao ha como sobrescrever a foto de outra pessoa.
    final chave = 'avatares/${conta.id}/${_banco.proximoId('avatar')}.$extensao';
    return UrlDeUpload(
      // Um host que nao existe, de proposito: nada e enviado no modo de fixtures, e
      // uma URL que parecesse valida convidaria alguem a tentar abri-la.
      uploadUrl: 'https://storage.invalido/$chave?assinatura=falsa',
      urlFinal: 'https://storage.invalido/$chave',
      expiraEm: DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<void> enviarAvatar(
    UrlDeUpload destino,
    Uint8List bytes, {
    required String contentType,
  }) async {
    // Nao ha storage no modo de fixtures. Responder sucesso e o certo: a tela
    // continua o fluxo e grava a `fotoUrl` no perfil, entao a troca de foto e
    // demonstravel sem MinIO — e o avatar mostra imagem quebrada, que e honesto,
    // porque o arquivo realmente nao foi a lugar nenhum.
    await _esperar();
  }

  static const _tamanhoMaximoDeImagem = 5 * 1024 * 1024;
  static const _extensoesDeImagem = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };
}
