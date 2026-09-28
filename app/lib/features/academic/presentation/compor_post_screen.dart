import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/academic/presentation/academic_providers.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// Composição e edição de um comunicado. Só conta `faculdade` ativada chega aqui.
///
/// A tela é a mesma para publicar e editar porque as decisões são as mesmas — e a
/// Sprint 4 decidiu que a edição pode mudar **o alcance**, não só o texto. O
/// custo dessa decisão está registrado no contrato: quem já leu não é avisado. A
/// tela avisa quem está editando, que é a única pessoa que pode ponderar.
class ComporPostScreen extends ConsumerStatefulWidget {
  const ComporPostScreen({this.post, super.key});

  /// Nulo publica; preenchido edita.
  final Post? post;

  @override
  ConsumerState<ComporPostScreen> createState() => _ComporPostScreenState();
}

class _ComporPostScreenState extends ConsumerState<ComporPostScreen> {
  late final TextEditingController _conteudo;

  /// **`institucional` é o padrão do formulário, não do servidor.** O serviço
  /// exige o campo e não adivinha: um default do lado dele faria uma chamada
  /// malformada publicar com alcance que ninguém escolheu. Aqui a pré-seleção é
  /// legítima — é a escolha mais comum, e está à vista para ser trocada.
  late Visibilidade _visibilidade;
  String? _cursoId;

  String? _erroDeConteudo;
  String? _erroDeCurso;
  bool _enviando = false;

