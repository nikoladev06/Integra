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
/// É um **hub**, e não um atalho direto para o formulário: publicar tem destinos
/// diferentes por tipo de conta, e o mesmo botão do rodapé levando a formulários
/// diferentes seria um botão que ninguém aprende.
///
/// ## Esconder ou esmaecer, e a diferença entre as duas recusas
///
/// A tela mostrava as três opções para todas as contas, com um motivo escrito nas
/// indisponíveis. Isso tratava duas recusas muito diferentes como se fossem uma:
///
/// - **"não é para este tipo de conta"** é permanente. Um aluno nunca vai publicar
///   comunicado institucional, e uma faculdade nunca vai abrir vaga. A opção
///   esmaecida não informava nada que a conta possa usar — ocupava um terço da tela
///   para dizer "isto não é seu". Agora ela **não aparece**.
/// - **"ainda não"** é temporário, e continua esmaecida com o motivo. A conta
///   institucional pendente vê a opção e lê que está em análise; esconder deixaria
///   ela sem entender o que falta, e habilitar renderia 403 no envio.
///
/// O post profissional é a exceção que fica à vista para todas: a faculdade o vê
/// esmaecido porque o que ela publica é comunicado, no pilar Acadêmico — e esse
/// motivo é sobre **onde** a coisa mora, não sobre a conta não servir.
///
/// A ativação é checada na mesma ordem do servidor: tipo primeiro, estado depois.
class PublicarScreen extends ConsumerWidget {
  const PublicarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final perfil = ref.watch(perfilAtualProvider);

    final ehFaculdade = perfil?.tipo == TipoConta.faculdade;
    final ehEmpresa = perfil?.tipo == TipoConta.empresa;
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
          // Só a faculdade. O aluno e a empresa não têm instituição para comunicar
          // nada em nome de, e a opção esmaecida só lhes dizia "isto não é seu".
          if (ehFaculdade)
            _Opcao(
              icone: LucideIcons.megaphone,
              cor: cores.academico,
              titulo: 'Comunicado da instituição',
              descricao:
                  'Público, interno à instituição ou restrito a um curso. Só '
                  'quem tem vínculo recebe os dois últimos.',
              impedimento: ativada
                  ? null
                  : 'Sua instituição está em análise. Quando for ativada, você '
                        'publica por aqui.',
              aoTocar: () => context.push(Rotas.comporPost),
            ),
          _Opcao(
            icone: LucideIcons.messageSquare,
            cor: cores.profissional,
            titulo: 'Post no feed profissional',
            descricao:
                'Para conversar com outros alunos e com empresas. Sem alcance '
                'restrito: qualquer pessoa no Integra pode abrir.',
            // Aluno e empresa publicam; faculdade não. Comunicado de instituição é o
            // pilar Acadêmico, e a mesma coisa em dois lugares seria lida duas vezes.
            impedimento: ehFaculdade
                ? 'Contas de instituição publicam comunicados no pilar '
                      'Acadêmico, não no Profissional.'
                : !ativada
                ? 'Sua conta está em análise. Quando for ativada, você publica '
                      'por aqui.'
                : null,
            aoTocar: () => context.push(Rotas.comporPostProfissional),
          ),
          // Só a empresa. Quem se candidata é aluno, e faculdade não contrata pelo
          // Integra — nenhum dos dois tem o que fazer com um formulário de vaga.
          if (ehEmpresa)
            _Opcao(
              icone: LucideIcons.briefcase,
              cor: cores.profissional,
              titulo: 'Vaga',
              descricao:
                  'Estágio, júnior ou trainee, com candidatura dos alunos e o '
                  'estado de cada uma.',
              impedimento: ativada
                  ? null
                  : 'Sua empresa está em análise. Quando for ativada, você '
                        'publica vagas por aqui.',
              aoTocar: () => context.push(Rotas.comporVaga),
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
  /// adivinhar, e os dois motivos que sobraram dizem coisas diferentes — **conta em
  /// análise**, que passa, e **pilar errado**, que explica onde a coisa mora. O
  /// terceiro, "não é para este tipo de conta", deixou de ser um impedimento: a
  /// opção não aparece.
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
        // Esmaecido, e não escondido: o que chega aqui indisponível é "ainda não" ou
        // "noutro pilar", e as duas são informação útil. O "não é para você" não
        // chega — a opção nem é construída.
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
