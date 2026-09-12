import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// Perfil do usuário autenticado.
///
/// É a tela que **prova a costura ponta a ponta** nesta sprint: os dados vêm do
/// `ProfileRepository`, que hoje é o falso sobre fixtures e amanhã é o
/// `ApiProfileRepository` contra o `user-service`. Esta tela não muda na troca.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final perfil = ref.watch(perfilAtualProvider);

    if (perfil == null) {
      // O roteador já impede chegar aqui sem sessão; isto cobre o instante
      // entre o logout e a troca de rota.
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: cores.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          _Cabecalho(perfil: perfil),
          const SizedBox(height: Espaco.md),
          _CartaoDeAfiliacao(afiliacao: perfil.afiliacao),
          const SizedBox(height: Espaco.md),
          _CartaoDeContato(perfil: perfil),
          const SizedBox(height: Espaco.lg),
          ShadButton.outline(
            leading: const Icon(LucideIcons.logOut, size: 16),
            onPressed: () => ref.read(sessaoProvider.notifier).sair(),
            child: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cores.academico.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          // `fotoUrl` existe no modelo mas nunca foi implementado no protótipo:
          // o campo era sempre string vazia. O upload entra na Sprint 5, e até
          // então as iniciais são o avatar.
          child: Text(
            perfil.iniciais,
            style: tema.textTheme.large.copyWith(color: cores.academico),
          ),
        ),
        const SizedBox(width: Espaco.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(perfil.nomeCompleto, style: tema.textTheme.h4),
              Text('@${perfil.username}', style: tema.textTheme.muted),
              const SizedBox(height: Espaco.xs),
              ShadBadge.secondary(child: Text(perfil.tipo.rotulo)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartaoDeAfiliacao extends StatelessWidget {
  const _CartaoDeAfiliacao({required this.afiliacao});

  final Afiliacao afiliacao;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return ShadCard(
      title: const Text('Vínculo institucional'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Espaco.sm),
          _Linha(
            rotulo: 'Universidade',
            valor:
                '${afiliacao.universidade.sigla} — ${afiliacao.universidade.nome}',
          ),
          _Linha(rotulo: 'Curso', valor: afiliacao.curso.nome),
          const SizedBox(height: Espaco.sm),
          Text(
            'No protótipo estes dois campos eram texto livre, o que impedia '
            'filtrar posts por curso. Agora são entidades com identificador.',
            style: tema.textTheme.muted,
          ),
        ],
      ),
    );
  }
}

class _CartaoDeContato extends StatelessWidget {
  const _CartaoDeContato({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      title: const Text('Contato'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Espaco.sm),
          // Só o próprio perfil traz contato; o público omite, por contrato.
          _Linha(rotulo: 'E-mail', valor: perfil.email ?? 'não disponível'),
          _Linha(rotulo: 'Telefone', valor: perfil.telefone ?? 'não disponível'),
          if (perfil.bio != null) _Linha(rotulo: 'Bio', valor: perfil.bio!),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(rotulo, style: tema.textTheme.muted),
          ),
          Expanded(child: Text(valor, style: tema.textTheme.small)),
        ],
      ),
    );
  }
}
