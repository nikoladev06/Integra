import 'package:integra/features/auth/data/models/par_de_tokens.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// Contrato de autenticação que as telas conhecem.
///
/// **Esta interface é a costura central do plano.** As telas dependem só dela,
/// nunca de `dio` nem de um endereço de API. Os métodos correspondem um a um às
/// rotas de `contracts/auth.openapi.yaml`.
///
/// Erros chegam como [Failure] lançado, não como retorno nulo: o protótipo
/// devolvia lista vazia em erro, o que tornava "sem resultado" e "backend fora"
/// indistinguíveis na tela.
abstract interface class AuthRepository {
  /// `POST /auth/register`. Não autentica — o cliente vai para o login depois.
  ///
  /// [cpf] é obrigatório desde a v2 e é a chave que liga a conta às matrículas
  /// que as faculdades cadastram. [universidadeId] e [cursoId] são **opcionais**
  /// e vêm juntos ou não vêm: informados, criam uma formação *declarada* — uma
  /// linha de currículo, sem verificação e sem acesso a nada.
  ///
  /// Lança `FalhaDeConflito` se e-mail, username ou CPF já existem, e
  /// `FalhaDeValidacao` com as mensagens por campo se algum valor é inválido.
  Future<void> cadastrar({
    required String nomeCompleto,
    required String email,
    required String username,
    required String senha,
    required String telefone,
    required String cpf,
    String? universidadeId,
    String? cursoId,
  });

  /// `POST /auth/register/instituicao`. Uma rota, duas telas.
  ///
  /// [tipo] só aceita [TipoConta.faculdade] e [TipoConta.empresa]; aluno vai por
  /// [cadastrar]. **A conta nasce pendente**: entra e edita o perfil, mas não
  /// publica nem matricula até ser ativada — a tela lê `ativadaEm` em
  /// `GET /users/me` e mostra o aviso de análise enquanto for nulo.
  ///
  /// [sigla] só é usada quando o CNPJ não corresponde a nenhuma universidade
  /// catalogada e uma nova precisa ser criada.
  Future<void> cadastrarInstituicao({
    required TipoConta tipo,
    required String nome,
    required String cnpj,
    required String email,
    required String username,
    required String senha,
    required String telefone,
    String? sigla,
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
