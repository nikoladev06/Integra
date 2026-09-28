import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// O que a conta pode publicar. Aberta pelo botão central do rodapé.
///
/// É um **hub**, e não um atalho direto para o formulário, porque publicar vai ter
/// três destinos e hoje só um existe. O hub mostra os três, com os que faltam
/// desabilitados e datados — a tela não muda de forma na Sprint 5, e quem usa
/// aprende o que o produto tem sem ter que descobrir por tentativa.
///
/// Custa um toque a mais para a faculdade, que só tem uma opção disponível. É o
/// mesmo toque que ela vai dar quando houver três, e a alternativa — ir direto ao
/// formulário hoje e passar a mostrar o hub depois — mudaria o comportamento do
/// mesmo botão no meio do caminho.
///
/// **Cada opção declara o que a habilita, e a regra é a do servidor.** A faculdade
/// pendente vê a opção e o motivo de não poder usá-la; esconder deixaria a conta em
/// análise sem entender o que falta, e mostrar habilitado renderia 403 no envio.
class PublicarScreen extends ConsumerWidget {
  const PublicarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final perfil = ref.watch(perfilAtualProvider);

    final ehFaculdade = perfil?.tipo == TipoConta.faculdade;
    final ativada = perfil?.ativadaEm != null;

    return Scaffold(
      backgroundColor: cores.background,
      appBar: AppBar(
        // Mantém o título: é destino de toque, com botão de voltar, e o cabeçalho
        // sem texto é o das telas de navegação, onde a aba já diz onde se está.
        title: const Text('Publicar'),
        backgroundColor: cores.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          _Opcao(
            icone: LucideIcons.megaphone,
            cor: cores.academico,
            titulo: 'Comunicado da instituição',
            descricao:
                'Público, interno à instituição ou restrito a um curso. Só quem '
                'tem vínculo recebe os dois últimos.',
            // As duas condições são as mesmas que o serviço checa, e na mesma
            // ordem: tipo de conta pelo token, ativação pelo banco.
            impedimento: !ehFaculdade
                ? 'Só contas de faculdade publicam comunicados institucionais.'
                : !ativada
                ? 'Sua instituição está em análise. Quando for ativada, você '
                      'publica por aqui.'
                : null,
            aoTocar: () => context.push(Rotas.comporPost),
          ),
          _Opcao(
            icone: LucideIcons.messageSquare,
            cor: cores.profissional,
            titulo: 'Post no feed profissional',
            descricao: 'Para conversar com outros alunos e com empresas.',
            impedimento:
                'O feed profissional entra na Sprint 5, junto do serviço que '
                'guarda os posts.',
            aoTocar: null,
          ),
          _Opcao(
            icone: LucideIcons.briefcase,
            cor: cores.profissional,
            titulo: 'Vaga',
            descricao: 'Publicada por empresa, com candidatura dos alunos.',
            impedimento:
                'A área de vagas entra na Sprint 5. Vaga e post têm ciclos de '
                'vida diferentes, então são serviços separados.',
            aoTocar: null,
          ),
        ],
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.descricao,
    required this.impedimento,
    required this.aoTocar,
  });

  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;

  /// Por que esta opção não está disponível. Nulo significa disponível.
  ///
  /// Uma frase em vez de um booleano: "indisponível" sem motivo manda o usuário
  /// adivinhar, e os motivos aqui são três coisas diferentes — tipo de conta
  /// errado, conta em análise, e serviço que não existe.
  final String? impedimento;

  final VoidCallback? aoTocar;

  bool get _disponivel => impedimento == null;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final tinta = _disponivel ? cor : cores.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.md),
      child: Opacity(
        // Esmaecido, e não escondido: a opção indisponível informa o que o produto
        // vai ter, e o texto abaixo diz quando.
        opacity: _disponivel ? 1 : 0.6,
        child: ShadCard(
          padding: const EdgeInsets.all(Espaco.md),
          child: InkWell(
            onTap: _disponivel ? aoTocar : null,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tinta.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icone, size: 20, color: tinta),
                ),
                const SizedBox(width: Espaco.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: tema.textTheme.small),
                      const SizedBox(height: Espaco.xs),
                      Text(descricao, style: tema.textTheme.muted),
                      if (!_disponivel) ...[
                        const SizedBox(height: Espaco.xs),
                        Text(
                          impedimento!,
                          style: tema.textTheme.muted.copyWith(color: tinta),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_disponivel)
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: cores.mutedForeground,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
