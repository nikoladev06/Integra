import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';
import 'package:integra/features/jobs/presentation/jobs_providers.dart';
import 'package:integra/shared/domain/tempo.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// A aba "minhas candidaturas" do aluno.
///
/// Um sliver, como a lista de vagas: vive dentro do [CustomScrollView] do pilar.
///
/// **A lista é de "onde me candidatei", e por isso cada item mostra a vaga inteira** —
/// título, empresa e estado dela. Um item com só a data e o estado da candidatura
/// obrigaria a abrir cada um para lembrar do que se trata.
class ListaDeCandidaturas extends ConsumerWidget {
  const ListaDeCandidaturas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidaturas = ref.watch(minhasCandidaturasProvider);

    return switch (candidaturas) {
      AsyncError(:final error) => _Centrado(
        child: _Erro(
          mensagem: error is Failure
              ? error.mensagem
              : 'Não foi possível carregar suas candidaturas.',
          aoTentarDeNovo: () => ref.invalidate(minhasCandidaturasProvider),
        ),
      ),
      AsyncLoading() => const _Centrado(
        child: Center(child: CircularProgressIndicator()),
      ),
      AsyncData(:final value) when value.itens.isEmpty => const _Centrado(
        child: _Vazio(),
      ),
      AsyncData(:final value) => SliverPadding(
        padding: const EdgeInsets.all(Espaco.md),
        sliver: SliverList.builder(
          itemCount: value.itens.length,
          itemBuilder: (context, indice) =>
              CandidaturaCard(candidatura: value.itens[indice]),
        ),
      ),
    };
  }
}

/// O card de uma candidatura.
///
/// Usado nas **duas** listas — a do aluno e a que a empresa vê numa vaga —, e
/// [mostrarCandidato] é o que muda: o aluno já sabe quem ele é, e a empresa já sabe de
/// que vaga se trata. Cada lado vê o que não é óbvio do seu ponto de vista.
///
/// Um widget para os dois porque a linha é a mesma informação lida de dois ângulos.
/// Dois cards divergiriam no primeiro ajuste, e o estado da candidatura — que é o que
/// a Sprint 5 acrescentou de novo — apareceria diferente para os dois lados.
class CandidaturaCard extends StatelessWidget {
  const CandidaturaCard({
    required this.candidatura,
    this.mostrarCandidato = false,
    this.aoMarcarVisualizada,
    super.key,
  });

  final Candidatura candidatura;

  /// `true` na lista da empresa. `false` na do aluno, onde a vaga é o assunto.
  final bool mostrarCandidato;

  /// Só a empresa autora da vaga. Nulo na lista do aluno — e a ausência é a regra:
  /// quem transiciona o estado é a empresa, e um botão aqui faria o aluno marcar a
  /// própria candidatura como vista.
  final VoidCallback? aoMarcarVisualizada;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final vaga = candidatura.vaga;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.md),
      child: ShadCard(
        padding: const EdgeInsets.all(Espaco.md),
        child: InkWell(
          onTap: () => context.push(Rotas.vaga(vaga.id)),
          borderRadius: BorderRadius.circular(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cores.profissional.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      mostrarCandidato
                          ? LucideIcons.user
                          : LucideIcons.building2,
                      size: 18,
                      color: cores.profissional,
                    ),
                  ),
                  const SizedBox(width: Espaco.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mostrarCandidato
                              ? candidatura.candidato.nomeCompleto
                              : vaga.titulo,
                          style: tema.textTheme.small,
                        ),
                        Text(
                          mostrarCandidato
                              ? '@${candidatura.candidato.username} · '
                                    '${quando(candidatura.criadoEm)}'
                              : '${vaga.empresa.nome} · '
                                    '${quando(candidatura.criadoEm)}',
                          style: tema.textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espaco.sm),

              Wrap(
                spacing: Espaco.sm,
                runSpacing: Espaco.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _EstadoDaCandidatura(candidatura: candidatura),
                  // A vaga encerrada aparece na lista do aluno: ele continua vendo
                  // onde se candidatou depois de o processo terminar. É por isso que o
                  // detalhe de uma vaga fechada continua legível.
                  if (!vaga.aberta)
                    const ShadBadge.destructive(child: Text('Vaga encerrada')),
                  if (mostrarCandidato)
                    ShadBadge.outline(child: Text(vaga.tipo.rotulo)),
                ],
              ),

              if (aoMarcarVisualizada != null && !candidatura.vista) ...[
                const SizedBox(height: Espaco.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.outline(
                    size: ShadButtonSize.sm,
                    leading: const Icon(LucideIcons.eye, size: 14),
                    onPressed: aoMarcarVisualizada,
                    child: const Text('Marcar como visualizada'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// O estado, com a explicação que o aluno lê.
///
/// A explicação vem do enum, e não da tela: é a razão de o estado existir — sem algo
/// que muda, a tela do aluno não tem o que dizer depois de ele se candidatar.
class _EstadoDaCandidatura extends StatelessWidget {
  const _EstadoDaCandidatura({required this.candidatura});

  final Candidatura candidatura;

  @override
  Widget build(BuildContext context) {
    final vista = candidatura.vista;

    return Tooltip(
      message: candidatura.estado.explicacao,
      child: vista
          ? ShadBadge(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.eye, size: 12),
                  const SizedBox(width: Espaco.xs),
                  Text(candidatura.estado.rotulo),
                ],
              ),
            )
          : ShadBadge.secondary(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.clock, size: 12),
                  const SizedBox(width: Espaco.xs),
                  Text(candidatura.estado.rotulo),
                ],
              ),
            ),
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

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return EstadoVazio(
      icone: LucideIcons.send,
      cor: cores.profissional,
      titulo: 'Você ainda não se candidatou',
      descricao:
          'As vagas a que você se candidatar aparecem aqui, com o estado de cada '
          'uma — você vê quando a empresa abre a sua candidatura.',
      acao: ShadButton(
        leading: const Icon(LucideIcons.briefcase, size: 16),
        onPressed: () => context.push(Rotas.profissional),
        child: const Text('Ver vagas abertas'),
      ),
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
