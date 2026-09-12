/// Erro tratado, no formato que a API devolve.
///
/// Espelha `components.schemas.Error` dos contratos em `contracts/`, incluindo
/// o mapa `fields` com as mensagens por campo — que já vêm em português e são
/// exibíveis direto na tela, sem tradução no cliente.
///
/// Substitui o padrão do protótipo, em que todo controller terminava em
/// `catch (e) { return []; }`: lista vazia e erro indistinguíveis, então a tela
/// mostrava "nenhum resultado" tanto para busca sem resultado quanto para
/// backend fora do ar.
sealed class Failure {
  const Failure(this.mensagem);

  /// Mensagem exibível ao usuário, em português.
  final String mensagem;

  @override
  String toString() => '$runtimeType: $mensagem';
}

/// Falha de validação, com as mensagens por campo vindas do serviço.
final class FalhaDeValidacao extends Failure {
  const FalhaDeValidacao({
    required this.campos,
    String mensagem = 'Verifique os campos destacados',
  }) : super(mensagem);

  /// Nome do campo → mensagens. As chaves casam com os campos do formulário.
  final Map<String, List<String>> campos;

  /// Primeira mensagem de um campo, que é o que um `TextFormField` mostra.
  String? primeiroErroDe(String campo) => campos[campo]?.firstOrNull;
}

/// Credenciais recusadas, ou sessão que não vale mais.
final class FalhaDeAutenticacao extends Failure {
  const FalhaDeAutenticacao([super.mensagem = 'E-mail ou senha incorretos']);
}

/// Autenticado, mas sem permissão para a ação.
final class FalhaDePermissao extends Failure {
  const FalhaDePermissao([
    super.mensagem = 'Sua conta não tem permissão para esta ação',
  ]);
}

/// Recurso inexistente.
final class FalhaNaoEncontrado extends Failure {
  const FalhaNaoEncontrado([super.mensagem = 'Não encontramos o que você pediu']);
}

/// Conflito de unicidade — e-mail ou username já em uso.
final class FalhaDeConflito extends Failure {
  const FalhaDeConflito(super.mensagem);
}

/// Sem rede, ou o servidor não respondeu.
///
/// Separado de [FalhaDeServidor] porque a ação do usuário é diferente: aqui
/// tentar de novo costuma resolver.
final class FalhaDeRede extends Failure {
  const FalhaDeRede([
    super.mensagem = 'Sem conexão. Verifique sua internet e tente de novo.',
  ]);
}

/// O servidor respondeu, com erro dele.
final class FalhaDeServidor extends Failure {
  const FalhaDeServidor([
    super.mensagem = 'Algo deu errado do nosso lado. Tente novamente em instantes.',
  ]);
}
