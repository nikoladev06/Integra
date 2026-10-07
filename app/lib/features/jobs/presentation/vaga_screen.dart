import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';
import 'package:integra/features/jobs/presentation/compor_vaga_screen.dart';
import 'package:integra/features/jobs/presentation/jobs_providers.dart';
import 'package:integra/features/jobs/presentation/widgets/lista_de_candidaturas.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/shared/domain/tempo.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// O detalhe de uma vaga. **É aqui que o portão da Sprint 5 se fecha do lado do app.**
///
/// A mesma tela serve aos dois lados, e mostra coisas diferentes porque as perguntas
/// são diferentes:
///
/// - **aluno**: a descrição inteira e o botão de candidatar-se, com o estado da própria
///   candidatura quando já existe;
/// - **empresa autora**: a descrição, os botões de editar e encerrar, e **a lista de
///   quem se candidatou** — com o botão de marcar como visualizada.
///
/// Duas telas para isso teriam que repetir o corpo da vaga, e a versão de cada lado
/// divergiria no primeiro campo novo.
///
/// ## Por que o botão de candidatar-se está aqui e não na lista
///
/// É uma ação com consequência — a empresa passa a ver o nome de quem se candidatou —
/// e um botão de um toque numa lista rolável é o jeito de alguém se candidatar sem ter
/// lido a descrição. O card leva até aqui; o botão fica onde o texto está.
class VagaScreen extends ConsumerStatefulWidget {
  const VagaScreen({required this.vagaId, super.key});

  final String vagaId;

  @override
  ConsumerState<VagaScreen> createState() => _VagaScreenState();
}

class _VagaScreenState extends ConsumerState<VagaScreen> {
  bool _ocupado = false;

  Future<void> _candidatar(Vaga vaga) async {
    setState(() => _ocupado = true);
    try {
      final resultado = await ref
          .read(jobsRepositoryProvider)
          .candidatar(vaga.id);

      ref.invalidate(vagaProvider(vaga.id));
      ref.invalidate(minhasCandidaturasProvider);
      // A lista da aba precisa saber: `candidaturaEnviada` e o total mudaram, e a vaga
      // já está na tela de trás.
      ref.read(vagasProvider.notifier).substituir(resultado.candidatura.vaga);

      if (!mounted) return;
      // **Confirma só quando criou.** O 200 do contrato — "já havia candidatura" — não
      // gera aviso: avisar duas vezes faz o usuário achar que se candidatou duas vezes.
      if (resultado.criada) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text(
              'Candidatura enviada. Você acompanha o estado dela na aba de '
              'candidaturas.',
            ),
          ),
        );
      }
    } on Failure catch (falha) {
      // Vaga fechada chega aqui como 409 com mensagem própria — não há campo a
      // corrigir, então ela vai para o aviso e não para um erro de formulário.
      _avisar(falha.mensagem, erro: true);
      // Recarrega: se a vaga fechou entre a listagem e o toque, a tela estava
      // desatualizada e o estado novo é a informação útil.
      ref.invalidate(vagaProvider(vaga.id));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _marcarVisualizada(String candidaturaId) async {
    try {
      await ref.read(jobsRepositoryProvider).marcarVisualizada(candidaturaId);
      ref.invalidate(candidaturasDaVagaProvider(widget.vagaId));
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
    final vaga = ref.watch(vagaProvider(widget.vagaId));
    final perfil = ref.watch(perfilAtualProvider);

    return Scaffold(
      backgroundColor: cores.background,
      appBar: AppBar(
        title: const Text('Vaga'),
        backgroundColor: cores.card,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (vaga.value?.podeEditar ?? false)
            ShadIconButton.ghost(
              icon: const Icon(LucideIcons.pencil, size: 18),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ComporVagaScreen(vaga: vaga.value),
                ),
              ),
            ),
        ],
      ),
      body: switch (vaga) {
        AsyncError(:final error) => _Erro(
          mensagem: error is Failure
              ? error.mensagem
              : 'Não foi possível carregar a vaga.',
          aoTentarDeNovo: () => ref.invalidate(vagaProvider(widget.vagaId)),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncData(:final value) => _Corpo(
          vaga: value,
          ehAluno: perfil?.tipo == TipoConta.aluno,
          ocupado: _ocupado,
          aoCandidatar: () => _candidatar(value),
          aoMarcarVisualizada: _marcarVisualizada,
        ),
      },
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo({
    required this.vaga,
    required this.ehAluno,
    required this.ocupado,
    required this.aoCandidatar,
    required this.aoMarcarVisualizada,
  });

  final Vaga vaga;
  final bool ehAluno;
  final bool ocupado;
  final VoidCallback aoCandidatar;
  final void Function(String candidaturaId) aoMarcarVisualizada;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(Espaco.md),
      children: [
        Text(vaga.titulo, style: tema.textTheme.h3),
        const SizedBox(height: Espaco.xs),
        Text(
          '${vaga.empresa.nome} · @${vaga.empresa.username} · '
          '${quando(vaga.criadoEm)}${vaga.editada ? ' · editada' : ''}',
          style: tema.textTheme.muted,
        ),
        const SizedBox(height: Espaco.md),

        Wrap(
          spacing: Espaco.sm,
          runSpacing: Espaco.xs,
          children: [
            ShadBadge.secondary(child: Text(vaga.tipo.rotulo)),
            ShadBadge.outline(child: Text(vaga.ondeE)),
            if (!vaga.aberta)
              const ShadBadge.destructive(child: Text('Encerrada')),
            ShadBadge.outline(
              child: Text('${vaga.totalDeCandidaturas} candidatura(s)'),
            ),
          ],
        ),
        const SizedBox(height: Espaco.md),

        Text(vaga.descricao, style: tema.textTheme.p),
        const SizedBox(height: Espaco.lg),

        _Acao(
          vaga: vaga,
          ehAluno: ehAluno,
          ocupado: ocupado,
          aoCandidatar: aoCandidatar,
        ),

        if (vaga.podeEditar) ...[
          const SizedBox(height: Espaco.lg),
          Divider(color: cores.border, height: 1),
          const SizedBox(height: Espaco.md),
          Text('Quem se candidatou', style: tema.textTheme.h4),
          const SizedBox(height: Espaco.xs),
          Text(
            // A frase carrega a decisão do contrato: a empresa vê o mesmo resumo de
            // qualquer card, e o resto está no perfil público — a candidatura não é um
            // canal para dado que o perfil esconde.
            'Você vê o nome, a arroba e a foto de cada pessoa. Para o currículo, '
            'abra o perfil dela — ele é público.',
            style: tema.textTheme.muted,
          ),
          const SizedBox(height: Espaco.md),
          _Candidaturas(
            vagaId: vaga.id,
            aoMarcarVisualizada: aoMarcarVisualizada,
          ),
        ],
      ],
    );
  }
}

