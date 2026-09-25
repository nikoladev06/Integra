import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';

/// O cabeçalho comum às telas internas: título do pilar e a busca.
///
/// A busca mora aqui, e não dentro de cada feed, porque ela atravessa os três
/// tipos de coisa que o app conhece — universidades, empresas e pessoas — e
/// nenhum feed é dono dela. No protótipo era uma tela à parte, alcançável só
/// pelo menu, e que buscava apenas usuários.
///
/// O campo é um botão com cara de campo. Digitar dentro de uma `AppBar` em tela
/// de celular deixa o teclado cobrindo os resultados; tocar aqui abre a tela de
/// busca com o foco já no campo e espaço para os três grupos.
class CabecalhoIntegra extends StatelessWidget implements PreferredSizeWidget {
  const CabecalhoIntegra({required this.titulo, this.acoes, super.key});

  final String titulo;
  final List<Widget>? acoes;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 52);

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return AppBar(
      title: Text(titulo),
      backgroundColor: cores.card,
      surfaceTintColor: Colors.transparent,
      actions: acoes,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Espaco.md,
            0,
            Espaco.md,
            Espaco.sm,
          ),
          child: Semantics(
            button: true,
            label: 'Buscar universidades, empresas e pessoas',
            child: InkWell(
              onTap: () => context.push(Rotas.busca),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: Espaco.sm),
                decoration: BoxDecoration(
                  color: cores.muted,
                  border: Border.all(color: cores.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 16,
                      color: cores.mutedForeground,
                    ),
                    const SizedBox(width: Espaco.sm),
                    Text(
                      'Buscar universidades, empresas e pessoas',
                      style: tema.textTheme.muted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
