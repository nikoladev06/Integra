import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/professional/presentation/profissional_providers.dart';
import 'package:integra/shared/domain/seletor_de_imagem.dart';

/// Compor um post do feed profissional.
///
/// **Não tem seletor de alcance**, e a ausência é a diferença central em relação ao
/// comunicado institucional: aqui não existe conteúdo restrito. Um seletor com uma
/// opção só seria um controle que não controla nada.
///
/// ## O fluxo de imagem, em três passos
///
/// Escolher a imagem **não** a envia. O envio acontece ao publicar, e na ordem que
/// importa:
///
///   1. pede a URL assinada ao serviço (que valida tipo e tamanho);
///   2. faz `PUT` dos bytes direto no storage;
///   3. publica o post com a `imagemUrl` resultante.
///
/// Os três são sequenciais porque **o post não deve existir se o `PUT` falhar**:
/// publicar primeiro e enviar depois deixaria um card com imagem quebrada que o autor
/// não tem como consertar. Se o passo 2 falha, nada foi publicado e a tela continua
/// com o texto digitado — é o que permite tentar de novo sem reescrever.
class ComporPostProfissionalScreen extends ConsumerStatefulWidget {
  const ComporPostProfissionalScreen({super.key});

  @override
  ConsumerState<ComporPostProfissionalScreen> createState() =>
      _ComporPostProfissionalScreenState();
}

class _ComporPostProfissionalScreenState
    extends ConsumerState<ComporPostProfissionalScreen> {
  final _conteudo = TextEditingController();

  ImagemEscolhida? _imagem;
  bool _publicando = false;
  String? _erroDeConteudo;

  @override
  void dispose() {
    _conteudo.dispose();
    super.dispose();
  }

  Future<void> _escolherImagem() async {
    try {
      final escolhida = await ref.read(seletorDeImagemProvider).escolher();
      // Nulo é cancelamento, e cancelar não é erro: avisar quem só mudou de ideia
      // ensina o usuário a desconfiar dos avisos.
      if (escolhida == null) return;
      setState(() => _imagem = escolhida);
    } on Object catch (_) {
      // A galeria pode falhar por permissão negada, e a mensagem do canal de
      // plataforma não é exibível. A ação é a mesma em todos os casos.
      _avisar('Não foi possível abrir a galeria.', erro: true);
    }
  }

  Future<void> _publicar() async {
    final texto = _conteudo.text.trim();
    if (texto.isEmpty) {
      setState(() => _erroDeConteudo = 'Escreva algo antes de publicar');
      return;
    }

    setState(() {
      _erroDeConteudo = null;
      _publicando = true;
    });

    try {
      final repo = ref.read(feedRepositoryProvider);

      String? imagemUrl;
      final imagem = _imagem;
      if (imagem != null) {
        // Passos 1 e 2. A validação de tipo e tamanho é do serviço: ele responde 422
        // com o campo nomeado, e é por isso que a mensagem cai no aviso em vez de
        // uma frase escrita aqui.
        final destino = await repo.urlDeUploadDeImagem(
          contentType: imagem.contentType,
          tamanhoBytes: imagem.tamanhoBytes,
        );
        await repo.enviarImagem(
          destino,
          imagem.bytes,
          contentType: imagem.contentType,
        );
        imagemUrl = destino.urlFinal;
      }

      // Passo 3. Só aqui o post passa a existir.
      await repo.publicar(conteudo: texto, imagemUrl: imagemUrl);

      // Recarrega o feed: o post novo é do próprio autor, e o autor entra sempre no
      // ramo "seguindo" do conjunto — então ele aparece na primeira página.
      ref.invalidate(feedProfissionalProvider);

      if (!mounted) return;
      // Fecha e confirma por toast, não por alerta no corpo: a confirmação vem quando
      // a tela fecha, e um alerta no corpo de uma tela que fecha nunca é lido. Foi o
      // defeito que a Sprint 4 encontrou em salvar o perfil.
      Navigator.of(context).pop();
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Post publicado.')),
      );
    } on FalhaDeValidacao catch (falha) {
      // O erro de campo fica **no corpo**, e não em toast: o oposto da confirmação,
      // porque precisa ficar à vista enquanto se corrige.
      setState(() {
        _erroDeConteudo =
            falha.primeiroErroDe('conteudo') ??
            falha.primeiroErroDe('contentType') ??
            falha.primeiroErroDe('tamanhoBytes') ??
            falha.mensagem;
      });
    } on Failure catch (falha) {
      _avisar(falha.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _publicando = false);
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

    return Scaffold(
      backgroundColor: cores.background,
      appBar: AppBar(
        // Mantém o título: é destino de toque, com botão de voltar, e o cabeçalho sem
        // texto é o das telas de navegação, onde a aba já diz onde se está.
        title: const Text('Novo post'),
        backgroundColor: cores.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          Text('O que você quer compartilhar?', style: tema.textTheme.small),
          const SizedBox(height: Espaco.xs),
          ShadTextarea(
            controller: _conteudo,
            placeholder: const Text(
              'Uma conquista, uma dúvida, uma oportunidade…',
            ),
            minHeight: 140,
            maxLength: 2000,
          ),
          if (_erroDeConteudo != null) ...[
            const SizedBox(height: Espaco.xs),
            Text(
              _erroDeConteudo!,
              style: tema.textTheme.muted.copyWith(color: cores.destructive),
            ),
          ],
          const SizedBox(height: Espaco.md),

          _Imagem(
            imagem: _imagem,
            aoEscolher: _publicando ? null : _escolherImagem,
            aoRemover: _publicando ? null : () => setState(() => _imagem = null),
          ),
          const SizedBox(height: Espaco.lg),

          ShadButton(
            onPressed: _publicando ? null : _publicar,
            leading: _publicando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.send, size: 16),
            child: Text(_publicando ? 'Publicando…' : 'Publicar'),
          ),
          const SizedBox(height: Espaco.md),

          Text(
            'Seu post aparece para quem te segue e para alunos da sua '
            'instituição. Não há alcance restrito no pilar Profissional — '
            'qualquer pessoa no Integra pode abrir o post pelo seu perfil.',
            style: tema.textTheme.muted,
          ),
        ],
      ),
    );
  }
}

