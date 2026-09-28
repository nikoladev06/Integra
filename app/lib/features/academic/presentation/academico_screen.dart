import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/academic/presentation/academic_providers.dart';
import 'package:integra/features/academic/presentation/widgets/botao_de_escopo.dart';
import 'package:integra/features/academic/presentation/widgets/post_card.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/shared/widgets/cabecalho_integra.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// Pilar Acadêmico — os comunicados institucionais.
///
/// Até a Sprint 3 esta tela era um vazio honesto: o `academic-service` não existia,
/// e preenchê-la com dados falsos esconderia o que faltava. Agora ela é o feed, e o
/// vazio continua tendo duas versões diferentes, porque as causas são diferentes e
/// o que o usuário precisa fazer também:
///
/// - **Sem vínculo**: o caminho é buscar a faculdade e informar o CPF. O vazio diz
///   isso, com o botão que leva à busca.
/// - **Com vínculo e nada publicado**: não há nada a fazer, e prometer ação seria
///   mandar o usuário procurar um problema que não é dele.
///
/// Quem decide o que aparece aqui é o **vínculo**, resolvido no serviço. A tela não
/// filtra nada: se filtrasse, a regra viraria decoração de UI, contornável por quem
/// ler a resposta da API em vez de olhar a tela.
///
/// É um [CustomScrollView] porque o cabeçalho é um sliver retrátil. Com `Column` +
/// `Expanded` + `ListView` haveria dois eixos de rolagem, e o cabeçalho ficaria
/// preso ao de fora — que nunca rola.
class AcademicoScreen extends ConsumerWidget {
  const AcademicoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ShadTheme.of(context).colorScheme;
    final perfil = ref.watch(perfilAtualProvider);
    final escopo = ref.watch(escopoDoFeedProvider);
    final feed = ref.watch(feedProvider);

    // A conta `faculdade` **ativada** compõe daqui. A pendente não vê o botão: ela
    // receberia 403 do serviço, e oferecer uma ação que será recusada é pior que
    // não oferecer — o aviso de análise está no perfil dela.
    final podePublicar =
        perfil != null &&
        perfil.tipo == TipoConta.faculdade &&
        perfil.ativadaEm != null;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(feedProvider),
        child: CustomScrollView(
          slivers: [
            CabecalhoIntegra(
              escopo: BotaoDeEscopo<EscopoDoFeed>(
                opcoes: EscopoDoFeed.values,
                selecionado: escopo,
                padrao: EscopoDoFeed.geral,
                rotulo: (e) => e.rotulo,
                descricao: (e) => e.descricao,
                cor: cores.academico,
                aoTrocar: (e) =>
                    ref.read(escopoDoFeedProvider.notifier).trocar(e),
              ),
              acoes: [
                if (podePublicar)
                  Tooltip(
                    message: 'Novo comunicado',
                    child: ShadIconButton.ghost(
                      icon: const Icon(LucideIcons.squarePen, size: 20),
                      onPressed: () => context.push(Rotas.comporPost),
                    ),
                  ),
              ],
            ),

            switch (feed) {
              AsyncError(:final error) => _Centrado(
                child: _Erro(
                  mensagem: error is Failure
                      ? error.mensagem
                      : 'Não foi possível carregar os comunicados.',
                  aoTentarDeNovo: () => ref.invalidate(feedProvider),
                ),
              ),
              AsyncLoading() => const _Centrado(
                child: Center(child: CircularProgressIndicator()),
              ),
              AsyncData(:final value) when value.itens.isEmpty => _Centrado(
                child: _Vazio(
                  escopo: escopo,
                  vinculo: perfil?.vinculo,
                  ehFaculdade: perfil?.tipo == TipoConta.faculdade,
                ),
              ),
              AsyncData(:final value) => _Lista(estado: value),
            },
          ],
        ),
      ),
    );
  }
}

