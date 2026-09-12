import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// Pilar Acadêmico — posts institucionais, gerais ou restritos por curso.
///
/// A tela existe desde a Sprint 2 para a navegação estar completa, e mostra um
/// vazio honesto em vez de conteúdo inventado: o `academic-service` só entra na
/// Sprint 4, e preencher isso com dados falsos esconderia o que falta.
class AcademicoScreen extends ConsumerWidget {
  const AcademicoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ShadTheme.of(context).colorScheme;
    final perfil = ref.watch(perfilAtualProvider);
    final instituicao = perfil?.afiliacao.universidade.sigla;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acadêmico'),
        backgroundColor: cores.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: EstadoVazio(
        icone: LucideIcons.graduationCap,
        cor: cores.academico,
        titulo: instituicao == null
            ? 'Nada publicado ainda'
            : 'Nada publicado pela $instituicao ainda',
        descricao:
            'Aqui vão aparecer os comunicados da sua faculdade — os gerais e os '
            'restritos ao seu curso. O serviço que os publica entra na Sprint 4.',
      ),
    );
  }
}
