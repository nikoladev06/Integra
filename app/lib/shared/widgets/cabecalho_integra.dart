import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';

/// O cabeçalho das telas de navegação: escopo, busca e chat. **Sem texto.**
///
/// Três elementos, e nenhum deles é o nome da tela. O título saiu por onde o
/// rótulo das abas já havia saído na Sprint 2: escrever "Acadêmico" acima de uma
/// aba de Acadêmico que já está sublinhada é repetir de duas formas a mesma
/// informação, e o que se paga por isso é a faixa mais valiosa de uma tela de
/// celular. Onde a tela precisa se apresentar — um formulário, um detalhe
/// alcançado por toque —, o `AppBar` comum com título continua, porque ali o
/// título é a única coisa que diz onde o usuário está.
///
/// ## Retrátil pelo rolar, não por botão
///
/// `floating: true, snap: true` num [SliverAppBar]: rolar para baixo leva o
/// cabeçalho embora, e **qualquer** rolagem para cima o traz de volta inteiro, sem
/// precisar voltar ao topo da lista. É o comportamento do LinkedIn e do Instagram,
/// e é a razão de ele ser um sliver em vez do `appBar:` do `Scaffold`: o `appBar`
/// não tem como saber que a lista rolou.
///
/// A consequência é que **toda tela que usa este cabeçalho é um
/// [CustomScrollView]**, com ele como primeiro sliver. Uma tela com `Column` +
/// `Expanded` + `ListView` tem dois eixos de rolagem e o cabeçalho ficaria preso
/// ao de fora, que nunca rola.
class CabecalhoIntegra extends StatelessWidget {
  const CabecalhoIntegra({this.escopo, this.acoes, this.direita, super.key});

  /// O botão de escopo do feed, quando a tela tem um escopo.
  ///
  /// Nulo nas telas que não têm — perfil, e o feed profissional até o
  /// `feed-service` existir. O espaço à esquerda é reservado de qualquer forma,
  /// para a busca ficar centrada igual em todas as abas; mostrar um botão que não
  /// faz nada seria pior que deixar o canto vazio.
  final Widget? escopo;

  /// Ações extras, à esquerda do canto direito.
  final List<Widget>? acoes;

  /// Ocupa o canto direito **em vez** do botão de mensagens.
  ///
  /// Serve ao perfil da instituição, onde o menu de opções — inserir CPF, encerrar
  /// vínculo — é a ação daquela tela. Duas coisas no mesmo canto obrigariam a
  /// escolher entre espremer as duas ou empurrar a busca para fora do centro, e o
  /// menu ganha: mensagens está a um toque em qualquer aba, e o menu só existe ali.
  final Widget? direita;

  /// Largura do slot da esquerda. É a de um [ShadIconButton], e fixá-la é o que
  /// mantém a busca no mesmo lugar com e sem o botão de escopo.
  static const _larguraDoSlot = 40.0;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return SliverAppBar(
      // `floating` sem `pinned`: ele sai inteiro de cena ao rolar para baixo.
      // `snap` faz o retorno ser completo em vez de proporcional ao gesto — sem
      // ele, uma rolagem curta para cima deixa o cabeçalho meio visível, e o
      // campo de busca cortado ao meio parece defeito.
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: cores.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: cores.border)),
      titleSpacing: Espaco.sm,
      // 48 e não os 56 padrão do Material: aquela altura é dimensionada para um
      // título com duas linhas de folga, e aqui não há título — só um campo de
      // 32 px e dois ícones. O que sobrava era faixa vazia no topo de cada tela.
      toolbarHeight: 48,
      title: Row(
        children: [
          SizedBox(
            width: _larguraDoSlot,
            child: escopo ?? const SizedBox.shrink(),
          ),
          const SizedBox(width: Espaco.xs),
          const Expanded(child: _CampoDeBusca()),
          const SizedBox(width: Espaco.xs),
          ...?acoes,
          direita ?? const _BotaoDeChat(),
        ],
      ),
    );
  }
}

/// A busca: um botão com cara de campo.
///
/// Digitar dentro de uma `AppBar` em tela de celular deixa o teclado cobrindo os
/// resultados; tocar aqui abre a tela de busca com o foco já no campo e espaço
/// para os três grupos.
///
/// O texto encurtou de "Buscar universidades, empresas e pessoas" para uma palavra
/// quando o cabeçalho passou a ter três elementos na mesma faixa: a frase inteira
/// não caberia sem espremer o campo, e a tela de busca — que tem largura sobrando —
/// continua dizendo o que procura.
class _CampoDeBusca extends StatelessWidget {
  const _CampoDeBusca();

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Semantics(
      button: true,
      label: 'Buscar universidades, empresas e pessoas',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(Rotas.busca),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // Acompanha a faixa: 32 deixa 8 px acima e abaixo dentro dos 48.
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: Espaco.sm),
          decoration: BoxDecoration(
            color: cores.muted,
            border: Border.all(color: cores.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.search, size: 15, color: cores.mutedForeground),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Text(
                  'Buscar',
                  style: tema.textTheme.muted,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensagens diretas. **Não existe ainda** — leva a uma tela que diz isso.
///
/// Chat não estava no escopo de nenhuma das cinco sprints, nem nos três pilares:
/// entrou como decisão de produto durante a Sprint 4, e o serviço dele é trabalho
/// de uma sprint própria (ver o plano). O botão existe desde já porque o desenho do
/// cabeçalho o pede, e porque mudar a posição dos três elementos depois de as
/// pessoas se acostumarem custa mais que uma tela de vazio honesto.
class _BotaoDeChat extends StatelessWidget {
  const _BotaoDeChat();

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Mensagens',
    child: ShadIconButton.ghost(
      icon: const Icon(LucideIcons.messageCircle, size: 20),
      onPressed: () => context.push(Rotas.mensagens),
    ),
  );
}
