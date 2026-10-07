import 'dart:typed_data';

import 'package:integra/core/error/failure.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/professional/data/feed_repository.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// [FeedRepository] em memória, sobre o [BancoFalso].
///
/// **O que este falso reproduz é a curadoria, e não uma matriz de permissão** — aqui
/// não existe uma. Todo post profissional é legível por qualquer conta, e um falso
/// que inventasse alcance ensinaria às telas uma regra que o servidor não tem.
///
/// O que ele precisa acertar é a outra coisa: **os dois ramos do feed e a origem de
/// cada item**. É onde o falso pode mentir de um jeito que a API não mente — se ele
/// trouxesse todo post do banco, a tela nunca mostraria a etiqueta "recomendado" e
/// ninguém descobriria que ela não funciona até rodar contra o serviço.
///
/// `_naFeed` abaixo é a tradução de `feed_service/escopo.py`, com os mesmos nomes de
/// caso. Esta é a terceira escrita de uma regra de curadoria (SQL, Python, Dart), e a
/// mitigação é a mesma que o plano registra para a visibilidade: os nomes dos casos
/// são iguais nos três arquivos.
class FakeFeedRepository implements FeedRepository {
  FakeFeedRepository(this._banco, {Duration? latencia})
    : _latencia = latencia ?? const Duration(milliseconds: 300);

  final BancoFalso _banco;
  final Duration _latencia;

  /// Mesmo limite do serviço. Uma página menor aqui esconderia o botão de "carregar
  /// mais" nos testes, e maior esconderia um bug de paginação.
  static const _porPagina = 20;

  Future<void> _esperar() => Future<void>.delayed(_latencia);

  // ────────────────────  a curadoria, e só o que ela decide  ────────────────────

  /// Se este post entra no feed deste leitor, e por qual ramo.
  ///
  /// Devolve a origem, ou nulo quando o post não entra. Um booleano mais uma segunda
  /// função para a origem deixaria as duas escritas divergirem — e o sintoma seria um
  /// item no feed com etiqueta errada, que é pior que item ausente porque parece
  /// certo.
  ///
  ///     autor == leitor                          seguindo
  ///     leitor segue o autor                     seguindo
  ///     autor com vinculo em universidade         recomendado
  ///       que o leitor tem vinculo ou segue
  ///     nenhum dos tres                          (fora do feed)
  OrigemNoFeed? _naFeed(PostProfissionalFalso post, String leitorId) {
    if (_banco.autoresSeguidos(leitorId).contains(post.autorId)) {
      return OrigemNoFeed.seguindo;
    }
    if (_banco.recomendadoPara(post, leitorId)) {
      return OrigemNoFeed.recomendado;
    }
    return null;
  }

  /// O filtro do seletor da tela. **Estreita, nunca amplia.**
  ///
  /// Aplicado depois de `_naFeed`, e a ordem é a regra: pedir
  /// [EscopoDoProfissional.empresas] não traz empresa que o leitor não segue, porque
  /// empresa não entra por recomendação. Trocar a ordem faria o escopo virar
  /// concessão — o equivalente ao `OR` que o `feed-service` recusa em SQL.
  bool _noEscopo(PostProfissionalFalso post, EscopoDoProfissional escopo) =>
      switch (escopo) {
        EscopoDoProfissional.geral => true,
        EscopoDoProfissional.empresas => post.autorTipo == TipoDeAutor.empresa,
        EscopoDoProfissional.pessoas => post.autorTipo == TipoDeAutor.aluno,
      };

  /// Monta o [PostProfissional] resolvendo o autor **na leitura**.
  ///
  /// Devolve nulo quando a conta não existe mais — o mesmo que o serviço faz: sem ela
  /// o card não tem cabeçalho, e um card sem cabeçalho não é conteúdo.
  PostProfissional? _montar(
    PostProfissionalFalso post,
    Perfil leitor, {
    OrigemNoFeed? origem,
  }) {
    final autor = _banco.usuarios[post.autorId];
    if (autor == null) return null;

    return PostProfissional(
      id: post.id,
      autor: AutorDePost(
        id: autor.id,
        nomeCompleto: autor.nomeCompleto,
        username: autor.username,
        fotoUrl: autor.fotoUrl,
        // O tipo sai do POST, e não do perfil: é coluna, porque é o que o escopo
        // filtra na consulta paginada. Ler do perfil daria o mesmo resultado hoje e
        // esconderia a razão de a coluna existir.
        tipo: post.autorTipo,
      ),
      conteudo: post.conteudo,
      imagemUrl: post.imagemUrl,
      origem: origem,
      totalDeCurtidas: post.curtidas.length,
      totalDeComentarios: _banco.totalDeComentariosProfissionais(post.id),
      curtidoPorMim: post.curtidas.contains(leitor.id),
      podeEditar: post.autorId == leitor.id,
      criadoEm: post.criadoEm,
      editadoEm: post.editadoEm,
    );
  }

