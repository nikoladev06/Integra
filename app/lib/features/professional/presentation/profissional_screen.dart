import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

// `cores.profissional` vem da extensão `IntegraColorScheme` daqui.
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/academic/presentation/widgets/botao_de_escopo.dart';
import 'package:integra/shared/widgets/cabecalho_integra.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// O escopo escolhido na aba de feed e vagas.
///
/// Guardado num provider desde já, mesmo sem serviço para consumi-lo: é o que faz o
/// botão do cabeçalho ser um controle de verdade — a escolha persiste ao trocar de
/// aba e o vazio a repete — em vez de um menu que abre e não muda nada.
final escopoDoProfissionalProvider =
    NotifierProvider<EscopoDoProfissionalNotifier, EscopoDoProfissional>(
      EscopoDoProfissionalNotifier.new,
    );

class EscopoDoProfissionalNotifier extends Notifier<EscopoDoProfissional> {
  @override
  EscopoDoProfissional build() => EscopoDoProfissional.geral;

  void trocar(EscopoDoProfissional escopo) => state = escopo;
}

/// Pilar Profissional — feed entre alunos e vagas de empresas.
///
/// Segue **vazia de conteúdo**, e de propósito: o `feed-service` e o `jobs-service`
/// só entram na Sprint 5, e preenchê-la com posts falsos esconderia o que falta.
///
/// O que ela já tem é o cabeçalho completo, botão de escopo incluído. O escopo aqui
/// filtra por **quem publica** — geral, só empresas, só pessoas —, e não por
/// instituição como no Acadêmico: no profissional não existe vínculo a consultar, e
/// o que distingue um post de outro é o tipo de conta que o escreveu.
///
/// O vazio repete a escolha em vez de ignorá-la. É a diferença entre um controle e
/// uma decoração: o usuário vê que mexer no botão mudou algo, e sabe o que esperar
/// quando o serviço entrar.
class ProfissionalScreen extends ConsumerWidget {
  const ProfissionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ShadTheme.of(context).colorScheme;
    final escopo = ref.watch(escopoDoProfissionalProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CabecalhoIntegra(
            escopo: BotaoDeEscopo<EscopoDoProfissional>(
              opcoes: EscopoDoProfissional.values,
              selecionado: escopo,
              padrao: EscopoDoProfissional.geral,
              rotulo: (e) => e.rotulo,
              descricao: (e) => e.descricao,
              cor: cores.profissional,
              aoTrocar: (e) =>
                  ref.read(escopoDoProfissionalProvider.notifier).trocar(e),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoVazio(
              icone: switch (escopo) {
                EscopoDoProfissional.empresas => LucideIcons.building2,
                EscopoDoProfissional.pessoas => LucideIcons.users,
                EscopoDoProfissional.geral => LucideIcons.briefcase,
              },
              cor: cores.profissional,
              titulo: 'Feed e vagas chegam na Sprint 5',
              descricao:
                  '${escopo.descricao}. '
                  'O feed entre alunos e a área de vagas publicadas por empresas '
                  'são serviços separados: um post e uma vaga têm ciclos de vida '
                  'diferentes, e o protótipo os tratava como a mesma coisa.',
            ),
          ),
        ],
      ),
    );
  }
}
