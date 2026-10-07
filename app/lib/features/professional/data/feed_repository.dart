import 'dart:typed_data';

import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';

/// Contrato do pilar Profissional, espelhando `contracts/feed.openapi.yaml` v1.
///
/// **Nenhum método recebe filtro de permissão, e aqui isso é trivial:** não existe
/// permissão de leitura neste pilar. Todo post profissional é legível por qualquer
/// conta autenticada, e o serviço nunca responde 404 por alcance.
///
/// O que existe é [EscopoDoProfissional], que é outra coisa: **curadoria**. Ele
/// escolhe que tipo de conta aparece por padrão numa lista que ninguém pediu item
/// por item, e estreita o conjunto — nunca amplia. Pedir
/// [EscopoDoProfissional.empresas] não traz empresa que o leitor não segue.
abstract interface class FeedRepository {
  // ──────────────────────────────  leitura  ──────────────────────────────

  /// `GET /feed/posts`. Uma página do feed, do mais recente para o mais antigo.
  ///
  /// O conjunto é a união de quem o leitor segue (mais ele mesmo) e dos alunos com
  /// vínculo numa universidade que ele tem vínculo ou segue. Lista vazia é estado
  /// normal: é o de quem ainda não seguiu ninguém nem informou o CPF.
  Future<PaginaDePostsProfissionais> feed({
    EscopoDoProfissional escopo = EscopoDoProfissional.geral,
    String? cursor,
  });

  /// `GET /feed/usuarios/{id}/posts`. A aba "publicações" de um perfil.
  ///
  /// Separada do feed porque o feed é limitado ao conjunto do leitor, e quem abriu
  /// um perfil pela busca não está nele. Sem escopo e sem origem: a pergunta "por
  /// que estou vendo isto?" não se faz numa lista que a pessoa pediu por nome.
  Future<PaginaDePostsProfissionais> postsDoUsuario(
    String userId, {
    String? cursor,
  });

  /// `GET /feed/posts/{id}`. 404 aqui significa inexistente, e só isso.
  Future<PostProfissional> post(String postId);

  /// `GET /feed/posts/{id}/comentarios`. Do mais antigo para o mais novo.
  Future<PaginaDeComentariosProfissionais> comentarios(
    String postId, {
    String? cursor,
  });

  // ─────────────────────────────  publicação  ─────────────────────────────

  /// `POST /feed/posts`. Qualquer conta autenticada, **menos `faculdade`**.
  ///
  /// Conta institucional pendente é recusada com `conta_pendente`: consultar o CNPJ
  /// público de uma empresa não pode bastar para publicar no nome dela.
  ///
  /// [imagemUrl] é a URL devolvida por [urlDeUploadDeImagem] depois de o `PUT` ter
  /// sucesso. O serviço não confere que o arquivo chegou — uma imagem pedida e não
  /// enviada vira um card com imagem quebrada, e não um post recusado.
  Future<PostProfissional> publicar({required String conteudo, String? imagemUrl});

  /// `PATCH /feed/posts/{id}`. Só o autor.
  ///
  /// [removerImagem] é o que distingue "não mencionei a imagem" de "tire a imagem":
  /// um `String? imagemUrl` nulo diria as duas coisas, e a segunda ficaria
  /// impossível de expressar. No corpo, `true` vira `imagemUrl: null` explícito.
  Future<PostProfissional> editar(
    String postId, {
    String? conteudo,
    String? imagemUrl,
    bool removerImagem = false,
  });

  /// `DELETE /feed/posts/{id}`. Leva curtidas e comentários junto.
  ///
  /// A imagem no storage **fica**: apagá-la acoplaria a remoção de um post à
  /// disponibilidade do storage, e um `DELETE` que falha porque o storage caiu deixa
  /// o usuário sem conseguir apagar o próprio post.
  Future<void> remover(String postId);

  // ──────────────────────  curtidas e comentários  ──────────────────────

  /// `PUT`/`DELETE /feed/posts/{id}/curtidas`. Idempotente nos dois sentidos.
  Future<void> curtir(String postId, {required bool curtir});

  /// `POST /feed/posts/{id}/comentarios`.
  Future<ComentarioProfissional> comentar(String postId, String conteudo);

  /// `DELETE /feed/comentarios/{id}`. Autor do comentário, ou autor do post.
  Future<void> removerComentario(String comentarioId);

  // ──────────────────────────────  imagem  ──────────────────────────────

  /// `POST /feed/posts/imagem/upload-url`. Pede a URL assinada.
  ///
  /// O caminho do objeto é escolhido pelo servidor a partir do id de quem pede — o
  /// cliente não o informa, e por isso não há como sobrescrever a imagem de outra
  /// pessoa.
  Future<UrlDeUpload> urlDeUploadDeImagem({
    required String contentType,
    required int tamanhoBytes,
  });

  /// O `PUT` dos bytes na URL assinada. **Não passa pelo `feed-service`.**
  ///
  /// Fica no repositório, e não numa tela, por um motivo de contrato: o `PUT` tem
  /// que levar exatamente o `Content-Type` e o `Content-Length` declarados ao pedir
  /// a URL, porque os dois entram na assinatura. Deixar isso a cargo da tela é como
  /// um envio acabaria com `Content-Type` errado e um 403 do storage que ninguém
  /// sabe ler.
  Future<void> enviarImagem(
    UrlDeUpload destino,
    Uint8List bytes, {
    required String contentType,
  });
}