  /// Uma página, do mais recente para o mais antigo, com keyset pelo id do último.
  ///
  /// O cursor do falso é o id do último item, e não a data mais o id do serviço. É a
  /// simplificação aceita: o que a tela precisa é que o cursor seja **opaco** e que
  /// paginar não repita item — as duas coisas valem aqui. Reproduzir o base64url do
  /// serviço não testaria nada que a tela faça.
  PaginaDePostsProfissionais _paginar(
    List<(PostProfissionalFalso, OrigemNoFeed?)> candidatos,
    Perfil leitor,
    String? cursor,
  ) {
    final ordenados = candidatos.toList()
      ..sort((a, b) => b.$1.criadoEm.compareTo(a.$1.criadoEm));

    var inicio = 0;
    if (cursor != null) {
      final posicao = ordenados.indexWhere((c) => c.$1.id == cursor);
      // Cursor de um post apagado no meio da rolagem: começa do topo em vez de
      // devolver vazio. Vazio faria a tela concluir que a lista acabou.
      inicio = posicao == -1 ? 0 : posicao + 1;
    }

    final fatia = ordenados.skip(inicio).take(_porPagina).toList();
    final itens = <PostProfissional>[];
    for (final (post, origem) in fatia) {
      final montado = _montar(post, leitor, origem: origem);
      if (montado != null) itens.add(montado);
    }

    final temMais = ordenados.length > inicio + fatia.length;
    return PaginaDePostsProfissionais(
      itens: itens,
      proximoCursor: temMais && fatia.isNotEmpty ? fatia.last.$1.id : null,
    );
  }

  // ──────────────────────────────  leitura  ──────────────────────────────

  @override
  Future<PaginaDePostsProfissionais> feed({
    EscopoDoProfissional escopo = EscopoDoProfissional.geral,
    String? cursor,
  }) async {
    await _esperar();
    final leitor = _banco.usuarioAtual;

    final candidatos = <(PostProfissionalFalso, OrigemNoFeed?)>[];
    for (final post in _banco.postsProfissionais) {
      final origem = _naFeed(post, leitor.id);
      if (origem == null) continue;
      if (!_noEscopo(post, escopo)) continue;
      candidatos.add((post, origem));
    }

    return _paginar(candidatos, leitor, cursor);
  }

  @override
  Future<PaginaDePostsProfissionais> postsDoUsuario(
    String userId, {
    String? cursor,
  }) async {
    await _esperar();
    final leitor = _banco.usuarioAtual;

    // Sem origem: a pergunta "por que estou vendo isto?" não se faz numa lista que a
    // pessoa pediu por nome. É o mesmo nulo que o serviço devolve aqui.
    final candidatos = _banco.postsProfissionais
        .where((p) => p.autorId == userId)
        .map((p) => (p, null as OrigemNoFeed?))
        .toList();

    return _paginar(candidatos, leitor, cursor);
  }

  @override
  Future<PostProfissional> post(String postId) async {
    await _esperar();
    final leitor = _banco.usuarioAtual;
    final post = _banco.postProfissionalPorId(postId);
    // Sem checagem de alcance, e a ausência é a regra deste pilar: 404 aqui significa
    // inexistente, e só isso.
    final montado = post == null ? null : _montar(post, leitor);
    if (montado == null) throw _naoEncontrado();
    return montado;
  }

  @override
  Future<PaginaDeComentariosProfissionais> comentarios(
    String postId, {
    String? cursor,
  }) async {
    await _esperar();
    final post = _exigirPost(postId);
    final leitor = _banco.usuarioAtual;

    // Do mais antigo para o mais novo: conversa se lê na ordem em que aconteceu.
    final ordenados = _banco.comentariosProfissionais
        .where((c) => c.postId == postId)
        .toList()
      ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

    final itens = <ComentarioProfissional>[];
    for (final comentario in ordenados) {
      final montado = _montarComentario(comentario, post, leitor);
      if (montado != null) itens.add(montado);
    }
    return PaginaDeComentariosProfissionais(itens: itens);
  }