  bool get _editando => widget.post != null;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _conteudo = TextEditingController(text: post?.conteudo ?? '');
    _visibilidade = post?.visibilidade ?? Visibilidade.institucional;
    _cursoId = post?.curso?.id;
  }

  @override
  void dispose() {
    _conteudo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _conteudo.text.trim();

    setState(() {
      _erroDeConteudo = texto.isEmpty
          ? 'Escreva o comunicado antes de publicar'
          : null;
      _erroDeCurso = _visibilidade == Visibilidade.curso && _cursoId == null
          ? 'Escolha o curso a que o comunicado fica restrito'
          : null;
    });

    if (_erroDeConteudo != null || _erroDeCurso != null) return;

    setState(() => _enviando = true);
    try {
      final repo = ref.read(academicRepositoryProvider);
      if (_editando) {
        await repo.editar(
          widget.post!.id,
          conteudo: texto,
          visibilidade: _visibilidade,
          cursoId: _cursoId,
        );
      } else {
        await repo.publicar(
          conteudo: texto,
          visibilidade: _visibilidade,
          cursoId: _cursoId,
        );
      }

      // O feed é a tela que mostra o resultado, então é ela que recarrega. Sem
      // isto o comunicado só apareceria na próxima abertura do app.
      ref.invalidate(feedProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ShadToaster.of(context).show(
        ShadToast(
          description: Text(
            _editando ? 'Comunicado atualizado.' : 'Comunicado publicado.',
          ),
        ),
      );
    } on FalhaDeValidacao catch (falha) {
      // O serviço nomeia o campo; a tela pinta a linha certa em vez de um aviso
      // genérico no topo.
      setState(() {
        _erroDeConteudo = falha.campos['conteudo']?.first;
        _erroDeCurso = falha.campos['cursoId']?.first;
      });
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
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Scaffold(
      backgroundColor: cores.background,
      appBar: AppBar(
        title: Text(_editando ? 'Editar comunicado' : 'Novo comunicado'),
        backgroundColor: cores.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          Text('Comunicado', style: tema.textTheme.small),
          const SizedBox(height: Espaco.xs),
          ShadTextarea(
            controller: _conteudo,
            placeholder: const Text('O que a instituição precisa comunicar?'),
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
          const SizedBox(height: Espaco.lg),

          Text('Quem vê', style: tema.textTheme.small),
          const SizedBox(height: Espaco.xs),
          ShadSelect<Visibilidade>(
            initialValue: _visibilidade,
            onChanged: (valor) {
              if (valor == null) return;
              setState(() {
                _visibilidade = valor;
                // Sair de `curso` limpa a restrição: o serviço **recusa** um
                // `cursoId` em post que não é restrito, em vez de ignorá-lo — um
                // curso aceito em silêncio pareceria uma restrição que não existe.
                if (valor != Visibilidade.curso) _cursoId = null;
                _erroDeCurso = null;
              });
            },
            selectedOptionBuilder: (context, valor) => Text(valor.rotulo),
            options: [
              for (final v in Visibilidade.values)
                ShadOption(value: v, child: Text(v.rotulo)),
            ],
          ),
          const SizedBox(height: Espaco.xs),
          Text(_visibilidade.explicacao, style: tema.textTheme.muted),

          if (_visibilidade == Visibilidade.curso) ...[
            const SizedBox(height: Espaco.md),
            _SeletorDeCurso(
              cursoId: _cursoId,
              erro: _erroDeCurso,
              aoMudar: (id) => setState(() {
                _cursoId = id;
                _erroDeCurso = null;
              }),
            ),
          ],

          const SizedBox(height: Espaco.lg),
          _AvisoDeAlcance(visibilidade: _visibilidade, editando: _editando),
          const SizedBox(height: Espaco.lg),

          ShadButton(
            onPressed: _enviando ? null : _enviar,
            child: Text(
              _enviando
                  ? 'Enviando…'
                  : (_editando ? 'Salvar alterações' : 'Publicar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeletorDeCurso extends ConsumerWidget {
  const _SeletorDeCurso({
    required this.cursoId,
    required this.aoMudar,
    this.erro,
  });

  final String? cursoId;
  final String? erro;
  final ValueChanged<String?> aoMudar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final cursos = ref.watch(meusCursosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Curso', style: tema.textTheme.small),
        const SizedBox(height: Espaco.xs),
        switch (cursos) {
          AsyncError() => Text(
            'Não foi possível carregar seus cursos.',
            style: tema.textTheme.muted,
          ),
          AsyncLoading() => Text(
            'Carregando cursos…',
            style: tema.textTheme.muted,
          ),
          // Instituição sem curso cadastrado não tem como restringir nada, e a
          // tela diz para onde ir em vez de mostrar um combobox vazio.
          AsyncData(:final value) when value.isEmpty => Text(
            'Você ainda não cadastrou cursos. Cadastre em Perfil › '
            'Administração da instituição para poder restringir um comunicado.',
            style: tema.textTheme.muted,
          ),
          AsyncData(:final value) => _combo(value),
        },
        if (erro != null) ...[
          const SizedBox(height: Espaco.xs),
          Text(
            erro!,
            style: tema.textTheme.muted.copyWith(
              color: tema.colorScheme.destructive,
            ),
          ),
        ],
      ],
    );
  }

  Widget _combo(List<Curso> cursos) {
    final porId = {for (final c in cursos) c.id: c};

    return ShadSelect<String>(
      placeholder: const Text('Escolha o curso'),
      initialValue: cursoId,
      onChanged: aoMudar,
      selectedOptionBuilder: (context, valor) =>
          Text(porId[valor]?.nome ?? valor),
      options: [
        for (final c in cursos) ShadOption(value: c.id, child: Text(c.nome)),
      ],
    );
  }
}

/// O aviso que explica o que o alcance escolhido significa na prática.
///
/// Existe porque a escolha é consequente e irreversível para quem já leu: um
/// comunicado `publico` sai para fora da instituição, e um `curso` não chega a
/// quem só declarou aquela formação. O texto do combobox é curto por necessidade;
/// aqui cabe a frase inteira.
class _AvisoDeAlcance extends StatelessWidget {
  const _AvisoDeAlcance({required this.visibilidade, required this.editando});

  final Visibilidade visibilidade;
  final bool editando;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    final explicacao = switch (visibilidade) {
      Visibilidade.publico =>
        'Qualquer pessoa no Integra vê este comunicado, inclusive quem não '
            'segue a instituição — ele aparece no perfil dela.',
      Visibilidade.institucional =>
        'Só quem tem vínculo ativo com a sua instituição vê. Quem apenas '
            'declarou a formação no perfil, ou já se formou, não recebe.',
      Visibilidade.curso =>
        'Só quem tem vínculo ativo no curso escolhido vê. Alunos de outros '
            'cursos da sua instituição não recebem.',
    };

    return ShadAlert(
      icon: const Icon(LucideIcons.info),
      title: Text(visibilidade.rotulo),
      description: Text(
        editando
            ? '$explicacao\n\nEditar um comunicado publicado não avisa quem já o '
                  'leu, e mudar o alcance pode torná-lo visível a mais gente.'
            : explicacao,
        style: tema.textTheme.muted,
      ),
    );
  }
}