/// O bloco de imagem: escolher, pré-visualizar e remover.
///
/// A pré-visualização sai dos **bytes em memória**, e não de uma URL: o arquivo ainda
/// não foi enviado a lugar nenhum. É o que permite mostrar o que foi escolhido antes
/// de publicar — e é a razão de [ImagemEscolhida] guardar bytes.
class _Imagem extends StatelessWidget {
  const _Imagem({
    required this.imagem,
    required this.aoEscolher,
    required this.aoRemover,
  });

  final ImagemEscolhida? imagem;
  final VoidCallback? aoEscolher;
  final VoidCallback? aoRemover;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final escolhida = imagem;

    if (escolhida == null) {
      return ShadButton.outline(
        onPressed: aoEscolher,
        leading: const Icon(LucideIcons.image, size: 16),
        child: const Text('Adicionar imagem'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(
              escolhida.bytes,
              fit: BoxFit.cover,
              // Um arquivo truncado ou com extensão mentindo sobre o conteúdo chega
              // aqui como bytes que o sistema não decodifica — e sem este ramo a
              // exceção sobe do serviço de imagem e pinta a tela de vermelho. O
              // arquivo continua enviável: o storage não decodifica nada, e é o
              // servidor quem valida o `Content-Type`.
              errorBuilder: (context, _, _) => ColoredBox(
                color: ShadTheme.of(context).colorScheme.muted,
                child: Center(
                  child: Text(
                    'Não foi possível pré-visualizar este arquivo',
                    textAlign: TextAlign.center,
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Espaco.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                // O tamanho aparece porque o limite é real — 5 MB, conferido pelo
                // storage — e descobrir que passou só no envio seria pior.
                '${(escolhida.tamanhoBytes / 1024).round()} KB · '
                '${escolhida.contentType}',
                style: tema.textTheme.muted,
              ),
            ),
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: aoRemover,
              leading: const Icon(LucideIcons.x, size: 14),
              child: const Text('Remover'),
            ),
          ],
        ),
      ],
    );
  }
}
