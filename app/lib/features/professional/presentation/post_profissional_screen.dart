import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';
import 'package:integra/features/professional/presentation/profissional_providers.dart';
import 'package:integra/features/professional/presentation/widgets/post_profissional_card.dart';
import 'package:integra/shared/domain/tempo.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// O detalhe de um post profissional, com os comentários.
///
/// Mantém o título no cabeçalho, ao contrário das telas de navegação: é destino de
/// toque, com botão de voltar, e ali o título é a única coisa que diz onde o usuário
/// está.
///
/// **404 aqui significa uma coisa só: o post não existe.** É a diferença em relação ao
/// detalhe de um comunicado, onde 404 também cobre "existe e você não alcança" — uma
/// ambiguidade deliberada, para a rota não virar sonda de conteúdo restrito. Neste
/// pilar não há conteúdo restrito, então a mensagem de erro pode dizer a verdade.
class PostProfissionalScreen extends ConsumerStatefulWidget {
  const PostProfissionalScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<PostProfissionalScreen> createState() =>
      _PostProfissionalScreenState();
}

class _PostProfissionalScreenState
    extends ConsumerState<PostProfissionalScreen> {
  final _campo = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Future<void> _comentar() async {
    final texto = _campo.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);
    try {
      await ref.read(feedRepositoryProvider).comentar(widget.postId, texto);
      _campo.clear();
      // Invalida os dois: a lista de comentários e o post, porque
      // `totalDeComentarios` fica no post e o card do topo o mostra.
      ref.invalidate(comentariosProfissionaisProvider(widget.postId));
      ref.invalidate(postProfissionalProvider(widget.postId));
    } on Failure catch (falha) {
      _avisar(falha.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _removerComentario(String comentarioId) async {
    try {
      await ref.read(feedRepositoryProvider).removerComentario(comentarioId);
      ref.invalidate(comentariosProfissionaisProvider(widget.postId));
      ref.invalidate(postProfissionalProvider(widget.postId));
      _avisar('Comentário removido.');
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
    final cores = ShadTheme.of(context).colorScheme;
    final post = ref.watch(postProfissionalProvider(widget.postId));
    final comentarios = ref.watch(
      comentariosProfissionaisProvider(widget.postId),
    );

    return Scaffold(
      backgroundColor: cores.background,
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: cores.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: switch (post) {
        AsyncError(:final error) => _Erro(
          mensagem: error is Failure
              ? error.mensagem
              : 'Não foi possível carregar o post.',
          aoTentarDeNovo: () =>
              ref.invalidate(postProfissionalProvider(widget.postId)),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncData(:final value) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Espaco.md),
                children: [
                  // Sem `aoTocar`: já estamos no detalhe, e tocar não leva a lugar
                  // nenhum. Sem `compacto` porque as ações — curtir, contar
                  // comentários — são o ponto desta tela.
                  PostProfissionalCard(
                    post: value,
                    aoAtualizar: (_) =>
                        ref.invalidate(postProfissionalProvider(widget.postId)),
                    aoRemover: (_) => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: Espaco.sm),
                  _Comentarios(
                    comentarios: comentarios,
                    aoRemover: _removerComentario,
                  ),
                ],
              ),
            ),
            _Campo(
              controlador: _campo,
              enviando: _enviando,
              aoEnviar: _comentar,
            ),
          ],
        ),
      },
    );
  }
}

class _Comentarios extends StatelessWidget {
  const _Comentarios({required this.comentarios, required this.aoRemover});

  final AsyncValue<PaginaDeComentariosProfissionais> comentarios;
  final void Function(String comentarioId) aoRemover;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return switch (comentarios) {
      AsyncError() => Text(
        'Não foi possível carregar os comentários.',
        style: tema.textTheme.muted,
      ),
      AsyncLoading() => const Padding(
        padding: EdgeInsets.all(Espaco.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      AsyncData(:final value) when value.itens.isEmpty => Padding(
        padding: const EdgeInsets.only(top: Espaco.md),
        child: Text(
          'Nenhum comentário ainda. Seja o primeiro.',
          style: tema.textTheme.muted,
        ),
      ),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final comentario in value.itens)
            _Comentario(
              comentario: comentario,
              aoRemover: comentario.podeRemover
                  ? () => aoRemover(comentario.id)
                  : null,
            ),
        ],
      ),
    };
  }
}

class _Comentario extends StatelessWidget {
  const _Comentario({required this.comentario, this.aoRemover});

  final ComentarioProfissional comentario;
  final VoidCallback? aoRemover;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cores.muted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(comentario.autor.iniciais, style: tema.textTheme.muted),
          ),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comentario.autor.nomeCompleto} · '
                  '${quando(comentario.criadoEm)}',
                  style: tema.textTheme.muted,
                ),
                Text(comentario.conteudo, style: tema.textTheme.p),
              ],
            ),
          ),
          if (aoRemover != null)
            // `podeRemover` vem do servidor: o autor do comentário **ou o autor do
            // post**. A tela não recalcula a regra, para não mostrar um botão que o
            // servidor recusa.
            ShadIconButton.ghost(
              icon: const Icon(LucideIcons.trash2, size: 14),
              onPressed: aoRemover,
            ),
        ],
      ),
    );
  }
}

/// O campo de comentário, fixo no rodapé.
///
/// Fora da lista rolável de propósito: um campo que rola para fora da tela obriga a
/// voltar ao fim da conversa para responder.
class _Campo extends StatelessWidget {
  const _Campo({
    required this.controlador,
    required this.enviando,
    required this.aoEnviar,
  });

  final TextEditingController controlador;
  final bool enviando;
  final VoidCallback aoEnviar;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(Espaco.sm),
        decoration: BoxDecoration(
          color: cores.card,
          border: Border(top: BorderSide(color: cores.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ShadInput(
                controller: controlador,
                placeholder: const Text('Escreva um comentário'),
                maxLength: 1000,
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: Espaco.sm),
            ShadIconButton(
              icon: enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.send, size: 16),
              onPressed: enviando ? null : aoEnviar,
            ),
          ],
        ),
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
