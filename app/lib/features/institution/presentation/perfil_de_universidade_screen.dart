import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/domain/auth_validators.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/institution/presentation/instituicoes_providers.dart';
import 'package:integra/features/profile/data/models/instituicao.dart';

/// O perfil público de uma universidade, alcançado pela busca.
///
/// É a tela onde o vínculo nasce. O menu do canto superior direito oferece
/// **"inserir CPF"** para quem não tem vínculo com esta instituição, e
/// **"encerrar vínculo"** para quem tem — a decisão vem de `temVinculo`, que o
/// serviço calcula para o leitor, em vez de a tela cruzar duas respostas.
///
/// Enquanto não há vínculo, o que se vê aqui são só os posts públicos. É a
/// consequência visível da regra: formação declarada, e mesmo formação
/// verificada antiga, não abrem os comunicados internos.
class PerfilDeUniversidadeScreen extends ConsumerWidget {
  const PerfilDeUniversidadeScreen({required this.universidadeId, super.key});

  final String universidadeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final perfil = ref.watch(perfilDeUniversidadeProvider(universidadeId));

    return Scaffold(
      backgroundColor: tema.colorScheme.background,
      appBar: AppBar(
        title: const Text('Instituição'),
        backgroundColor: tema.colorScheme.card,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (perfil.hasValue)
            _MenuDaInstituicao(
              universidade: perfil.requireValue,
              aoConcluir: () =>
                  ref.invalidate(perfilDeUniversidadeProvider(universidadeId)),
            ),
        ],
      ),
      body: switch (perfil) {
        AsyncError(:final error) => _Erro(
          mensagem: error is Failure
              ? error.mensagem
              : 'Não foi possível carregar esta instituição.',
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncData(:final value) => _Conteudo(universidade: value),
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
  const _Conteudo({required this.universidade});

  final PerfilDeUniversidade universidade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(Espaco.md),
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cores.academico.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.school,
                color: cores.academico,
                size: 24,
              ),
            ),
            const SizedBox(width: Espaco.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(universidade.sigla, style: tema.textTheme.h4),
                  Text(universidade.nome, style: tema.textTheme.muted),
                ],
              ),
            ),
          ],
        ),
        if (universidade.bio != null) ...[
          const SizedBox(height: Espaco.md),
          Text(universidade.bio!, style: tema.textTheme.p),
        ],
        const SizedBox(height: Espaco.md),

        Wrap(
          spacing: Espaco.sm,
          runSpacing: Espaco.sm,
          children: [
            // Agregado, sem expor quem: o número conta quantos têm vínculo
            // ativo, e não lista ninguém.
            ShadBadge.secondary(
              child: Text('${universidade.totalDeAlunos} com vínculo'),
            ),
            if (universidade.temVinculo)
              const ShadBadge(child: Text('Você tem vínculo aqui')),
          ],
        ),
        const SizedBox(height: Espaco.md),

        _BotaoDeSeguir(universidade: universidade),
        const SizedBox(height: Espaco.lg),

        ShadCard(
          title: const Text('Comunicados'),
          child: Padding(
            padding: const EdgeInsets.only(top: Espaco.sm),
            child: Text(
              universidade.temVinculo
                  ? 'Com vínculo ativo, você verá aqui os comunicados gerais e '
                        'os restritos ao seu curso. O serviço que os publica '
                        'entra na Sprint 4.'
                  : 'Sem vínculo, só os comunicados públicos aparecem aqui. '
                        'Declarar a formação no perfil não muda isso — informe '
                        'o CPF pelo menu para criar o vínculo.',
              style: tema.textTheme.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _BotaoDeSeguir extends ConsumerStatefulWidget {
  const _BotaoDeSeguir({required this.universidade});

  final PerfilDeUniversidade universidade;

  @override
  ConsumerState<_BotaoDeSeguir> createState() => _BotaoDeSeguirState();
}

class _BotaoDeSeguirState extends ConsumerState<_BotaoDeSeguir> {
  bool _ocupado = false;

  Future<void> _alternar() async {
    setState(() => _ocupado = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .seguirUniversidade(
            widget.universidade.id,
            seguir: !widget.universidade.seguindo,
          );
      ref.invalidate(perfilDeUniversidadeProvider(widget.universidade.id));
    } on Failure catch (falha) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text(falha.mensagem)),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seguindo = widget.universidade.seguindo;

    // Seguir **não** concede acesso a conteúdo restrito: é registro de
    // interesse, e alimenta o escopo "geral" do feed. Quem confunde as duas
    // coisas é exatamente quem o modelo v2 existe para desconfundir.
    return seguindo
        ? ShadButton.outline(
            leading: const Icon(LucideIcons.check, size: 16),
            onPressed: _ocupado ? null : _alternar,
            child: const Text('Seguindo'),
          )
        : ShadButton(
            leading: const Icon(LucideIcons.plus, size: 16),
            onPressed: _ocupado ? null : _alternar,
            child: const Text('Seguir'),
          );
  }
}

/// O menu hamburguer do canto superior direito.
class _MenuDaInstituicao extends ConsumerWidget {
  const _MenuDaInstituicao({
    required this.universidade,
    required this.aoConcluir,
  });

  final PerfilDeUniversidade universidade;
  final VoidCallback aoConcluir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      builder: (context, controlador, _) => IconButton(
        icon: const Icon(LucideIcons.menu),
        tooltip: 'Opções da instituição',
        onPressed: () =>
            controlador.isOpen ? controlador.close() : controlador.open(),
      ),
      menuChildren: [
        if (universidade.temVinculo)
          MenuItemButton(
            leadingIcon: const Icon(LucideIcons.unlink, size: 16),
            onPressed: () => _encerrar(context, ref),
            child: const Text('Encerrar vínculo'),
          )
        else
          MenuItemButton(
            leadingIcon: const Icon(LucideIcons.idCard, size: 16),
            onPressed: () => _inserirCpf(context, ref),
            child: const Text('Inserir CPF'),
          ),
      ],
    );
  }

  Future<void> _encerrar(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(profileRepositoryProvider);
    try {
      await repo.encerrarVinculo();
      ref.read(sessaoProvider.notifier).atualizarPerfil(await repo.meuPerfil());
      aoConcluir();
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text(
              'Vínculo encerrado. Sua formação continua verificada.',
            ),
          ),
        );
      }
    } on Failure catch (falha) {
      if (context.mounted) {
        ShadToaster.of(
          context,
        ).show(ShadToast.destructive(description: Text(falha.mensagem)));
      }
    }
  }

  Future<void> _inserirCpf(BuildContext context, WidgetRef ref) async {
    final cpf = await showShadDialog<String>(
      context: context,
      builder: (_) => _DialogoDeCpf(sigla: universidade.sigla),
    );
    if (cpf == null || !context.mounted) return;

    final repo = ref.read(profileRepositoryProvider);
    try {
      await repo.criarVinculo(universidadeId: universidade.id, cpf: cpf);
      // O vínculo muda o perfil — ele entra em `vinculo` e estampa o selo na
      // formação correspondente —, então a sessão precisa do perfil novo.
      ref.read(sessaoProvider.notifier).atualizarPerfil(await repo.meuPerfil());
      aoConcluir();
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text(
              'Vínculo criado. Sua formação nesta instituição agora tem selo.',
            ),
          ),
        );
      }
    } on Failure catch (falha) {
      if (context.mounted) {
        // 403 e 404 chegam aqui com a **mesma mensagem**, de propósito: a
        // diferença de status serve a quem depura, não a quem quisesse usar a
        // rota como sonda da lista de matrículas da instituição.
        ShadToaster.of(
          context,
        ).show(ShadToast.destructive(description: Text(falha.mensagem)));
      }
    }
  }
}

