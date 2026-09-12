/// Configuração por ambiente, vinda de `--dart-define`.
///
/// Nunca de arquivo em `assets`: era assim que a chave do Google Places ia
/// embarcada no binário no protótipo. `--dart-define` entra em tempo de
/// compilação e não vira arquivo dentro do app.
///
/// Local, contra a stack do docker compose:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://localhost:8080
/// ```
///
/// Contra fixtures, sem backend algum — o padrão:
/// ```
/// flutter run
/// ```
abstract final class Ambiente {
  /// Vazio significa "use os repositórios falsos".
  ///
  /// É o padrão de propósito: o app precisa subir e ser navegável sem backend,
  /// que é o portão desta sprint. Um endereço padrão apontando para localhost
  /// faria o app falhar em rede na primeira tela para quem só quer rodar.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Sem `API_BASE_URL`, o app roda contra fixtures em memória.
  static bool get usarFalsos => apiBaseUrl.isEmpty;
}
