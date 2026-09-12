import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/integra_theme.dart';

/// Estado vazio reutilizável.
///
/// Um widget só para isso porque o protótipo não tinha nenhum: telas sem dados
/// apareciam em branco, e "sem resultado" era indistinguível de "erro" ou
/// "ainda carregando".
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.cor,
    this.acao,
    super.key,
  });

  final IconData icone;
  final String titulo;
  final String descricao;

  /// Cor do pilar, quando o vazio pertence a um.
  final Color? cor;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final destaque = cor ?? tema.colorScheme.mutedForeground;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Espaco.md),
              decoration: BoxDecoration(
                // A cor do pilar aparece só aqui, com opacidade baixa: o vazio
                // não deve competir com o conteúdo que virá ocupar o lugar.
                color: destaque.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 28, color: destaque),
            ),
            const SizedBox(height: Espaco.md),
            Text(
              titulo,
              style: tema.textTheme.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Espaco.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                descricao,
                style: tema.textTheme.muted,
                textAlign: TextAlign.center,
              ),
            ),
            if (acao != null) ...[const SizedBox(height: Espaco.lg), acao!],
          ],
        ),
      ),
    );
  }
}
