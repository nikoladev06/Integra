import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/integra_theme.dart';

/// Uma aba: o valor que ela seleciona, o ícone que a desenha e o nome que ela tem.
///
/// O `rotulo` não é desenhado — é o que o leitor de tela anuncia e o que o tooltip
/// mostra. Ícone sozinho, sem isso, é um botão sem nome para quem não enxerga.
typedef AbaDeIcone<T> = ({T valor, IconData icone, String rotulo});

/// Barra de abas **só de ícone**, fixada no topo da lista.
///
/// É o formato que o Instagram usa nos perfis: uma faixa de ícones com sublinhado
/// na ativa. Nasceu no perfil da instituição, para separar comunicados por alcance,
/// e foi extraída para cá quando o perfil do usuário precisou da mesma coisa —
/// duas barras iguais escritas em dois arquivos divergem no primeiro ajuste de
/// espaçamento.
///
/// **Fixada** (`pinned`): trocar de aba não deveria exigir rolar de volta ao topo,
/// e o cabeçalho, que é `floating`, volta com a rolagem para cima sem trazer as
/// abas consigo.
///
/// É um sliver, e por isso só funciona dentro de um [CustomScrollView] — o mesmo
/// requisito que o cabeçalho retrátil já impõe às telas de navegação.
class AbasDeIcone<T> extends StatelessWidget {
  const AbasDeIcone({
    required this.abas,
    required this.selecionada,
    required this.cor,
    required this.aoTrocar,
    super.key,
  });

  final List<AbaDeIcone<T>> abas;
  final T selecionada;

  /// A cor do pilar ou da seção. Pinta o ícone e o sublinhado da aba ativa.
  final Color cor;

  final ValueChanged<T> aoTrocar;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _Delegate<T>(
        abas: abas,
        selecionada: selecionada,
        cor: cor,
        fundo: cores.card,
        borda: cores.border,
        apagado: cores.mutedForeground,
        aoTrocar: aoTrocar,
      ),
    );
  }
}

class _Delegate<T> extends SliverPersistentHeaderDelegate {
  const _Delegate({
    required this.abas,
    required this.selecionada,
    required this.cor,
    required this.fundo,
    required this.borda,
    required this.apagado,
    required this.aoTrocar,
  });

  final List<AbaDeIcone<T>> abas;
  final T selecionada;
  final Color cor;
  final Color fundo;
  final Color borda;
  final Color apagado;
  final ValueChanged<T> aoTrocar;

  static const _altura = 46.0;

  @override
  double get minExtent => _altura;

  @override
  double get maxExtent => _altura;

  @override
  bool shouldRebuild(_Delegate<T> antiga) =>
      antiga.selecionada != selecionada ||
      antiga.cor != cor ||
      antiga.abas.length != abas.length;

  @override
  Widget build(BuildContext context, double deslocamento, bool sobreposta) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fundo,
        border: Border(bottom: BorderSide(color: borda)),
      ),
      child: Row(
        children: [
          for (final aba in abas)
            Expanded(
              child: _Aba(
                icone: aba.icone,
                rotulo: aba.rotulo,
                selecionada: aba.valor == selecionada,
                cor: cor,
                apagado: apagado,
                aoTocar: () => aoTrocar(aba.valor),
              ),
            ),
        ],
      ),
    );
  }
}

class _Aba extends StatelessWidget {
  const _Aba({
    required this.icone,
    required this.rotulo,
    required this.selecionada,
    required this.cor,
    required this.apagado,
    required this.aoTocar,
  });

  final IconData icone;
  final String rotulo;
  final bool selecionada;
  final Color cor;
  final Color apagado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final tinta = selecionada ? cor : apagado;

    return Semantics(
      label: rotulo,
      selected: selecionada,
      button: true,
      // Sem `excludeSemantics` o nó ficaria sem rótulo depois que o texto saiu — a
      // mesma armadilha que a navegação inferior documenta.
      excludeSemantics: true,
      child: Tooltip(
        message: rotulo,
        child: InkWell(
          onTap: aoTocar,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 22, color: tinta),
              const SizedBox(height: Espaco.xs),
              // Mesmo sublinhado animado da navegação inferior: a posição fica
              // legível de relance, e a linguagem visual das duas barras é a mesma.
              // Ocupa altura mesmo invisível, senão o ícone salta ao ser escolhido.
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: selecionada ? 28 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: tinta,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
