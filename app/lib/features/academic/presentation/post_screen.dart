import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/academic/presentation/academic_providers.dart';
import 'package:integra/features/academic/presentation/compor_post_screen.dart';
import 'package:integra/features/academic/presentation/widgets/post_card.dart';

/// Um comunicado e a conversa embaixo dele.
///
/// Fora do alcance do leitor, o serviço responde 404 — o mesmo de um post que
/// nunca existiu. A tela não tenta distinguir os dois casos porque **não pode**:
/// é assim de propósito, para a rota não virar sonda de comunicados restritos por
/// quem iterar ids.
///
/// Comentar exige poder ver o post, e a checagem é do serviço. Se a tela
/// escondesse o campo de comentário por conta própria, seria decoração — o
/// servidor recusaria de qualquer forma, e é ele quem decide.
class PostScreen extends ConsumerWidget {
  const PostScreen({required this.postId, super.key});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final post = ref.watch(postProvider(postId));

    return Scaffold(
      backgroundColor: tema.colorScheme.background,
      appBar: AppBar(
        title: const Text('Comunicado'),
        backgroundColor: tema.colorScheme.card,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (post.hasValue && post.requireValue.podeEditar)
            ShadIconButton.ghost(
              icon: const Icon(LucideIcons.pencil, size: 16),
              onPressed: () async {
                final alterado = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ComporPostScreen(post: post.requireValue),
                  ),
                );
                if (alterado == true) ref.invalidate(postProvider(postId));
              },
            ),
        ],
      ),
      body: switch (post) {
        AsyncError(:final error) => _Erro(
          mensagem: error is Failure
              ? error.mensagem
              : 'Não foi possível carregar este comunicado.',
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncData(:final value) => _Conteudo(post: value),
      },
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Espaco.xl),
      child: Text(
        mensagem,
        style: ShadTheme.of(context).textTheme.muted,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _Conteudo extends ConsumerWidget {
  const _Conteudo({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final comentarios = ref.watch(comentariosProvider(post.id));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Espaco.md),
            children: [
              PostCard(
                post: post,
                // Sem `aoTocar`: já estamos no detalhe, e um card que navega para
                // a tela em que se está é um beco.
                aoAtualizar: (_) => ref.invalidate(postProvider(post.id)),
                aoRemover: (_) => Navigator.of(context).pop(),
              ),
              const SizedBox(height: Espaco.sm),
              Text(
                post.totalDeComentarios == 1
                    ? '1 comentário'
                    : '${post.totalDeComentarios} comentários',
                style: tema.textTheme.small,
              ),
              const SizedBox(height: Espaco.sm),

              switch (comentarios) {
                AsyncError() => Text(
                  'Não foi possível carregar os comentários.',
                  style: tema.textTheme.muted,
                ),
                AsyncLoading() => const Padding(
                  padding: EdgeInsets.symmetric(vertical: Espaco.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                AsyncData(:final value) when value.itens.isEmpty => Text(
                  'Ninguém comentou ainda.',
                  style: tema.textTheme.muted,
                ),
                AsyncData(:final value) => Column(
                  children: [
                    for (final comentario in value.itens)
                      _Comentario(comentario: comentario, postId: post.id),
                  ],
                ),
              },
            ],
          ),
        ),
        _CampoDeComentario(postId: post.id),
      ],
    );
  }
}

class _Comentario extends ConsumerWidget {
  const _Comentario({required this.comentario, required this.postId});

  final Comentario comentario;
  final String postId;

  Future<void> _remover(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(academicRepositoryProvider)
          .removerComentario(comentario.id);
      ref.invalidate(comentariosProvider(postId));
      ref.invalidate(postProvider(postId));
    } on Failure catch (falha) {
      if (context.mounted) {
        ShadToaster.of(context)
            .show(ShadToast.destructive(description: Text(falha.mensagem)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadAvatar(
            comentario.autor.fotoUrl ?? '',
            placeholder: Text(comentario.autor.iniciais),
            size: const Size.square(32),
          ),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comentario.autor.nomeCompleto,
                        style: tema.textTheme.small,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '@${comentario.autor.username}',
                      style: tema.textTheme.muted,
                    ),
                  ],
                ),
                Text(comentario.conteudo, style: tema.textTheme.p),
              ],
            ),
          ),
          // `podeRemover` vem do servidor: é a **mesma** regra que autoriza a
          // remoção — autor do comentário, ou a faculdade autora do post. Um
          // botão que a tela decide mostrar e o servidor recusa é o que duas
          // cópias da regra produzem.
          if (comentario.podeRemover)
            ShadIconButton.ghost(
              icon: Icon(LucideIcons.x, size: 14, color: cores.mutedForeground),
              onPressed: () => _remover(context, ref),
            ),
        ],
      ),
    );
  }
}

class _CampoDeComentario extends ConsumerStatefulWidget {
  const _CampoDeComentario({required this.postId});

  final String postId;

  @override
  ConsumerState<_CampoDeComentario> createState() => _CampoDeComentarioState();
}

class _CampoDeComentarioState extends ConsumerState<_CampoDeComentario> {
  final _controlador = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _controlador.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);
    try {
      await ref.read(academicRepositoryProvider).comentar(widget.postId, texto);
      _controlador.clear();
      ref.invalidate(comentariosProvider(widget.postId));
      // O post também: `totalDeComentarios` é dele, e sem isto a contagem no card
      // ficaria atrasada em relação à lista logo abaixo.
      ref.invalidate(postProvider(widget.postId));
    } on Failure catch (falha) {
      if (mounted) {
        ShadToaster.of(context)
            .show(ShadToast.destructive(description: Text(falha.mensagem)));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Espaco.md,
        Espaco.sm,
        Espaco.md,
        Espaco.md,
      ),
      decoration: BoxDecoration(
        color: cores.card,
        border: Border(top: BorderSide(color: cores.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ShadInput(
                controller: _controlador,
                placeholder: const Text('Escreva um comentário'),
                maxLength: 1000,
                onSubmitted: (_) => _enviar(),
              ),
            ),
            const SizedBox(width: Espaco.sm),
            ShadIconButton(
              icon: const Icon(LucideIcons.send, size: 16),
              onPressed: _enviando ? null : _enviar,
            ),
          ],
        ),
      ),
    );
  }
}