/// Ocupa o que sobra da viewport, para vazio e erro ficarem centrados.
///
/// `hasScrollBody: false` é o que permite **rolar mesmo com a tela vazia** — sem
/// isso o `RefreshIndicator` não tem o que puxar, e o cabeçalho, que só volta com
/// uma rolagem para cima, ficaria escondido se o usuário o tivesse recolhido.
class _Centrado extends StatelessWidget {
  const _Centrado({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}

class _Lista extends ConsumerWidget {
  const _Lista({required this.estado});

  final FeedState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(feedProvider.notifier);

    return SliverPadding(
      padding: const EdgeInsets.all(Espaco.md),
      sliver: SliverList.builder(
        // +1 para o rodapé de "carregar mais", quando há próxima página.
        itemCount: estado.itens.length + (estado.temMais ? 1 : 0),
        itemBuilder: (context, indice) {
          if (indice == estado.itens.length) {
            return _CarregarMais(
              carregando: estado.carregandoMais,
              aoTocar: notifier.carregarMais,
            );
          }

          final post = estado.itens[indice];
          return PostCard(
            post: post,
            aoTocar: () => context.push(Rotas.post(post.id)),
            aoAtualizar: notifier.substituir,
            aoRemover: notifier.retirar,
          );
        },
      ),
    );
  }
}

/// Botão explícito em vez de rolagem infinita.
///
/// Um feed que carrega sozinho ao chegar no fim nunca tem fim visível, e num feed
/// institucional — que é finito, e onde o usuário procura *um* comunicado — saber
/// que a lista acabou é informação útil.
class _CarregarMais extends StatelessWidget {
  const _CarregarMais({required this.carregando, required this.aoTocar});

  final bool carregando;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Espaco.lg),
    child: Center(
      child: carregando
          ? const CircularProgressIndicator()
          : ShadButton.outline(
              onPressed: aoTocar,
              child: const Text('Carregar mais'),
            ),
    ),
  );
}

class _Vazio extends StatelessWidget {
  const _Vazio({
    required this.escopo,
    required this.vinculo,
    required this.ehFaculdade,
  });

  final EscopoDoFeed escopo;
  final Vinculo? vinculo;
  final bool ehFaculdade;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    // Conta institucional: não tem vínculo, e não deveria ler a frase sobre
    // informar CPF — ela não é aluna de si mesma.
    if (ehFaculdade) {
      return EstadoVazio(
        icone: LucideIcons.megaphone,
        cor: cores.academico,
        titulo: 'Você ainda não publicou nada',
        descricao:
            'Use o botão de escrever, no topo, para publicar o primeiro '
            'comunicado. Você escolhe se ele é público, interno à instituição '
            'ou restrito a um curso.',
      );
    }

    if (vinculo == null) {
      return EstadoVazio(
        icone: LucideIcons.graduationCap,
        cor: cores.academico,
        titulo: 'Você ainda não tem vínculo',
        // A frase carrega a regra que o modelo v2 existe para tornar verdadeira:
        // declarar não é ser confirmado. Um vazio genérico deixaria o aluno
        // achando que a faculdade não publica nada.
        descricao:
            'Os comunicados internos de uma instituição só aparecem para quem '
            'tem vínculo com ela — declarar a formação no perfil não basta. '
            'Busque sua faculdade e informe seu CPF no menu do perfil dela.',
        acao: ShadButton(
          leading: const Icon(LucideIcons.search, size: 16),
          onPressed: () => context.push(Rotas.busca),
          child: const Text('Buscar minha faculdade'),
        ),
      );
    }

    // Com vínculo e nada publicado: nada a fazer, e a tela não finge que há.
    return EstadoVazio(
      icone: LucideIcons.graduationCap,
      cor: cores.academico,
      titulo: escopo == EscopoDoFeed.minha
          ? 'Nada publicado pela ${vinculo!.universidade.sigla} ainda'
          : 'Nada por aqui ainda',
      descricao: escopo == EscopoDoFeed.minha
          ? 'Quando a ${vinculo!.universidade.sigla} publicar, os comunicados '
                'gerais e os do seu curso aparecem aqui.'
          : 'Este escopo inclui a sua instituição e as que você segue. Seguir '
                'mais faculdades pela busca traz os comunicados públicos delas.',
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.mensagem, required this.aoTentarDeNovo});

  final String mensagem;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) => EstadoVazio(
    icone: LucideIcons.cloudOff,
    titulo: 'Não foi possível carregar',
    descricao: mensagem,
    acao: ShadButton.outline(
      onPressed: aoTentarDeNovo,
      child: const Text('Tentar de novo'),
    ),
  );
}
