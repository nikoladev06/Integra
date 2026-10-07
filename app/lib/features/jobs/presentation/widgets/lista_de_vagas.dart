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

/// A aba de vagas: a barra de filtro e a lista.
///
/// Um sliver, e não uma tela: ela vive dentro do [CustomScrollView] do pilar
/// Profissional, junto do cabeçalho retrátil e da barra de abas. Como
/// [SliverMainAxisGroup], ela pode conter os dois slivers — filtro e lista — sem
/// virar um segundo eixo de rolagem.
class ListaDeVagas extends ConsumerWidget {
  const ListaDeVagas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vagas = ref.watch(vagasProvider);

    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: _BarraDeFiltro()),
        switch (vagas) {
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
        },
      ],
    );
  }
}

/// O filtro em vigor, sempre visível, com o que está ativo escrito.
///
/// Uma linha de etiquetas em vez de um ícone como o do escopo do feed, e a razão é a
/// diferença entre os dois controles: o escopo tem três opções mutuamente exclusivas
/// e caberia num tooltip; o filtro de vagas combina tipo, modalidade e estado, e uma
/// combinação não cabe numa frase de hover. Escrever o que está ativo é o que impede
/// alguém de ler uma lista filtrada como uma lista vazia.
class _BarraDeFiltro extends ConsumerWidget {
  const _BarraDeFiltro();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final filtro = ref.watch(filtroDeVagasProvider);
    final notifier = ref.read(filtroDeVagasProvider.notifier);
    final perfil = ref.watch(perfilAtualProvider);
    final ehEmpresa = perfil?.tipo == TipoConta.empresa;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espaco.md,
        Espaco.sm,
        Espaco.md,
        Espaco.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: Espaco.xs,
              runSpacing: Espaco.xs,
              children: [
                _Chip<TipoDeVaga>(
                  rotulo: 'Tipo',
                  valor: filtro.tipo,
                  opcoes: TipoDeVaga.values,
                  nome: (t) => t.rotulo,
                  aoTrocar: (t) => notifier.trocar(
                    FiltroDeVagas(
                      tipo: t,
                      modalidade: filtro.modalidade,
                      empresaId: filtro.empresaId,
                      estado: filtro.estado,
                    ),
                  ),
                ),
                _Chip<Modalidade>(
                  rotulo: 'Modalidade',
                  valor: filtro.modalidade,
                  opcoes: Modalidade.values,
                  nome: (m) => m.rotulo,
                  aoTrocar: (m) => notifier.trocar(
                    FiltroDeVagas(
                      tipo: filtro.tipo,
                      modalidade: m,
                      empresaId: filtro.empresaId,
                      estado: filtro.estado,
                    ),
                  ),
                ),
                // Só a empresa tem estas duas: "minhas vagas" e "encerradas" são as
                // perguntas de quem publica. Para o aluno, uma vaga encerrada é um
                // beco — ele não pode se candidatar —, e a dele em "minhas
                // candidaturas" já mostra o estado da vaga.
                if (ehEmpresa) ...[
                  _Alternar(
                    rotulo: 'Minhas vagas',
                    ativo: filtro.empresaId != null,
                    aoTrocar: (ativo) => notifier.trocar(
                      FiltroDeVagas(
                        tipo: filtro.tipo,
                        modalidade: filtro.modalidade,
                        empresaId: ativo ? perfil!.id : null,
                        estado: filtro.estado,
                      ),
                    ),
                  ),
                  _Alternar(
                    rotulo: 'Encerradas',
                    ativo: filtro.estado == EstadoDaVaga.fechada,
                    aoTrocar: (ativo) => notifier.trocar(
                      FiltroDeVagas(
                        tipo: filtro.tipo,
                        modalidade: filtro.modalidade,
                        empresaId: filtro.empresaId,
                        estado: ativo
                            ? EstadoDaVaga.fechada
                            : EstadoDaVaga.aberta,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (filtro.ativo)
            Tooltip(
              message: 'Limpar filtros',
              child: ShadIconButton.ghost(
                icon: Icon(LucideIcons.x, size: 16, color: cores.profissional),
                onPressed: notifier.limpar,
              ),
            ),
        ],
      ),
    );
  }
}

/// Um filtro de valor único, com "Todos" como primeira opção.
///
/// "Todos" existe na lista em vez de exigir o botão de limpar: desfazer uma escolha
/// tem que estar no mesmo lugar onde ela foi feita, senão o usuário procura o
/// contrário do que acabou de tocar.
class _Chip<T> extends StatelessWidget {
  const _Chip({
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.nome,
    required this.aoTrocar,
  });

  final String rotulo;
  final T? valor;
  final List<T> opcoes;
  final String Function(T) nome;
  final ValueChanged<T?> aoTrocar;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;
    final ativo = valor != null;

    return MenuAnchor(
      builder: (context, controlador, _) => ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () =>
            controlador.isOpen ? controlador.close() : controlador.open(),
        trailing: Icon(
          LucideIcons.chevronDown,
          size: 14,
          color: ativo ? cores.profissional : cores.mutedForeground,
        ),
        child: Text(ativo ? nome(valor as T) : rotulo),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () => aoTrocar(null),
          child: Text('Todos · $rotulo'),
        ),
        for (final opcao in opcoes)
          MenuItemButton(
            leadingIcon: Icon(
              LucideIcons.check,
              size: 14,
              color: opcao == valor ? cores.profissional : Colors.transparent,
            ),
            onPressed: () => aoTrocar(opcao),
            child: Text(nome(opcao)),
          ),
      ],
    );
  }
}

class _Alternar extends StatelessWidget {
  const _Alternar({
    required this.rotulo,
    required this.ativo,
    required this.aoTrocar,
  });

  final String rotulo;
  final bool ativo;
  final ValueChanged<bool> aoTrocar;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: () => aoTrocar(!ativo),
      leading: Icon(
        ativo ? LucideIcons.checkCheck : LucideIcons.circle,
        size: 14,
        color: ativo ? cores.profissional : cores.mutedForeground,
      ),
      child: Text(rotulo),
    );
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

    return SliverPadding
      (
      padding: const EdgeInsets.fromLTRB(
        Espaco.md,
        Espaco.xs,
        Espaco.md,
        Espaco.md,
      ),
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
