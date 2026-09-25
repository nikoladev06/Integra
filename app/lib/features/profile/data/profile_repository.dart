import 'package:integra/features/profile/data/models/instituicao.dart';
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
  Future<void> seguirUniversidade(String universidadeId, {required bool seguir});
}
