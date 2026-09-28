import 'package:integra/core/error/failure.dart';
import 'package:integra/features/academic/data/academic_repository.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// [AcademicRepository] em memória, sobre o [BancoFalso].
///
/// **Reproduz a matriz de visibilidade inteira, e não o caminho feliz.** É a
/// regra central do pilar Acadêmico, e um falso que entregasse tudo ensinaria às
/// telas um mundo onde ela não existe — o erro só apareceria contra o servidor,
/// depois de a tela estar escrita.
///
/// O plano registra as duas contas que a folga de trabalhar com falsos cobra:
/// o falso ficar atrás do contrato, e o falso mentir de um jeito que a API não
/// mente. Aqui a segunda é a perigosa, e é por isso que [_podeVer] abaixo é uma
/// tradução linha a linha de `visibilidade.py`, com os mesmos nomes de caso.
class FakeAcademicRepository implements AcademicRepository {
  FakeAcademicRepository(this._banco, {Duration? latencia})
    : _latencia = latencia ?? const Duration(milliseconds: 300);

  final BancoFalso _banco;
  final Duration _latencia;

  /// Mesmo limite do serviço. Uma página menor aqui esconderia o botão de
  /// "carregar mais" nos testes, e maior esconderia um bug de paginação.
  static const _porPagina = 20;

  Future<void> _esperar() => Future<void>.delayed(_latencia);

  // ──────────────────────  a regra, e só ela decide  ──────────────────────

  /// A matriz de visibilidade. Tradução de `academic_service/visibilidade.py`.
  ///
  ///     a conta AUTORA do post           qualquer alcance   vê
  ///     vínculo ATIVO com a universidade publico            vê
  ///                                      institucional      vê
  ///                                      curso == o do      vê
  ///                                        vínculo
  ///                                      outro curso        NÃO vê
  ///     segue, sem vínculo               publico            vê
  ///                                      o resto            NÃO vê
  ///     nem segue nem tem vínculo        publico            vê
  ///                                      o resto            NÃO vê
  ///
  /// Três coisas não aparecem nesta função, e nenhuma por esquecimento:
  /// **formação declarada**, **formação verificada sem vínculo** e **seguir**.
  /// Nenhuma delas concede nada — e a primeira e a segunda são indistinguíveis
  /// daqui, porque o que a função lê é `perfil.vinculo`, não `perfil.formacoes`.
  bool _podeVer(PostFalso post, Perfil leitor) {
    // O autor alcança o que escreveu, em qualquer alcance. Conta `faculdade`
    // **não tem vínculo** — vínculo é de aluno —, então sem esta linha a
    // instituição não veria o próprio comunicado restrito.
    if (post.autorId == leitor.id) return true;

    if (post.visibilidade == Visibilidade.publico) return true;

    // Daqui para baixo tudo exige vínculo ativo com ESTA universidade. Ter
    // vínculo com outra não vale.
    final vinculo = leitor.vinculo;
    if (vinculo == null || vinculo.universidade.id != post.universidadeId) {
      return false;
    }

    if (post.visibilidade == Visibilidade.institucional) return true;

    return post.cursoId != null && vinculo.curso.id == post.cursoId;
  }

  /// Monta o [Post] resolvendo instituição e curso **na leitura**.
  ///
  /// Devolve nulo quando a universidade não existe mais — o mesmo que o serviço
  /// faz: sem ela o card não tem cabeçalho, e um card sem cabeçalho não é
  /// conteúdo.
  Post? _montar(PostFalso post, Perfil leitor) {
    final universidade = _banco.universidadePorId(post.universidadeId);
    if (universidade == null) return null;

    final cursoId = post.cursoId;
    final curso = post.visibilidade == Visibilidade.curso && cursoId != null
        ? _banco.cursoPorId(post.universidadeId, cursoId)
        : null;

    return Post(
      id: post.id,
      instituicao: InstituicaoDoPost(
        id: universidade.id,
        nome: universidade.nome,
        sigla: universidade.sigla,
      ),
      visibilidade: post.visibilidade,
      curso: curso,
      conteudo: post.conteudo,
      totalDeCurtidas: post.curtidas.length,
      totalDeComentarios: _banco.totalDeComentarios(post.id),
      curtidoPorMim: post.curtidas.contains(leitor.id),
      podeEditar: post.autorId == leitor.id,
      criadoEm: post.criadoEm,
      editadoEm: post.editadoEm,
    );
  }

