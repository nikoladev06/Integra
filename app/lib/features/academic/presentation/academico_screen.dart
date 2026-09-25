import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/shared/widgets/cabecalho_integra.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// Pilar Acadêmico — posts institucionais, gerais ou restritos por curso.
///
/// A tela existe desde a Sprint 2 para a navegação estar completa, e mostra um
/// vazio honesto em vez de conteúdo inventado: o `academic-service` só entra na
/// Sprint 4, e preencher isso com dados falsos esconderia o que falta.
///
/// O que ela já sabe é **de quem** os comunicados viriam, e essa resposta vem do
/// vínculo — nunca da formação declarada. Quem só declarou não recebe nada, e a
/// tela diz isso em vez de prometer o feed de uma instituição que não confirmou
/// a matrícula.
class AcademicoScreen extends ConsumerWidget {
  const AcademicoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ShadTheme.of(context).colorScheme;
    final vinculo = ref.watch(perfilAtualProvider)?.vinculo;

    return Scaffold(
      appBar: const CabecalhoIntegra(titulo: 'Acadêmico'),
      body: EstadoVazio(
        icone: LucideIcons.graduationCap,
        cor: cores.academico,
        titulo: vinculo == null
            ? 'Você ainda não tem vínculo'
            : 'Nada publicado pela ${vinculo.universidade.sigla} ainda',
        descricao: vinculo == null
            ? 'Os comunicados internos de uma instituição só aparecem para quem '
                  'tem vínculo com ela. Busque sua faculdade e informe seu CPF '
                  'no menu do perfil dela para criar o seu.'
            : 'Aqui vão aparecer os comunicados da sua faculdade — os gerais e '
                  'os restritos ao seu curso. O serviço que os publica entra na '
                  'Sprint 4.',
      ),
    );
  }
}