  ComentarioProfissional? _montarComentario(
    ComentarioProfissionalFalso comentario,
    PostProfissionalFalso post,
    Perfil leitor,
  ) {
    final autor = _banco.usuarios[comentario.autorId];
    if (autor == null) return null;

    return ComentarioProfissional(
      id: comentario.id,
      postId: comentario.postId,
      autor: AutorDeComentarioProfissional(
        id: autor.id,
        nomeCompleto: autor.nomeCompleto,
        username: autor.username,
        fotoUrl: autor.fotoUrl,
      ),
      conteudo: comentario.conteudo,
      // Autor do comentário **ou autor do post** — a segunda metade é moderação, e é
      // a mesma regra que o serviço aplica para autorizar. Duas escritas produziriam
      // um botão que aparece na tela e é recusado pelo servidor.
      podeRemover:
          leitor.id == comentario.autorId || leitor.id == post.autorId,
      criadoEm: comentario.criadoEm,
    );
  }

  // ─────────────────────────────  publicação  ─────────────────────────────

  @override
  Future<PostProfissional> publicar({
    required String conteudo,
    String? imagemUrl,
  }) async {
    await _esperar();
    final autor = _banco.usuarioAtual;

    // As duas recusas do serviço, na mesma ordem: tipo de conta primeiro (pelo
    // token, sem I/O lá), ativação depois (pelo banco). Reproduzi-las aqui é o que
    // faz a tela de publicar mostrar o motivo certo em vez de descobrir no envio.
    if (autor.tipo == TipoConta.faculdade) {
      throw const FalhaDePermissao(
        'Contas de instituição publicam no pilar Acadêmico, não no Profissional',
      );
    }
    if (autor.ativadaEm == null) {
      throw const FalhaDePermissao(
        'Sua conta ainda está em análise. Você será avisado quando for ativada.',
      );
    }

    final post = PostProfissionalFalso(
      id: _banco.proximoId('post-prof'),
      autorId: autor.id,
      autorTipo: autor.tipo == TipoConta.empresa
          ? TipoDeAutor.empresa
          : TipoDeAutor.aluno,
      // O vínculo é copiado **agora**, e é o que decide a quem este post será
      // recomendado daqui para frente. Nulo em conta empresa e em aluno sem vínculo.
      autorUniversidadeId: autor.vinculo?.universidade.id,
      conteudo: conteudo.trim(),
      imagemUrl: imagemUrl,
      criadoEm: DateTime.now(),
    );
    _banco.postsProfissionais.add(post);

    // `origem` nula: quem acabou de publicar não precisa que o servidor explique por
    // que está vendo o próprio post.
    return _montar(post, autor)!;
  }

  @override
  Future<PostProfissional> editar(
    String postId, {
    String? conteudo,
    String? imagemUrl,
    bool removerImagem = false,
  }) async {
    await _esperar();
    final autor = _banco.usuarioAtual;
    final post = _exigirDoAutor(postId, autor.id);

    if (conteudo == null && imagemUrl == null && !removerImagem) {
      throw const FalhaDeValidacao(
        campos: {'_': ['Informe ao menos um campo para alterar']},
        mensagem: 'Verifique os campos destacados',
      );
    }

    if (conteudo != null) post.conteudo = conteudo.trim();
    if (removerImagem) {
      post.imagemUrl = null;
    } else if (imagemUrl != null) {
      post.imagemUrl = imagemUrl;
    }
    post.editadoEm = DateTime.now();

    return _montar(post, autor)!;
  }

  @override
  Future<void> remover(String postId) async {
    await _esperar();
    final autor = _banco.usuarioAtual;
    final post = _exigirDoAutor(postId, autor.id);

    _banco.postsProfissionais.remove(post);
    // O `CASCADE` do banco, à mão. Sem isto, comentário órfão apareceria no próximo
    // post que reaproveitasse o id — o falso reusa ids sequenciais.
    _banco.comentariosProfissionais.removeWhere((c) => c.postId == postId);
  }

  // ──────────────────────  curtidas e comentários  ──────────────────────

  @override
  Future<void> curtir(String postId, {required bool curtir}) async {
    await _esperar();
    final leitor = _banco.usuarioAtual;
    final post = _exigirPost(postId);

    // Idempotente nos dois sentidos, e de graça: `Set` não guarda duplicata, e
    // remover o que não está remove nada. É o análogo do `ON CONFLICT DO NOTHING`.
    if (curtir) {
      post.curtidas.add(leitor.id);
    } else {
      post.curtidas.remove(leitor.id);
    }
  }

