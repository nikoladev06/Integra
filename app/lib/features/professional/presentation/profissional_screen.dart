import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/tokens.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// Pilar Profissional — feed entre alunos e área de vagas.
class ProfissionalScreen extends ConsumerWidget {
  const ProfissionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ShadTheme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profissional'),
        backgroundColor: cores.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: EstadoVazio(
        icone: LucideIcons.briefcase,
        cor: cores.profissional,
        titulo: 'Feed e vagas chegam na Sprint 5',
        descricao:
            'O feed entre alunos e a área de vagas publicadas por empresas são '
            'serviços separados: um post e uma vaga têm ciclos de vida '
            'diferentes, e o protótipo os tratava como a mesma coisa.',
      ),
    );
  }
}