class _DialogoDeCpf extends StatefulWidget {
  const _DialogoDeCpf({required this.sigla});

  final String sigla;

  @override
  State<_DialogoDeCpf> createState() => _DialogoDeCpfState();
}

class _DialogoDeCpfState extends State<_DialogoDeCpf> {
  final _controlador = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _confirmar() {
    final erro = validarCpf(_controlador.text);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop(_controlador.text);
  }

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return ShadDialog(
      title: const Text('Inserir CPF'),
      description: Text(
        'Informe o CPF da sua própria conta. Se ele constar na lista de alunos '
        'da ${widget.sigla}, o vínculo é criado.',
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ShadButton(onPressed: _confirmar, child: const Text('Confirmar')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espaco.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShadInput(
              controller: _controlador,
              placeholder: const Text('000.000.000-00'),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _confirmar(),
            ),
            if (_erro != null) ...[
              const SizedBox(height: Espaco.xs),
              Text(
                _erro!,
                style: tema.textTheme.muted.copyWith(
                  color: tema.colorScheme.destructive,
                ),
              ),
            ],
            const SizedBox(height: Espaco.sm),
            Text(
              'Só o CPF da própria conta é aceito. O de outra pessoa é '
              'recusado antes mesmo de ser procurado na lista — CPF circula '
              'por aí, e sem essa conferência ele viraria senha de acesso aos '
              'comunicados internos da instituição.',
              style: tema.textTheme.muted,
            ),
          ],
        ),
      ),
    );
  }
}