  @override
  Future<ComentarioProfissional> comentar(
    String postId,
    String conteudo,
  ) async {
    await _esperar();
    final leitor = _banco.usuarioAtual;
    final post = _exigirPost(postId);

    final comentario = ComentarioProfissionalFalso(
      id: _banco.proximoId('coment-prof'),
      postId: postId,
      autorId: leitor.id,
      conteudo: conteudo.trim(),
      criadoEm: DateTime.now(),
    );
    _banco.comentariosProfissionais.add(comentario);
    return _montarComentario(comentario, post, leitor)!;
  }

  @override
  Future<void> removerComentario(String comentarioId) async {
    await _esperar();
    final leitor = _banco.usuarioAtual;

    final comentario = _banco.comentariosProfissionais
        .where((c) => c.id == comentarioId)
        .firstOrNull;
    if (comentario == null) throw _comentarioNaoEncontrado();

    final post = _exigirPost(comentario.postId);
    if (leitor.id != comentario.autorId && leitor.id != post.autorId) {
      // 404 e não 403: de outra pessoa sob post que não é seu responde igual a
      // inexistente, para a rota não confirmar que existe um comentário com aquele id.
      throw _comentarioNaoEncontrado();
    }

    _banco.comentariosProfissionais.remove(comentario);
  }

  // ──────────────────────────────  imagem  ──────────────────────────────

  @override
  Future<UrlDeUpload> urlDeUploadDeImagem({
    required String contentType,
    required int tamanhoBytes,
  }) async {
    await _esperar();
    final conta = _banco.usuarioAtual;

    // As duas validações do serviço, com as mesmas mensagens. O falso as reproduz
    // porque é o que a tela de composição mostra: sem elas, escolher um GIF de 20 MB
    // pareceria funcionar no modo de fixtures e falharia contra a API.
    final extensao = _extensoes[contentType];
    if (extensao == null) {
      throw const FalhaDeValidacao(
        campos: {'contentType': ['Envie uma imagem JPEG, PNG ou WebP']},
        mensagem: 'Verifique os campos destacados',
      );
    }
    if (tamanhoBytes <= 0 || tamanhoBytes > _tamanhoMaximo) {
      throw const FalhaDeValidacao(
        campos: {'tamanhoBytes': ['A imagem deve ter até 5 MB']},
        mensagem: 'Verifique os campos destacados',
      );
    }

    final chave = 'posts/${conta.id}/${_banco.proximoId('img')}.$extensao';
    return UrlDeUpload(
      // Um host que não existe, de propósito: nada é enviado no modo de fixtures, e
      // uma URL que parecesse válida convidaria alguém a tentar abri-la.
      uploadUrl: 'https://storage.invalido/$chave?assinatura=falsa',
      urlFinal: 'https://storage.invalido/$chave',
      expiraEm: DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<void> enviarImagem(
    UrlDeUpload destino,
    Uint8List bytes, {
    required String contentType,
  }) async {
    // Não há storage no modo de fixtures. Responder sucesso é o certo: a tela
    // continua o fluxo e grava a `imagemUrl` no post, então a composição com imagem é
    // demonstrável sem MinIO — e o card mostra uma imagem quebrada, que é honesto,
    // porque o arquivo realmente não foi a lugar nenhum.
    await _esperar();
  }

  // ──────────────────────────────  auxiliares  ──────────────────────────────

  static const _tamanhoMaximo = 5 * 1024 * 1024;
  static const _extensoes = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  PostProfissionalFalso _exigirPost(String postId) {
    final post = _banco.postProfissionalPorId(postId);
    if (post == null) throw _naoEncontrado();
    return post;
  }

  /// O post, se existir **e** for desta conta. Caso contrário, 404 e não 403.
  PostProfissionalFalso _exigirDoAutor(String postId, String autorId) {
    final post = _banco.postProfissionalPorId(postId);
    if (post == null || post.autorId != autorId) throw _naoEncontrado();
    return post;
  }

  FalhaNaoEncontrado _naoEncontrado() =>
      const FalhaNaoEncontrado('Post não encontrado');

  FalhaNaoEncontrado _comentarioNaoEncontrado() =>
      const FalhaNaoEncontrado('Comentário não encontrado');
}
