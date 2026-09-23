import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/tokens.dart';

/// A casca de navegação: as abas dos pilares.
///
/// Substitui o `home_view.dart` do protótipo, que tinha 32 KB porque acumulava
/// shell de navegação, feed e composição de card no mesmo `build`. Aqui a casca
/// só sabe trocar de aba; cada pilar é uma tela própria.
///
/// O pilar Social não tem aba: não existe no app até a Fase 4.
class AppShell extends StatelessWidget {
  const AppShell({required this.navegacao, super.key});

  final StatefulNavigationShell navegacao;

  static const _abas = [
    (pilar: Pilar.academico, icone: LucideIcons.graduationCap),
    (pilar: Pilar.profissional, icone: LucideIcons.briefcase),
    (pilar: null, icone: LucideIcons.user),
  ];

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return Scaffold(
      body: navegacao,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: cores.card,
          border: Border(top: BorderSide(color: cores.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (final (indice, aba) in _abas.indexed)
                Expanded(
                  child: _ItemDeAba(
                    icone: aba.icone,
                    // O rótulo sai da tela mas não do widget: vira o nome que o
                    // leitor de tela anuncia e a dica no hover. Ícone sozinho,
                    // sem isso, é um botão sem nome para quem não enxerga.
                    rotulo: aba.pilar?.rotulo ?? 'Perfil',
                    selecionado: navegacao.currentIndex == indice,
                    // Cada aba carrega a cor do seu pilar quando ativa, para a
                    // posição na navegação ser legível sem ler o texto.
                    corAtiva: aba.pilar == null
                        ? cores.primary
                        : cores.doPilar(aba.pilar!),
                    // `initialLocation: true` volta ao topo da aba quando ela já
                    // está selecionada — o gesto que o usuário espera.
                    onTap: () => navegacao.goBranch(
                      indice,
                      initialLocation: indice == navegacao.currentIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemDeAba extends StatelessWidget {
  const _ItemDeAba({
    required this.icone,
    required this.rotulo,
    required this.selecionado,
    required this.corAtiva,
    required this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final bool selecionado;
  final Color corAtiva;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;
    final cor = selecionado ? corAtiva : cores.mutedForeground;

    return Semantics(
      label: rotulo,
      selected: selecionado,
      button: true,
      // O texto sai da árvore, então o nome do botão passa a vir daqui. Sem
      // `excludeSemantics` o nó ficaria sem rótulo depois que o Text saiu.
      excludeSemantics: true,
      child: Tooltip(
        message: rotulo,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 24, color: cor),
                const SizedBox(height: 6),
                // Um ponto no lugar do texto: a aba ativa continua legível de
                // relance, sem repetir por escrito o que o ícone já diz.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: selecionado ? 16 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