  /// Uma página, do mais recente para o mais antigo.
  ///
  /// [universidades] nulo significa "sem restrição de escopo" — usado pelo
  /// detalhe de um post, nunca pelo feed.
  PaginaDePosts _pagina(
    Perfil leitor, {
    Set<String>? universidades,
    Visibilidade? visibilidade,
    String? cursor,
  }) {
    final visiveis =
        _banco.posts
            .where(
              (p) =>
                  universidades == null ||
                  universidades.contains(p.universidadeId),
            )
            // O filtro de alcance das abas entra **depois** de `_podeVer`, nunca em
            // lugar dele. Trocar a ordem não mudaria o resultado aqui, mas um `||`
            // no lugar do encadeamento transformaria o filtro em concessão.
            .where(
              (p) => visibilidade == null || p.visibilidade == visibilidade,
            )
            .where((p) => _podeVer(p, leitor))
            .toList()
          ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

    // Cursor = o id do último item entregue. No serviço ele codifica data + id em
    // base64url; aqui o id nu basta, e o formato é opaco para a tela nos dois
    // casos — ela só devolve o que recebeu.
    final inicio = cursor == null
        ? 0
        : visiveis.indexWhere((p) => p.id == cursor) + 1;

    final janela = visiveis.skip(inicio).take(_porPagina).toList();
    final temMais = visiveis.length > inicio + janela.length;

    return PaginaDePosts(
      itens: janela.map((p) => _montar(p, leitor)).whereType<Post>().toList(),
      proximoCursor: temMais && janela.isNotEmpty ? janela.last.id : null,
    );
  }

  // ──────────────────────────────  leitura  ──────────────────────────────

  @override
  Future<PaginaDePosts> feed({
    EscopoDoFeed escopo = EscopoDoFeed.geral,
    String? cursor,
  }) async {
    await _esperar();

    final eu = _banco.usuarioAtual;

    // O escopo escolhe **quais universidades** entram, nunca qual conteúdo. Em
    // `minha`, uma conta institucional cai na que administra — ela não tem
    // vínculo, e sem isto a faculdade não veria o próprio feed.
    final universidades = switch (escopo) {
      EscopoDoFeed.geral => _banco.universidadesDoEscopo(eu.id),
      EscopoDoFeed.minha => {
        ?eu.vinculo?.universidade.id,
        ?_banco.universidadeDaConta(eu.id),
      },
    };

    return _pagina(eu, universidades: universidades, cursor: cursor);
  }

  @override
  Future<PaginaDePosts> postsDaUniversidade(
    String universidadeId, {
    Visibilidade? visibilidade,
    String? cursor,
  }) async {
    await _esperar();

    if (_banco.universidadePorId(universidadeId) == null) {
      throw const FalhaNaoEncontrado('Universidade não encontrada');
    }

    // Uma universidade só, e **não** limitado ao escopo: é o caminho de quem
    // chegou pela busca, sem seguir nem ter vínculo, e que ainda assim vê os
    // públicos.
    return _pagina(
      _banco.usuarioAtual,
      universidades: {universidadeId},
      visibilidade: visibilidade,
      cursor: cursor,
    );
  }

  @override
  Future<Post> post(String postId) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    final post = _banco.postPorId(postId);

    // Inexistente e fora do alcance respondem **igual**. Distinguir os dois
    // confirmaria que existe um comunicado restrito naquele id.
    if (post == null || !_podeVer(post, eu)) throw _naoEncontrado();

