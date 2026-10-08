import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';
import 'package:integra/features/jobs/presentation/jobs_providers.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// O filtro de vagas: um ícone no canto esquerdo do cabeçalho.
///
/// Substituiu a barra de etiquetas que ficava logo abaixo da barra de abas. A barra
/// escrevia o filtro em vigor, o que era a parte boa dela, e cobrava por isso uma
/// faixa permanente da tela — até duas linhas quando os quatro controles da empresa
/// não caíam numa. É o mesmo custo que tirou a barra de escopo do Acadêmico na
/// Sprint 2, e a mesma solução: o canto esquerdo do cabeçalho, que já é **o lugar do
/// controle da lista** nas duas telas de feed.
///
/// O que a barra dizia por escrito, o ícone diz por cor: fora do padrão ele ganha o
/// dourado do pilar. É o que impede alguém de ler uma lista filtrada como uma lista
/// vazia — e o que está ativo continua escrito, agora dentro do menu, onde a escolha
/// é feita.
class BotaoDeFiltroDeVagas extends ConsumerWidget {
  const BotaoDeFiltroDeVagas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ShadTheme.of(context).colorScheme;
    final filtro = ref.watch(filtroDeVagasProvider);
    final notifier = ref.read(filtroDeVagasProvider.notifier);
    final perfil = ref.watch(perfilAtualProvider);
    final ehEmpresa = perfil?.tipo == TipoConta.empresa;

    return MenuAnchor(
      builder: (context, controlador, _) => Tooltip(
        // Diz o filtro **em vigor**, e não só o nome do botão: com o texto fora da
        // tela, é a única forma de o leitor de tela e o hover contarem que a lista
        // está estreitada.
        message: 'Filtrar vagas: ${_resumo(filtro)}',
        child: ShadIconButton.ghost(
          icon: Icon(
            LucideIcons.listFilter,
            size: 20,
            color: filtro.ativo ? cores.profissional : cores.mutedForeground,
          ),
          onPressed: () =>
              controlador.isOpen ? controlador.close() : controlador.open(),
        ),
      ),
      menuChildren: [
        _Submenu<TipoDeVaga>(
          rotulo: 'Tipo',
          valor: filtro.tipo,
          opcoes: TipoDeVaga.values,
          nome: (t) => t.rotulo,
          aoTrocar: (t) => notifier.trocar(
            FiltroDeVagas(
              tipo: t,
              modalidade: filtro.modalidade,
              empresaId: filtro.empresaId,
              estado: filtro.estado,
            ),
          ),
        ),
        _Submenu<Modalidade>(
          rotulo: 'Modalidade',
          valor: filtro.modalidade,
          opcoes: Modalidade.values,
          nome: (m) => m.rotulo,
          aoTrocar: (m) => notifier.trocar(
            FiltroDeVagas(
              tipo: filtro.tipo,
              modalidade: m,
              empresaId: filtro.empresaId,
              estado: filtro.estado,
            ),
          ),
        ),

        // Só a empresa tem estas duas: "minhas vagas" e "encerradas" são as perguntas
        // de quem publica. Para o aluno, uma vaga encerrada é um beco — ele não pode
        // se candidatar —, e a dele em "minhas candidaturas" já mostra o estado da vaga.
        if (ehEmpresa) ...[
          _Alternar(
            rotulo: 'Minhas vagas',
            ativo: filtro.empresaId != null,
            aoTrocar: (ativo) => notifier.trocar(
              FiltroDeVagas(
                tipo: filtro.tipo,
                modalidade: filtro.modalidade,
                empresaId: ativo ? perfil!.id : null,
                estado: filtro.estado,
              ),
            ),
          ),
          _Alternar(
            rotulo: 'Encerradas',
            ativo: filtro.estado == EstadoDaVaga.fechada,
            aoTrocar: (ativo) => notifier.trocar(
              FiltroDeVagas(
                tipo: filtro.tipo,
                modalidade: filtro.modalidade,
                empresaId: filtro.empresaId,
                estado: ativo ? EstadoDaVaga.fechada : EstadoDaVaga.aberta,
              ),
            ),
          ),
        ],

        if (filtro.ativo)
          MenuItemButton(
            leadingIcon: Icon(
              LucideIcons.x,
              size: 16,
              color: cores.profissional,
            ),
            onPressed: notifier.limpar,
            child: const Text('Limpar filtros'),
          ),
      ],
    );
  }

  /// O filtro em vigor numa frase, para o tooltip e o leitor de tela.
  static String _resumo(FiltroDeVagas filtro) {
    if (!filtro.ativo) return 'todas as vagas abertas';
    return [
      if (filtro.tipo != null) filtro.tipo!.rotulo,
      if (filtro.modalidade != null) filtro.modalidade!.rotulo,
      if (filtro.estado == EstadoDaVaga.fechada) 'encerradas',
      if (filtro.empresaId != null) 'minhas vagas',
    ].join(' · ');
  }
}

/// Um filtro de valor único, com "Todos" como primeira opção.
///
/// "Todos" está na lista em vez de depender do botão de limpar: desfazer uma escolha
/// tem que estar no mesmo lugar onde ela foi feita, senão o usuário procura o
/// contrário do que acabou de tocar.
///
/// Um [SubmenuButton] e não um menu próprio: o valor escolhido aparece no rótulo do
/// pai, então quem abre o filtro lê o que está ativo sem ter que entrar em cada ramo.
class _Submenu<T> extends StatelessWidget {
  const _Submenu({
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.nome,
    required this.aoTrocar,
  });

  final String rotulo;
  final T? valor;
  final List<T> opcoes;
  final String Function(T) nome;
  final ValueChanged<T?> aoTrocar;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;
    final ativo = valor != null;

    return SubmenuButton(
      leadingIcon: Icon(
        LucideIcons.check,
        size: 16,
        color: ativo ? cores.profissional : Colors.transparent,
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () => aoTrocar(null),
          child: Text('Todos · $rotulo'),
        ),
        for (final opcao in opcoes)
          MenuItemButton(
            leadingIcon: Icon(
              LucideIcons.check,
              size: 14,
              color: opcao == valor ? cores.profissional : Colors.transparent,
            ),
            onPressed: () => aoTrocar(opcao),
            child: Text(nome(opcao)),
          ),
      ],
      child: Text(ativo ? '$rotulo · ${nome(valor as T)}' : rotulo),
    );
  }
}

class _Alternar extends StatelessWidget {
  const _Alternar({
    required this.rotulo,
    required this.ativo,
    required this.aoTrocar,
  });

  final String rotulo;
  final bool ativo;
  final ValueChanged<bool> aoTrocar;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return MenuItemButton(
      leadingIcon: Icon(
        ativo ? LucideIcons.checkCheck : LucideIcons.circle,
        size: 16,
        color: ativo ? cores.profissional : cores.mutedForeground,
      ),
      // `closeOnActivate: false`: os dois alternadores se combinam — "minhas vagas" e
      // "encerradas" juntos são a pergunta "o que eu já encerrei" —, e um menu que
      // fecha a cada toque obriga a reabri-lo para a segunda metade da pergunta.
      closeOnActivate: false,
      onPressed: () => aoTrocar(!ativo),
      child: Text(rotulo),
    );
  }
}
