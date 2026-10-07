/// Data relativa curta, em português.
///
/// `há 3 h` diz mais que `20/09 10:00` num feed: quem rola uma lista quer saber se
/// é de hoje, não a hora exata. Passada uma semana a frase relativa perde utilidade
/// — "há 43 d" não significa nada — e a data absoluta volta.
///
/// Nasceu privada em `post_card.dart` e subiu para cá na Sprint 5, quando o card do
/// feed profissional e o da vaga precisaram da mesma coisa. Três cópias das mesmas
/// cinco faixas divergiriam no primeiro ajuste de limite.
///
/// **Sem `intl` e sem pacote novo.** São cinco faixas em uma língua, e a alternativa
/// seria carregar localização inteira para produzir exatamente estas cinco frases.
String quando(DateTime data) {
  final diferenca = DateTime.now().toUtc().difference(data.toUtc());

  if (diferenca.inMinutes < 1) return 'agora';
  if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inHours < 24) return 'há ${diferenca.inHours} h';
  if (diferenca.inDays < 7) return 'há ${diferenca.inDays} d';

  final d = data.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
