import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/academic/data/models/post.dart';

/// O card de um comunicado.
///
/// O protótipo montava o card dentro do `build` do feed, num arquivo de 32 KB
/// junto da navegação. Aqui é um widget, porque três telas o usam: o feed, o
/// perfil da instituição e o detalhe do post.
///
/// A **etiqueta de alcance** é a parte que não é decoração. Um comunicado restrito
/// a um curso parece igual a um público se nada disser o contrário, e o aluno
/// precisa saber que aquilo não é público — sobretudo antes de comentar.
class PostCard extends ConsumerStatefulWidget {
  const PostCard({
    required this.post,
    this.aoTocar,
    this.aoAtualizar,
    this.aoRemover,
    this.compacto = false,
    super.key,
  });

  final Post post;

  /// Abrir o detalhe. Nulo na própria tela de detalhe, onde tocar não leva a
  /// lugar nenhum.
  final VoidCallback? aoTocar;

  /// Chamado com o post novo depois de curtir ou editar, para a lista trocar um
  /// item em vez de recarregar a página — recarregar faria a rolagem pular.
  final void Function(Post)? aoAtualizar;
  final void Function(String postId)? aoRemover;

  /// Sem o rodapé de ações. Usado no perfil da instituição, onde o card é uma
  /// prévia e o que se espera do toque é abrir, não curtir.
  final bool compacto;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _ocupado = false;

  Post get _post => widget.post;

  Future<void> _curtir() async {
    setState(() => _ocupado = true);
    try {
      final repo = ref.read(academicRepositoryProvider);
      await repo.curtir(_post.id, curtir: !_post.curtidoPorMim);
      // Relê o post em vez de somar 1 na contagem local: com duas pessoas
      // curtindo ao mesmo tempo, a conta local fica errada e só se corrige na
      // próxima carga. Uma requisição a mais vale o número certo.
      widget.aoAtualizar?.call(await repo.post(_post.id));
    } on Failure catch (falha) {
      _avisar(falha.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _remover() async {
    final confirmado = await showShadDialog<bool>(
      context: context,
      builder: (_) => ShadDialog.alert(
        title: const Text('Apagar comunicado?'),
        description: const Text(
          'As curtidas e os comentários vão junto, e não há como desfazer. '
          'Quem já leu não é avisado.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await ref.read(academicRepositoryProvider).remover(_post.id);
      widget.aoRemover?.call(_post.id);
      _avisar('Comunicado apagado.');
    } on Failure catch (falha) {
      _avisar(falha.mensagem, erro: true);
    }
  }

  void _avisar(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      erro
          ? ShadToast.destructive(description: Text(mensagem))
          : ShadToast(description: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.md),
      child: ShadCard(
        padding: const EdgeInsets.all(Espaco.md),
        child: InkWell(
          onTap: widget.aoTocar,
          borderRadius: BorderRadius.circular(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cabecalho(
                post: _post,
                aoApagar: _post.podeEditar ? _remover : null,
              ),
              const SizedBox(height: Espaco.sm),

              Text(_post.conteudo, style: tema.textTheme.p),
              const SizedBox(height: Espaco.sm),

              _Etiquetas(post: _post),

              if (!widget.compacto) ...[
                const SizedBox(height: Espaco.sm),
                Divider(color: cores.border, height: 1),
                const SizedBox(height: Espaco.xs),
                Row(
                  children: [
                    _Acao(
                      icone: _post.curtidoPorMim
                          ? LucideIcons.heartHandshake
                          : LucideIcons.heart,
                      rotulo: '${_post.totalDeCurtidas}',
                      semantica: _post.curtidoPorMim
                          ? 'Descurtir. ${_post.totalDeCurtidas} curtidas'
                          : 'Curtir. ${_post.totalDeCurtidas} curtidas',
                      cor: _post.curtidoPorMim ? cores.academico : null,
                      aoTocar: _ocupado ? null : _curtir,
                    ),
                    const SizedBox(width: Espaco.sm),
                    _Acao(
                      icone: LucideIcons.messageSquare,
                      rotulo: '${_post.totalDeComentarios}',
                      semantica:
                          'Comentários: ${_post.totalDeComentarios}. Abrir o comunicado',
                      aoTocar: widget.aoTocar,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.post, this.aoApagar});

  final Post post;
  final VoidCallback? aoApagar;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cores.academico.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(LucideIcons.school, size: 18, color: cores.academico),
        ),
        const SizedBox(width: Espaco.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A sigla, e não o nome inteiro: "FATEC RP" cabe na linha e é como
              // o aluno chama a instituição.
              GestureDetector(
                onTap: () =>
                    context.push(Rotas.universidade(post.instituicao.id)),
                child: Text(
                  post.instituicao.sigla,
                  style: tema.textTheme.small,
                ),
              ),
              Text(
                post.editado
                    ? '${_quando(post.criadoEm)} · editado'
                    : _quando(post.criadoEm),
                style: tema.textTheme.muted,
              ),
            ],
          ),
        ),
        if (aoApagar != null)
          // Só a conta autora, e `podeEditar` vem do servidor — a tela não compara
          // ids por conta própria para não concluir diferente dele.
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.trash2, size: 16),
            onPressed: aoApagar,
          ),
      ],
    );
  }
}

class _Etiquetas extends StatelessWidget {
  const _Etiquetas({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    // O público não ganha etiqueta: é o alcance esperado, e marcá-lo faria a
    // etiqueta perder o sentido de aviso. O que precisa de destaque é o restrito.
    if (!post.restrito) return const SizedBox.shrink();

    return Wrap(
      spacing: Espaco.sm,
      runSpacing: Espaco.xs,
      children: [
        ShadBadge.secondary(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                post.visibilidade == Visibilidade.curso
                    ? LucideIcons.graduationCap
                    : LucideIcons.lock,
                size: 12,
                color: cores.academico,
              ),
              const SizedBox(width: Espaco.xs),
              Text(post.alcance),
            ],
          ),
        ),
      ],
    );
  }
}

class _Acao extends StatelessWidget {
  const _Acao({
    required this.icone,
    required this.rotulo,
    required this.semantica,
    this.cor,
    this.aoTocar,
  });

  final IconData icone;
  final String rotulo;

  /// O que o leitor de tela anuncia. O botão mostra só o número, e "3" sozinho não
  /// diz nada — a mesma razão pela qual as abas da navegação inferior têm rótulo
  /// no widget mesmo sem texto na tela.
  final String semantica;

  final Color? cor;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final tinta = cor ?? tema.colorScheme.mutedForeground;

    return Semantics(
      button: true,
      label: semantica,
      child: ShadButton.ghost(
        size: ShadButtonSize.sm,
        onPressed: aoTocar,
        leading: Icon(icone, size: 16, color: tinta),
        child: Text(rotulo, style: tema.textTheme.muted.copyWith(color: tinta)),
      ),
    );
  }
}

/// Data relativa curta. `há 3 h` diz mais que `20/09 10:00` num feed.
///
/// Sem `intl` e sem pacote novo: são cinco faixas, e a alternativa seria carregar
/// localização inteira para produzir as mesmas cinco frases em português.
String _quando(DateTime quando) {
  final diferenca = DateTime.now().toUtc().difference(quando.toUtc());

  if (diferenca.inMinutes < 1) return 'agora';
  if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inHours < 24) return 'há ${diferenca.inHours} h';
  if (diferenca.inDays < 7) return 'há ${diferenca.inDays} d';

  final d = quando.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