    return _montar(post, eu)!;
  }

  @override
  Future<PaginaDeComentarios> comentarios(
    String postId, {
    String? cursor,
  }) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    final post = _garantirVisivel(postId, eu);

    final doPost = _banco.comentarios.where((c) => c.postId == postId).toList()
      // Do mais antigo para o mais novo: conversa se lê na ordem em que
      // aconteceu. É a ordem inversa da do feed, e de propósito.
      ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

    return PaginaDeComentarios(
      itens: doPost
          .map((c) => _montarComentario(c, post, eu))
          .whereType<Comentario>()
          .toList(),
    );
  }

  Comentario? _montarComentario(
    ComentarioFalso comentario,
    PostFalso post,
    Perfil leitor,
  ) {
    final autor = _banco.usuarios[comentario.autorId];
    if (autor == null) return null;

    return Comentario(
      id: comentario.id,
      postId: comentario.postId,
      autor: AutorDeComentario(
        id: autor.id,
        nomeCompleto: autor.nomeCompleto,
        username: autor.username,
        fotoUrl: autor.fotoUrl,
      ),
      conteudo: comentario.conteudo,
      // Autor do comentário, ou a faculdade autora do post (moderação). Sem a
      // segunda metade, a única saída da instituição seria apagar o post inteiro.
      podeRemover: leitor.id == comentario.autorId || leitor.id == post.autorId,
      criadoEm: comentario.criadoEm,
    );
  }

  // ─────────────────────────────  publicação  ─────────────────────────────

  @override
  Future<Post> publicar({
    required String conteudo,
    required Visibilidade visibilidade,
    String? cursoId,
  }) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    final universidadeId = _exigirInstituicaoAtiva(eu);
    _conferirAlcance(universidadeId, visibilidade, cursoId);

    final post = PostFalso(
      id: _banco.proximoId('post'),
      universidadeId: universidadeId,
      autorId: eu.id,
      visibilidade: visibilidade,
      cursoId: visibilidade == Visibilidade.curso ? cursoId : null,
      conteudo: conteudo.trim(),
      criadoEm: DateTime.now().toUtc(),
    );
    _banco.posts.add(post);

    return _montar(post, eu)!;
  }

  @override
  Future<Post> editar(
    String postId, {
    String? conteudo,
    Visibilidade? visibilidade,
    String? cursoId,
  }) async {
    await _esperar();

    if (conteudo == null && visibilidade == null && cursoId == null) {
      throw const FalhaDeValidacao(
        campos: {
          '_': ['Informe ao menos um campo para alterar'],
        },
      );
    }

    final eu = _banco.usuarioAtual;
    final universidadeId = _exigirInstituicaoAtiva(eu);
    final post = _banco.postPorId(postId);

    // 404 e não 403, mesmo para outra faculdade: descobrir por diferença de
    // status que existe um post de id X publicado por outra instituição é o mesmo
    // vazamento, só com outro requerente.
    if (post == null || post.autorId != eu.id) throw _naoEncontrado();

    final novoAlcance = visibilidade ?? post.visibilidade;
    // O que falta pode estar no post gravado: passar a `curso` sem informar o
    // curso é válido se o post já tinha um.
    final novoCurso = novoAlcance == Visibilidade.curso
        ? (cursoId ?? post.cursoId)
        : cursoId;

    _conferirAlcance(universidadeId, novoAlcance, novoCurso);

    if (conteudo != null) post.conteudo = conteudo.trim();
    post.visibilidade = novoAlcance;
    // Sair de `curso` limpa a restrição, em vez de deixar uma órfã no registro.
    post.cursoId = novoAlcance == Visibilidade.curso ? novoCurso : null;
    post.editadoEm = DateTime.now().toUtc();

    return _montar(post, eu)!;
  }

  @override
  Future<void> remover(String postId) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    _exigirInstituicaoAtiva(eu);

    final post = _banco.postPorId(postId);
    if (post == null || post.autorId != eu.id) throw _naoEncontrado();

    _banco.posts.remove(post);
    // O `ON DELETE CASCADE` do banco, à mão: comentário órfão continuaria
    // aparecendo na contagem de outro post por coincidência de id.
    _banco.comentarios.removeWhere((c) => c.postId == postId);
  }

  // ──────────────────────  curtidas e comentários  ──────────────────────

  @override
  Future<void> curtir(String postId, {required bool curtir}) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    // Curtir exige **poder ver**: sem isso a contagem de um post restrito seria
    // alterável por quem não pode lê-lo.
    final post = _garantirVisivel(postId, eu);

    // Idempotente pelo `Set`, como pela chave composta no banco: curtir duas
    // vezes não acumula.
    if (curtir) {
      post.curtidas.add(eu.id);
    } else {
      post.curtidas.remove(eu.id);
    }
  }

  @override
  Future<Comentario> comentar(String postId, String conteudo) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    final post = _garantirVisivel(postId, eu);

    final texto = conteudo.trim();
    if (texto.isEmpty) {
      throw const FalhaDeValidacao(
        campos: {
          'conteudo': ['Escreva algo antes de enviar'],
        },
      );
    }

    final comentario = ComentarioFalso(
      id: _banco.proximoId('coment'),
      postId: postId,
      autorId: eu.id,
      conteudo: texto,
      criadoEm: DateTime.now().toUtc(),
    );
    _banco.comentarios.add(comentario);

    return _montarComentario(comentario, post, eu)!;
  }

  @override
  Future<void> removerComentario(String comentarioId) async {
    await _esperar();

    final eu = _banco.usuarioAtual;
    final comentario = _banco.comentarios
        .where((c) => c.id == comentarioId)
        .firstOrNull;

    if (comentario == null) throw _comentarioNaoEncontrado();

    // Visibilidade **antes** de propriedade, na mesma ordem das duas conferências
    // do CPF: quem não alcança o post não deve descobrir, por diferença de
    // resposta, que existe um comentário com aquele id.
    final post = _garantirVisivel(comentario.postId, eu);

    if (eu.id != comentario.autorId && eu.id != post.autorId) {
      throw _comentarioNaoEncontrado();
    }

    _banco.comentarios.remove(comentario);
  }

  // ──────────────────────────────  portões  ──────────────────────────────

  /// O post, se existir e se o leitor o alcançar. É o portão de curtir, comentar
  /// e listar comentários — os três, e não só a leitura.
  ///
  /// Checar visibilidade na leitura e esquecer na escrita é o erro clássico deste
  /// desenho. Com uma função só, nenhum caminho consegue o post sem passar aqui.
  PostFalso _garantirVisivel(String postId, Perfil leitor) {
    final post = _banco.postPorId(postId);
    if (post == null || !_podeVer(post, leitor)) throw _naoEncontrado();
    return post;
  }

  /// Conta `faculdade`, ativada, e que administra uma universidade.
  ///
  /// Devolve o id da universidade porque é o que quem publica precisa — a
  /// universidade do post é a da conta autora, nunca um campo que a tela manda.
  String _exigirInstituicaoAtiva(Perfil eu) {
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

  /// `cursoId` combina com o alcance, **nos dois sentidos**.
  ///
  /// Recusar o curso sobrando, em vez de ignorá-lo, é o ponto: aceito em silêncio
  /// num post institucional, ele pareceria uma restrição que não existe.
  void _conferirAlcance(
    String universidadeId,
    Visibilidade visibilidade,
    String? cursoId,
  ) {
    if (visibilidade != Visibilidade.curso) {
      if (cursoId != null) {
        throw const FalhaDeValidacao(
          campos: {
            'cursoId': ['Só posts restritos a curso levam um curso'],
          },
        );
      }
      return;
    }

    if (cursoId == null) {
      throw const FalhaDeValidacao(
        campos: {
          'cursoId': ['Escolha o curso a que o post fica restrito'],
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
  }

  FalhaNaoEncontrado _naoEncontrado() =>
      const FalhaNaoEncontrado('Post não encontrado');

  FalhaNaoEncontrado _comentarioNaoEncontrado() =>
      const FalhaNaoEncontrado('Comentário não encontrado');
}