/// O que cada lado pode fazer, em quatro casos.
///
/// Cada um tem uma resposta diferente na tela, e é por isso que o modelo expõe
/// `candidaturaEnviada` como `bool?` em vez de `bool`: nulo significa "não se aplica",
/// que é diferente de "não se candidatou".
class _Acao extends StatelessWidget {
  const _Acao({
    required this.vaga,
    required this.ehAluno,
    required this.ocupado,
    required this.aoCandidatar,
  });

  final Vaga vaga;
  final bool ehAluno;
  final bool ocupado;
  final VoidCallback aoCandidatar;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    // A empresa autora não se candidata à própria vaga, e as ações dela estão no
    // cabeçalho e na seção de candidaturas.
    if (vaga.podeEditar) return const SizedBox.shrink();

    if (!ehAluno) {
      return ShadAlert(
        icon: const Icon(LucideIcons.info),
        title: const Text('Só alunos se candidatam'),
        description: const Text(
          'Candidatura é de conta de aluno. Contas de empresa e de instituição '
          'leem a vaga, mas não se candidatam.',
        ),
      );
    }

    if (vaga.candidaturaEnviada == true) {
      return ShadAlert(
        icon: const Icon(LucideIcons.check),
        title: const Text('Candidatura enviada'),
        description: const Text(
          'Acompanhe o estado dela na aba de candidaturas — você vê quando a '
          'empresa abrir a sua.',
        ),
      );
    }

    if (!vaga.aberta) {
      return ShadAlert.destructive(
        icon: const Icon(LucideIcons.circleSlash),
        title: const Text('Vaga encerrada'),
        description: const Text(
          'A empresa encerrou o processo, e esta vaga não recebe candidaturas '
          'novas.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadButton(
          onPressed: ocupado ? null : aoCandidatar,
          leading: ocupado
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.send, size: 16),
          child: Text(ocupado ? 'Enviando…' : 'Candidatar-se'),
        ),
        const SizedBox(height: Espaco.xs),
        Text(
          'A empresa passa a ver seu nome, sua arroba e sua foto. Não há como '
          'desfazer uma candidatura.',
          style: tema.textTheme.muted.copyWith(color: cores.mutedForeground),
        ),
      ],
    );
  }
}

class _Candidaturas extends ConsumerWidget {
  const _Candidaturas({required this.vagaId, required this.aoMarcarVisualizada});

  final String vagaId;
  final void Function(String candidaturaId) aoMarcarVisualizada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final candidaturas = ref.watch(candidaturasDaVagaProvider(vagaId));

    return switch (candidaturas) {
      AsyncError() => Text(
        'Não foi possível carregar as candidaturas.',
        style: tema.textTheme.muted,
      ),
      AsyncLoading() => const Padding(
        padding: EdgeInsets.all(Espaco.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      AsyncData(:final value) when value.itens.isEmpty => Text(
        'Ninguém se candidatou ainda.',
        style: tema.textTheme.muted,
      ),
      AsyncData(:final value) => Column(
        children: [
          for (final candidatura in value.itens)
            CandidaturaCard(
              candidatura: candidatura,
              // Do lado da empresa o assunto é **quem** se candidatou: ela já sabe de
              // que vaga se trata, porque está dentro dela.
              mostrarCandidato: true,
              aoMarcarVisualizada: () => aoMarcarVisualizada(candidatura.id),
            ),
        ],
      ),
    };
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
