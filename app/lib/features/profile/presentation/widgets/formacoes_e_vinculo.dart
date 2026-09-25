import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// O selo de formação verificada.
///
/// Só aparece nas verificadas. **As não verificadas não ganham rótulo algum** —
/// nem "não verificada", nem cinza, nem tachado: a ausência do selo já comunica
/// o suficiente, e carimbar o contrário transformaria currículo declarado em
/// acusação.
class SeloDeVerificacao extends StatelessWidget {
  const SeloDeVerificacao({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return Tooltip(
      message: 'Confirmada pela instituição',
      child: Icon(LucideIcons.badgeCheck, size: 16, color: cores.ok),
    );
  }
}

/// A lista de formações do perfil.
///
/// [aoRemover] só é passado na tela de edição. Verificada não é removível, e o
/// botão nem aparece nelas: o selo é afirmação da instituição, não do usuário, e
/// deixá-lo apagável pelo perfil transformaria "verificado" em algo que o
/// próprio interessado controla.
class CartaoDeFormacoes extends StatelessWidget {
  const CartaoDeFormacoes({
    required this.formacoes,
    this.aoRemover,
    this.acao,
    super.key,
  });

  final List<Formacao> formacoes;
  final void Function(Formacao formacao)? aoRemover;

  /// Botão de "adicionar formação", na tela de edição.
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return ShadCard(
      title: const Text('Formação'),
      description: const Text(
        'Seu currículo, como você declara. Não concede acesso a nada.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Espaco.sm),
          if (formacoes.isEmpty)
            Text(
              'Nenhuma formação declarada.',
              style: tema.textTheme.muted,
            )
          else
            for (final formacao in formacoes)
              _LinhaDeFormacao(
                formacao: formacao,
                aoRemover: aoRemover == null || formacao.verificada
                    ? null
                    : () => aoRemover!(formacao),
              ),
          if (acao != null) ...[const SizedBox(height: Espaco.sm), acao!],
        ],
      ),
    );
  }
}

class _LinhaDeFormacao extends StatelessWidget {
  const _LinhaDeFormacao({required this.formacao, this.aoRemover});

  final Formacao formacao;
  final VoidCallback? aoRemover;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        formacao.curso.nome,
                        style: tema.textTheme.small,
                      ),
                    ),
                    if (formacao.verificada) ...[
                      const SizedBox(width: Espaco.xs),
                      const SeloDeVerificacao(),
                    ],
                  ],
                ),
                Text(
                  '${formacao.universidade.sigla} — '
                  '${formacao.universidade.nome}',
                  style: tema.textTheme.muted,
                ),
              ],
            ),
          ),
          if (aoRemover != null)
            ShadIconButton.ghost(
              icon: const Icon(LucideIcons.trash2, size: 16),
              onPressed: aoRemover,
            ),
        ],
      ),
    );
  }
}

/// O vínculo ativo, ou a explicação de por que não há um.
///
/// O texto do estado vazio carrega a regra inteira do modelo v2, porque é aqui
/// que o usuário a encontra pela primeira vez: declarar formação não basta, o
/// que vale é o CPF conferido contra a lista da instituição.
class CartaoDeVinculo extends StatelessWidget {
  const CartaoDeVinculo({required this.vinculo, this.acao, super.key});

  final Vinculo? vinculo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final atual = vinculo;

    return ShadCard(
      title: const Text('Vínculo institucional'),
      description: const Text(
        'O que dá acesso aos comunicados internos da sua instituição.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Espaco.sm),
          if (atual == null)
            Text(
              'Você não tem vínculo ativo. Abra o perfil da sua faculdade na '
              'busca e informe seu CPF — se ele constar na lista de alunos '
              'dela, o vínculo é criado e sua formação ganha o selo.',
              style: tema.textTheme.muted,
            )
          else ...[
            Row(
              children: [
                Icon(
                  LucideIcons.graduationCap,
                  size: 16,
                  color: cores.academico,
                ),
                const SizedBox(width: Espaco.sm),
                Expanded(
                  child: Text(
                    '${atual.universidade.sigla} — ${atual.curso.nome}',
                    style: tema.textTheme.small,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espaco.xs),
            Text(atual.universidade.nome, style: tema.textTheme.muted),
          ],
          if (acao != null) ...[const SizedBox(height: Espaco.md), acao!],
        ],
      ),
    );
  }
}
