import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';
import 'package:integra/shared/domain/tempo.dart';

/// O card de uma vaga na listagem.
///
/// Não tem ações. Curtir e comentar não existem aqui, e **candidatar-se fica no
/// detalhe**, de propósito: é uma ação com consequência — a empresa passa a ver seu
/// nome — e um botão de um toque numa lista rolável é o jeito de alguém se candidatar
/// sem ter lido a descrição. O card leva ao detalhe, e o detalhe tem o botão.
///
/// O que ele mostra em vez de ações é **o estado em que a vaga está para este
/// leitor**: já se candidatou, é a autora, ou a vaga encerrou. Sem isso a lista
/// obrigaria a abrir cada item para descobrir o que já se fez.
class VagaCard extends StatelessWidget {
  const VagaCard({required this.vaga, this.aoTocar, super.key});

  final Vaga vaga;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.md),
      child: ShadCard(
        padding: const EdgeInsets.all(Espaco.md),
        child: InkWell(
          onTap: aoTocar,
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
                      LucideIcons.building2,
                      size: 18,
                      color: cores.profissional,
                    ),
                  ),
                  const SizedBox(width: Espaco.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vaga.titulo, style: tema.textTheme.small),
                        Text(
                          '${vaga.empresa.nome} · ${quando(vaga.criadoEm)}',
                          style: tema.textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espaco.sm),

              Text(
                vaga.descricao,
                // Duas linhas: o card é uma prévia, e a descrição de uma vaga tem
                // parágrafos. Cortar aqui é o que mantém a lista rolável.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.muted,
              ),
              const SizedBox(height: Espaco.sm),

              Wrap(
                spacing: Espaco.sm,
                runSpacing: Espaco.xs,
                children: [
                  ShadBadge.secondary(child: Text(vaga.tipo.rotulo)),
                  ShadBadge.outline(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          vaga.modalidade == Modalidade.remoto
                              ? LucideIcons.globe
                              : LucideIcons.mapPin,
                          size: 12,
                          color: cores.mutedForeground,
                        ),
                        const SizedBox(width: Espaco.xs),
                        Text(vaga.ondeE),
                      ],
                    ),
                  ),
                  _Situacao(vaga: vaga),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A etiqueta que diz **o que esta vaga é para este leitor**.
///
/// Quatro casos, e a ordem entre eles é a da tela e não a do servidor: encerrada
/// primeiro, porque é o que muda o que se pode fazer; depois autoria, porque a
/// empresa lê a própria lista; depois candidatura. Sem etiqueta nenhuma quando a vaga
/// está aberta e o leitor não fez nada — é o caso esperado, e marcar o esperado polui
/// o card sem informar.
class _Situacao extends StatelessWidget {
  const _Situacao({required this.vaga});

  final Vaga vaga;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    if (!vaga.aberta) {
      return const ShadBadge.destructive(child: Text('Encerrada'));
    }
    if (vaga.podeEditar) {
      return ShadBadge.secondary(
        child: Text('${vaga.totalDeCandidaturas} candidatura(s)'),
      );
    }
    if (vaga.candidaturaEnviada == true) {
      return ShadBadge(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.check, size: 12, color: cores.primaryForeground),
            const SizedBox(width: Espaco.xs),
            const Text('Candidatura enviada'),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
