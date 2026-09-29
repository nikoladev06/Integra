import 'dart:typed_data';

import 'package:integra/features/profile/data/models/instituicao.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// Contrato de perfil, formação, vínculo e busca, espelhando
/// `contracts/user.openapi.yaml` v2.
///
/// A divisão em três blocos abaixo não é cosmética: ela repete a distinção que a
/// v2 introduziu. **Formação é currículo, vínculo é acesso**, e seguir não é
/// nenhum dos dois. Métodos misturados foi como a v1 acabou com uma `afiliacao`
/// que fazia as três coisas ao mesmo tempo.
abstract interface class ProfileRepository {
  // ──────────────────────────────  perfil  ──────────────────────────────

  /// `GET /users/me`. Vem com e-mail, telefone, CPF ou CNPJ e `ativadaEm`.
  Future<Perfil> meuPerfil();

  /// `GET /users/{id}`. Perfil público — sem contato e **sem documento**.
  Future<Perfil> perfilDe(String userId);

  /// `PATCH /users/me`. Envie só o que mudou.
  ///
  /// Não aceita e-mail nem CPF: o e-mail é credencial e pertence ao
  /// `auth-service`; o CPF é a chave que liga a conta às matrículas, e
  /// deixá-lo editável permitiria assumir a matrícula de outra pessoa.
  Future<Perfil> atualizarMeuPerfil({
    String? nomeCompleto,
    String? username,
    String? telefone,
    String? bio,

    /// A URL devolvida por [urlDeUploadDeAvatar], gravada **depois** de o `PUT` ter
    /// sucesso. É o terceiro passo do fluxo de foto, separado de propósito: gravar
    /// antes do envio apontaria o perfil para um objeto que talvez nunca chegue, e a
    /// foto quebraria para todo mundo que abrisse o perfil.
    String? fotoUrl,
  });

  // ────────────────────  formação declarada (currículo)  ────────────────────

  /// `POST /users/me/formacoes`. Nasce **sem selo** e não concede nada.
  Future<Formacao> declararFormacao({
    required String universidadeId,
    required String cursoId,
  });

  /// `DELETE /users/me/formacoes/{id}`.
  ///
  /// Só remove as **não verificadas**: o selo é afirmação da instituição, não do
  /// usuário, e deixá-lo apagável pelo perfil transformaria "verificado" em algo
  /// que o próprio interessado controla. Para sair da instituição existe
  /// [encerrarVinculo], que é outra coisa — e preserva o selo.
  Future<void> removerFormacao(String formacaoId);

  // ────────────────────────  vínculo (o que concede)  ────────────────────────

  /// `GET /users/me/vinculo`. Nulo é o estado normal de quem acabou de entrar.
  Future<Vinculo?> meuVinculo();

  /// `POST /universidades/{id}/vinculo` — o "inserir CPF" do menu.
  ///
  /// O serviço confere o CPF **contra o da própria conta antes** de procurá-lo
  /// na lista da instituição. CPF não é segredo no Brasil; sem essa primeira
  /// conferência, saber o CPF de um aluno daria acesso aos comunicados internos
  /// da faculdade dele. As duas recusas têm a mesma mensagem, para a rota não
  /// virar sonda da lista de matrículas.
  Future<Vinculo> criarVinculo({
    required String universidadeId,
    required String cpf,
  });

  /// `DELETE /users/me/vinculo`. Idempotente, e **a formação segue verificada**.
  Future<void> encerrarVinculo();

  // ───────────────────────────  catálogo e busca  ───────────────────────────

  /// `GET /universidades`. Sem autenticação — alimenta o cadastro.
  Future<List<Universidade>> universidades({String? termo});

  /// `GET /universidades/{id}/cursos`. Os que a própria instituição cadastrou.
  Future<List<Curso>> cursosDe(String universidadeId);

  /// `GET /universidades/{id}`. A tela que o aluno alcança pela busca.
  Future<PerfilDeUniversidade> perfilDaUniversidade(String universidadeId);

  /// `GET /busca`. A busca do cabeçalho, agrupada por tipo.
  Future<ResultadoDeBusca> buscar(String termo);

