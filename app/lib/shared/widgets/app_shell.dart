import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/tokens.dart';

/// A casca de navegação: as abas dos pilares, mais o botão de publicar.
///
/// Substitui o `home_view.dart` do protótipo, que tinha 32 KB porque acumulava
/// shell de navegação, feed e composição de card no mesmo `build`. Aqui a casca só
/// sabe trocar de aba; cada pilar é uma tela própria.
///
/// O pilar Social não tem aba: não existe no app até a Fase 4.
///
/// ## Quatro itens, três deles abas
///
/// O terceiro — publicar — **não é uma aba**, é uma ação: ele empilha uma tela por
/// cima da casca em vez de trocar o ramo de navegação. A diferença importa no
/// código porque `StatefulNavigationShell.currentIndex` conta só os ramos: se
/// publicar fosse o índice 2, Perfil passaria a ser o 3 e o índice do shell
/// deixaria de casar com a posição na barra. Por isso a lista abaixo distingue os
/// dois tipos, e o índice do ramo é declarado, não inferido da posição.
class AppShell extends StatelessWidget {
  const AppShell({required this.navegacao, super.key});

  final StatefulNavigationShell navegacao;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return Scaffold(
      body: navegacao,
      bottomNavigationBar: _BarraInferior(
        children: [
          _Item(
            icone: LucideIcons.graduationCap,
            rotulo: Pilar.academico.rotulo,
            selecionado: navegacao.currentIndex == 0,
            cor: cores.academico,
            onTap: () => _irParaRamo(0),
          ),
          _Item(
            icone: LucideIcons.briefcase,
            rotulo: Pilar.profissional.rotulo,
            selecionado: navegacao.currentIndex == 1,
            cor: cores.profissional,
            onTap: () => _irParaRamo(1),
          ),

          // Ação, não aba: empilha por cima da casca. Fica **antes** do
          // Perfil, que é onde o polegar do usuário já espera encontrar o
          // "publicar" nas redes que ele usa.
          _Item(
            icone: LucideIcons.squarePlus,
            rotulo: 'Publicar',
            selecionado: false,
            cor: cores.primary,
            onTap: () => context.push(Rotas.publicar),
          ),

          _Item(
            icone: LucideIcons.user,
            rotulo: 'Perfil',
            selecionado: navegacao.currentIndex == 2,
            cor: cores.primary,
            onTap: () => _irParaRamo(2),
          ),
        ],
      ),
    );
  }

  /// `initialLocation: true` volta ao topo da aba quando ela já está selecionada —
  /// o gesto que o usuário espera.
  void _irParaRamo(int indice) => navegacao.goBranch(
    indice,
    initialLocation: indice == navegacao.currentIndex,
  );
}

/// A faixa do rodapé: fundo, borda de cima, e a folga de baixo **medida**.
///
/// Existe como widget próprio por causa dessa folga, que errou duas vezes.
///
/// O jeito óbvio é `SafeArea`, e é o que estava aqui. O problema é que ele repassa
/// o recorte do sistema **inteiro** para baixo do conteúdo: num celular com barra
/// de gesto de 48 px, a faixa ia de 37 para 85 px e sobravam 55 px abaixo dos
/// ícones — eles pareciam colados no topo de um rodapé alto, que foi exatamente o
/// sintoma relatado. Em tela sem recorte nada disso aparecia, então dava para
/// "corrigir" duas vezes sem tocar na causa.
///
/// A conta aqui é outra: **metade do recorte, no máximo 12 px.** O indicador de
/// gesto é uma pílula fina desenhada a uns 8 px da borda; 12 px de folga deixam o
/// ícone livre dela sem doar a faixa toda. O fundo continua atrás da folga, então
/// não sobra tira branca na borda da tela.
///
/// `viewPaddingOf` e não `paddingOf`: `padding` zera quando o teclado sobe, e a
/// barra pularia de altura no meio de uma digitação.
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.children});

  final List<Widget> children;

  /// Folga quando não há recorte nenhum — web, desktop, celular com botões.
  static const _semRecorte = 2.0;

  /// Teto da folga com recorte. Acima disto a faixa volta a parecer alta.
  static const _tetoDoRecorte = 12.0;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;
    final recorte = MediaQuery.viewPaddingOf(context).bottom;

    final folga = recorte > 0
        ? (recorte / 2).clamp(_semRecorte, _tetoDoRecorte)
        : _semRecorte;

    return DecoratedBox(
      // Chave para o teste medir a faixa: a altura dela errou duas vezes, e medir
      // é a única forma de afirmar que não vai errar de novo.
      key: const ValueKey('barra-inferior'),
      decoration: BoxDecoration(
        color: cores.card,
        border: Border(top: BorderSide(color: cores.border)),
      ),
      // O `Padding` por dentro do `DecoratedBox`: o fundo cobre a folga também.
      child: Padding(
        padding: EdgeInsets.only(bottom: folga),
        child: Row(children: children),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icone,
    required this.rotulo,
    required this.selecionado,
    required this.cor,
    required this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final bool selecionado;

  /// A cor quando ativo. Cada aba carrega a do seu pilar, para a posição na
  /// navegação ser legível sem ler o texto.
  final Color cor;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;
    final tinta = selecionado ? cor : cores.mutedForeground;

    return Expanded(
      child: Semantics(
        label: rotulo,
        selected: selecionado,
        button: true,
        // O rótulo sai da tela mas não do widget: vira o nome que o leitor de tela
        // anuncia e a dica no hover. Ícone sozinho, sem isso, é um botão sem nome
        // para quem não enxerga. Sem `excludeSemantics` o nó ficaria sem rótulo
        // depois que o Text saiu.
        excludeSemantics: true,
        child: Tooltip(
          message: rotulo,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              // Assimétrico: a folga de cima separa o ícone da borda da faixa e do
              // conteúdo que rola por trás dela — 6 px deixava o ícone encostado no
              // topo. A de baixo é de `_BarraInferior`, que sabe do recorte do
              // sistema; aqui embaixo não entra nada.
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 24, color: tinta),
                  const SizedBox(height: 3),
                  // Um traço no lugar do texto: a aba ativa continua legível de
                  // relance, sem repetir por escrito o que o ícone já diz. Ocupa
                  // altura mesmo invisível, senão o ícone salta ao ser selecionado.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: selecionado ? 16 : 0,
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
        ),
      ),
    );
  }
}
