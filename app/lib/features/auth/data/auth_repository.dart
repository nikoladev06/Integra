import 'package:integra/features/auth/data/models/par_de_tokens.dart';

/// Contrato de autenticação que as telas conhecem.
///
/// **Esta interface é a costura central do plano.** As telas dependem só dela,
/// nunca de `dio` nem de um endereço de API. Enquanto o `auth-service` não
/// existe, a implementação injetada é [FakeAuthRepository]; quando existir, a
/// troca é uma linha no provider — e nenhuma tela muda.
///
/// Os métodos correspondem um a um às rotas de `contracts/auth.openapi.yaml`.
/// Erros chegam como [Failure] lançado, não como retorno nulo: o protótipo
/// devolvia lista vazia em erro, o que tornava "sem resultado" e "backend fora"
/// indistinguíveis na tela.
abstract interface class AuthRepository {
  /// `POST /auth/register`. Não autentica — o cliente vai para o login depois.
  ///
  /// Lança `FalhaDeConflito` se e-mail ou username já existem, e
  /// `FalhaDeValidacao` com as mensagens por campo se algum valor é inválido.
  Future<void> cadastrar({
    required String nomeCompleto,
    required String email,
    required String username,
    required String senha,
    required String telefone,
    required String universidadeId,
    required String cursoId,
  });

  /// `POST /auth/login`. Lança `FalhaDeAutenticacao` em credencial recusada.
  Future<ParDeTokens> entrar({required String email, required String senha});

  /// `POST /auth/refresh`. Rotaciona o par; o token apresentado é revogado.
  Future<ParDeTokens> renovar(String refreshToken);

  /// `POST /auth/logout`. Idempotente — não lança se o token já era inválido.
  Future<void> sair(String refreshToken);

  /// `PUT /auth/password`. Exige a senha atual.
  ///
  /// Revoga todas as sessões, inclusive a que fez a troca: quem chama precisa
  /// levar o usuário de volta ao login. **Não há recuperação de senha por
  /// e-mail** — este é o único caminho de mudança de senha no sistema.
  Future<void> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmacao,
  });
}