  /// `GET /users?q=`. Só pessoas, com o filtro que sustenta "ver outros alunos
  /// da mesma instituição", do pilar Acadêmico.
  Future<List<Perfil>> buscarPessoas(
    String termo, {
    String? universidadeId,
    String? cursoId,
  });

  // ─────────────────────────────  seguir  ─────────────────────────────

  /// `GET /users/me/seguindo/universidades`. Inclui a do vínculo ativo, que
  /// entra mesmo sem o usuário ter clicado em seguir.
  Future<List<UniversidadeSeguida>> universidadesSeguidas();

  /// `PUT`/`DELETE /users/me/seguindo/universidades/{id}`.
  Future<void> seguirUniversidade(
    String universidadeId, {
    required bool seguir,
  });

  // ───────────────  administração da própria instituição  ───────────────
  //
  // Só conta `faculdade`, e as de escrita exigem também que ela esteja
  // **ativada**. Todas operam sobre a instituição da conta autenticada — daí o
  // `me` no caminho, e não um id de universidade: aceitar o id do cliente
  // deixaria uma faculdade matricular alunos no nome de outra.
  //
  // É o que faz o vínculo poder nascer sem passar pelo seed, e por isso estas
  // telas eram a herança da Sprint 3 mais urgente do pilar Acadêmico.

  /// `GET /universidades/me/cursos`. Os que a própria instituição cadastrou.
  Future<List<Curso>> meusCursos();

  /// `POST /universidades/me/cursos`. Nome duplicado na mesma instituição é 409.
  Future<Curso> criarCurso(String nome);

  /// `DELETE /universidades/me/cursos/{id}`.
  ///
  /// Recusado quando há matrícula, formação ou vínculo apontando para o curso: no
  /// banco as chaves são `ON DELETE RESTRICT`, porque apagar o curso apagaria o
  /// selo de quem se formou nele.
  Future<void> removerCurso(String cursoId);

  /// `GET /universidades/me/matriculas`.
  ///
  /// [situacao] é `todas`, `pendentes` (CPF cadastrado e ninguém reivindicou) ou
  /// `vinculadas`. É o filtro que responde a pergunta da secretaria: quem ainda
  /// não entrou no app?
  Future<List<Matricula>> minhasMatriculas({
    String? cursoId,
    String situacao = 'todas',
  });

  /// `POST /universidades/me/matriculas`. **Pode ser antes de a conta existir.**
  Future<Matricula> criarMatricula({
    required String cpf,
    required String cursoId,
  });

  /// `DELETE /universidades/me/matriculas/{id}`.
  ///
  /// Encerra o vínculo de quem tinha aquele CPF, e **a formação segue
  /// verificada** — o caso comum é o aluno ter se formado, e ele realmente
  /// estudou lá.
  Future<void> removerMatricula(String matriculaId);

  // ──────────────────────────  foto de perfil  ──────────────────────────
  //
  // O fluxo tem três passos e o serviço participa de um: ele assina a URL, o
  // cliente faz `PUT` do arquivo direto no storage, e então grava a `fotoUrl` com
  // [atualizarPerfil]. **Bytes de imagem nunca atravessam o user-service.**
  //
  // Os três passos são separados de propósito, em vez de um `trocarFoto(bytes)`
  // que fizesse tudo: se o `PUT` falhar, o perfil **não** deve ter sido alterado.
  // Um método único teria que decidir sozinho se grava antes (e a foto quebra para
  // todos) ou depois (e aí são três passos de novo, só escondidos).

  /// `POST /users/me/avatar/upload-url`.
  ///
  /// O caminho do objeto é escolhido pelo servidor a partir do id de quem pede — o
  /// cliente não o informa, e por isso não há como pedir URL para o avatar de outra
  /// pessoa e sobrescrever a foto dela.
  ///
  /// [tamanhoBytes] entra na assinatura: o storage recusa um `PUT` cujo
  /// `content-length` não seja exatamente este. É o que faz o limite de 5 MB ser
  /// real, e não uma declaração de boa vontade do cliente.
  Future<UrlDeUpload> urlDeUploadDeAvatar({
    required String contentType,
    required int tamanhoBytes,
  });

  /// O `PUT` dos bytes na URL assinada. **Não passa pelo user-service.**
  Future<void> enviarAvatar(
    UrlDeUpload destino,
    Uint8List bytes, {
    required String contentType,
  });
}
