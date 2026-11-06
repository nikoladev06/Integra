import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';
import 'package:integra/features/jobs/presentation/jobs_providers.dart';
import 'package:integra/features/jobs/presentation/widgets/vaga_card.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// A aba de vagas: só a lista.
///
/// Um sliver, e não uma tela: ela vive dentro do [CustomScrollView] do pilar
/// Profissional, junto do cabeçalho retrátil e da barra de abas.
///
/// **O filtro saiu daqui** e virou o `BotaoDeFiltroDeVagas`, no canto esquerdo do
/// cabeçalho — o mesmo lugar do botão de escopo nas duas telas de feed. Ele ficava
/// numa faixa logo abaixo das abas, que custava até duas linhas permanentes da tela
/// quando os quatro controles da empresa não caíam numa. Com ele fora, esta aba é um
/// sliver só, e não um [SliverMainAxisGroup].
class ListaDeVagas extends ConsumerWidget {
  const ListaDeVagas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vagas = ref.watch(vagasProvider);

    return switch (vagas) {
      AsyncError(:final error) => _Centrado(
        child: _Erro(
          mensagem: error is Failure
              ? error.mensagem
              : 'Não foi possível carregar as vagas.',
          aoTentarDeNovo: () => ref.invalidate(vagasProvider),
        ),
      ),
      AsyncLoading() => const _Centrado(
        child: Center(child: CircularProgressIndicator()),
      ),
      AsyncData(:final value) when value.itens.isEmpty => const _Centrado(
        child: _Vazio(),
      ),
      AsyncData(:final value) => _Lista(estado: value),
    };
  }
}

class _Centrado extends StatelessWidget {
  const _Centrado({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}

class _Lista extends ConsumerWidget {
  const _Lista({required this.estado});

  final VagasState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(vagasProvider.notifier);

    return SliverPadding(
      padding: const EdgeInsets.all(Espaco.md),
      sliver: SliverList.builder(
        itemCount: estado.itens.length + (estado.temMais ? 1 : 0),
        itemBuilder: (context, indice) {
          if (indice == estado.itens.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Espaco.lg),
              child: Center(
                child: estado.carregandoMais
                    ? const CircularProgressIndicator()
                    : ShadButton.outline(
                        onPressed: notifier.carregarMais,
                        child: const Text('Carregar mais'),
                      ),
              ),
            );
          }

          final vaga = estado.itens[indice];
          return VagaCard(
            vaga: vaga,
            aoTocar: () => context.push(Rotas.vaga(vaga.id)),
          );
        },
      ),
    );
  }
}

class _Vazio extends ConsumerWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ShadTheme.of(context).colorScheme;
    final filtro = ref.watch(filtroDeVagasProvider);
    final perfil = ref.watch(perfilAtualProvider);

    // Com filtro ativo o vazio é do filtro, e não da área. Dizer "nenhuma vaga
    // publicada" aqui seria mentir: há vagas, nenhuma casa com o que foi pedido.
    if (filtro.ativo) {
      return EstadoVazio(
        icone: LucideIcons.filterX,
        cor: cores.profissional,
        titulo: 'Nenhuma vaga com esses filtros',
        descricao:
            'Há vagas publicadas, mas nenhuma casa com o que você escolheu. '
            'Limpe os filtros para ver todas as abertas.',
        acao: ShadButton.outline(
          onPressed: ref.read(filtroDeVagasProvider.notifier).limpar,
          child: const Text('Limpar filtros'),
        ),
      );
    }

    if (perfil?.tipo == TipoConta.empresa) {
      return EstadoVazio(
        icone: LucideIcons.briefcase,
        cor: cores.profissional,
        titulo: 'Nenhuma vaga aberta ainda',
        descricao: perfil?.ativadaEm == null
            // A conta pendente vê o motivo, e não um vazio genérico: ela não
            // consegue publicar, e descobrir isso no formulário seria pior.
            ? 'Sua conta está em análise. Quando for ativada, você publica vagas '
                  'pelo botão do topo, e os alunos se candidatam por aqui.'
            : 'Use o botão de mais, no topo, para publicar a primeira. Você '
                  'escolhe o tipo, a modalidade e — fora do remoto — a cidade.',
      );
    }

    return EstadoVazio(
      icone: LucideIcons.briefcase,
      cor: cores.profissional,
      titulo: 'Nenhuma vaga aberta ainda',
      descricao:
          'As vagas de estágio, júnior e trainee publicadas por empresas '
          'aparecem aqui. Quando houver, você se candidata pelo detalhe da vaga.',
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
