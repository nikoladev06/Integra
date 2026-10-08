import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/professional/data/models/post_profissional.dart';
import 'package:integra/shared/domain/tempo.dart';

/// O card de um post profissional.
///
/// Espelha o [PostCard] do Acadêmico, e as duas diferenças dizem o que separa os
/// pilares:
///
/// - **Não há etiqueta de alcance.** Lá ela não era decoração — um comunicado
///   restrito a um curso parece igual a um público se nada disser o contrário, e o
///   aluno precisa saber disso antes de comentar. Aqui não existe alcance: todo post
///   é legível por qualquer conta, e uma etiqueta seria um aviso sobre nada.
/// - **Há a etiqueta de origem**, e só no caso `recomendado`. Sem ela o usuário não
///   entende por que vê alguém que não segue — e a reação costuma ser desconfiança,
///   não descoberta. `seguindo` não ganha etiqueta: é o caso esperado, e marcar o
///   esperado polui o card sem informar.
class PostProfissionalCard extends ConsumerStatefulWidget {
  const PostProfissionalCard({
    required this.post,
    this.aoTocar,
    this.aoAtualizar,
    this.aoRemover,
    this.compacto = false,
    super.key,
  });

  final PostProfissional post;

  /// Abrir o detalhe. Nulo na própria tela de detalhe, onde tocar não leva a lugar
  /// nenhum.
  final VoidCallback? aoTocar;

  final void Function(PostProfissional)? aoAtualizar;
  final void Function(String postId)? aoRemover;

  /// Sem o rodapé de ações. Usado na aba de publicações de um perfil, onde o card é
  /// uma prévia e o que se espera do toque é abrir, não curtir.
  final bool compacto;

  @override
  ConsumerState<PostProfissionalCard> createState() =>
      _PostProfissionalCardState();
}

class _PostProfissionalCardState extends ConsumerState<PostProfissionalCard> {
  bool _ocupado = false;

  PostProfissional get _post => widget.post;

  Future<void> _curtir() async {
    setState(() => _ocupado = true);
    try {
      final repo = ref.read(feedRepositoryProvider);
      await repo.curtir(_post.id, curtir: !_post.curtidoPorMim);
      // Relê o post em vez de somar 1 na contagem local: com duas pessoas curtindo ao
      // mesmo tempo, a conta local fica errada e só se corrige na próxima carga.
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
        title: const Text('Apagar post?'),
        description: const Text(
          'As curtidas e os comentários vão junto, e não há como desfazer.',
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
      await ref.read(feedRepositoryProvider).remover(_post.id);
      widget.aoRemover?.call(_post.id);
      _avisar('Post apagado.');
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

              if (_post.temImagem) ...[
                const SizedBox(height: Espaco.sm),
                _Imagem(url: _post.imagemUrl!),
              ],

              if (_post.explicaOrigem) ...[
                const SizedBox(height: Espaco.sm),
                const _EtiquetaDeOrigem(),
              ],

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
                      cor: _post.curtidoPorMim ? cores.profissional : null,
                      aoTocar: _ocupado ? null : _curtir,
                    ),
                    const SizedBox(width: Espaco.sm),
                    _Acao(
                      icone: LucideIcons.messageSquare,
                      rotulo: '${_post.totalDeComentarios}',
                      semantica:
                          'Comentários: ${_post.totalDeComentarios}. Abrir o post',
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

/// O autor, a data, e o botão de apagar.
///
/// **O bloco do autor é tocável**, e leva ao perfil público dele — pessoa ou empresa.
/// Um [GestureDetector] e não um [InkWell]: o card inteiro já é um `InkWell` que abre
/// o post, e dois deles aninhados desenham dois respingos de toque sobrepostos. Aqui
/// basta interceptar o gesto antes que ele suba para o pai.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.post, this.aoApagar});

  final PostProfissional post;
  final VoidCallback? aoApagar;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final empresa = post.autor.tipo == TipoDeAutor.empresa;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            button: true,
            // Sem `excludeSemantics`: o nome e a arroba são conteúdo, e não só o
            // rótulo do botão — quem usa leitor de tela precisa dos dois.
            label: 'Abrir o perfil de ${post.autor.nomeCompleto}',
            child: GestureDetector(
              onTap: () => context.push(Rotas.usuario(post.autor.id)),
              // Sem isto o gesto só pega onde há pixel desenhado, e a faixa vazia à
              // direita do nome abriria o post em vez do perfil.
              behavior: HitTestBehavior.opaque,
              child: Row(
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
                    // O ícone distingue empresa de pessoa antes de a linha de texto
                    // ser lida. É a mesma informação que o escopo filtra, e é o que
                    // dá sentido a filtrar.
                    child: Icon(
                      empresa ? LucideIcons.building2 : LucideIcons.user,
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
                          post.autor.nomeCompleto,
                          style: tema.textTheme.small,
                        ),
                        Text(
                          post.editado
                              ? '@${post.autor.username} · ${quando(post.criadoEm)} · editado'
                              : '@${post.autor.username} · ${quando(post.criadoEm)}',
                          style: tema.textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (aoApagar != null)
          // `podeEditar` vem do servidor — a tela não compara ids por conta própria
          // para não concluir diferente dele.
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.trash2, size: 16),
            onPressed: aoApagar,
          ),
      ],
    );
  }
}

/// A imagem do post.
///
/// `errorBuilder` não é zelo excessivo: a imagem vive num storage separado, com URL
/// própria, e o serviço **não confere** que o arquivo chegou ao publicar. Uma imagem
/// pedida e não enviada é um estado possível — e no modo de fixtures é o estado
/// normal, porque nada é enviado. Sem este ramo, o card viraria um X vermelho de
/// framework no meio do feed.
class _Imagem extends StatelessWidget {
  const _Imagem({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => DecoratedBox(
            decoration: BoxDecoration(color: cores.muted),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.imageOff,
                    size: 24,
                    color: cores.mutedForeground,
                  ),
                  const SizedBox(height: Espaco.xs),
                  Text(
                    'Imagem indisponível',
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Recomendado — aluno da FATEC RP" seria melhor, e não é o que dá para escrever.
///
/// O servidor devolve a **origem**, não o motivo detalhado: dizer de qual
/// universidade veio a recomendação exigiria expor o vínculo do autor a quem lê o
/// feed, e vínculo de terceiro não é informação de quem abre o app. A etiqueta diz o
/// que é possível dizer sem isso.
class _EtiquetaDeOrigem extends StatelessWidget {
  const _EtiquetaDeOrigem();

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return ShadBadge.secondary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.sparkles, size: 12, color: cores.profissional),
          const SizedBox(width: Espaco.xs),
          const Text('Recomendado'),
        ],
      ),
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
  /// diz nada.
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
