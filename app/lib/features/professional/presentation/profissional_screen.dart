import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/academic/presentation/widgets/botao_de_escopo.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/jobs/presentation/widgets/botao_de_filtro_de_vagas.dart';
import 'package:integra/features/jobs/presentation/widgets/lista_de_candidaturas.dart';
import 'package:integra/features/jobs/presentation/widgets/lista_de_vagas.dart';
import 'package:integra/features/professional/presentation/profissional_providers.dart';
import 'package:integra/features/professional/presentation/widgets/post_profissional_card.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/shared/widgets/abas_de_icone.dart';
import 'package:integra/shared/widgets/cabecalho_integra.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// Pilar Profissional — feed entre alunos e empresas, e a área de vagas.
///
/// Até a Sprint 4 esta tela era um vazio honesto com o botão de escopo funcionando:
/// o `feed-service` e o `jobs-service` não existiam, e preenchê-la com dados falsos
/// esconderia o que faltava. Agora ela é as duas coisas, e o botão de escopo passou a
/// mandar o valor que já guardava.
///
/// ## Abas, e por que duas coisas na mesma aba do rodapé
///
/// Feed e vagas são **serviços separados** porque um post e uma vaga têm ciclos de
/// vida diferentes — uma vaga encerra e tem candidatos. Mas são o mesmo pilar para
/// quem usa: é onde se fala de trabalho. Um quarto ramo no rodapé para vagas gastaria
/// a faixa mais disputada da tela por uma lista que a maioria abre às vezes.
///
/// A terceira aba, **candidaturas**, existe só para conta `aluno`. Empresa não se
/// candidata a nada, e uma aba vazia por definição é pior que aba nenhuma — a mesma
/// regra que tirou a aba de currículo do perfil institucional. A empresa alcança as
/// candidaturas **pela vaga**, que é onde elas pertencem.
///
/// É um [CustomScrollView] porque o cabeçalho é um sliver retrátil e as abas são um
/// sliver fixado. Com `Column` + `Expanded` + `ListView` haveria dois eixos de
/// rolagem, e o cabeçalho ficaria preso ao de fora — que nunca rola.
class ProfissionalScreen extends ConsumerWidget {
  const ProfissionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ShadTheme.of(context).colorScheme;
    final perfil = ref.watch(perfilAtualProvider);
    final escopo = ref.watch(escopoDoProfissionalProvider);
    final aba = ref.watch(abaDoProfissionalProvider);

    final ehAluno = perfil?.tipo == TipoConta.aluno;

    // Publicar daqui exige conta ativada e **não** ser faculdade — as mesmas duas
    // condições que o serviço checa, na mesma ordem. A pendente não vê o botão:
    // receberia 403, e oferecer uma ação que será recusada é pior que não oferecer.
    final podePublicar =
        perfil != null &&
        perfil.tipo != TipoConta.faculdade &&
        perfil.ativadaEm != null;

    final abas = <AbaDeIcone<AbaDoProfissional>>[
      (
        valor: AbaDoProfissional.feed,
        icone: LucideIcons.messageSquare,
        rotulo: 'Feed profissional',
      ),
      (
        valor: AbaDoProfissional.vagas,
        icone: LucideIcons.briefcase,
        rotulo: 'Vagas',
      ),
      if (ehAluno)
        (
          valor: AbaDoProfissional.candidaturas,
          icone: LucideIcons.send,
          rotulo: 'Minhas candidaturas',
        ),
    ];

    // A conta pode ter trocado desde a última escolha — uma empresa não tem a aba de
    // candidaturas. Cair para o feed é mais honesto que mostrar uma aba que não existe
    // na barra: o sublinhado ficaria em nenhuma delas.
    final abaEmVigor = abas.any((a) => a.valor == aba)
        ? aba
        : AbaDoProfissional.feed;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CabecalhoIntegra(
            // **Um controle por aba, no mesmo canto.** O slot da esquerda é o lugar do
            // controle da lista nas duas telas de feed, e a aba de vagas passou a usá-lo
            // também: o filtro dela morava numa faixa abaixo das abas, que custava até
            // duas linhas permanentes da tela.
            //
            // Os dois ícones são **diferentes** de propósito — `slidersHorizontal` para
            // escopo, `listFilter` para filtro. O mesmo ícone com significado diferente
            // por aba é como um controle deixa de ser confiável. Candidaturas não tem
            // controle: a lista é "as minhas", e não há o que estreitar.
            escopo: switch (abaEmVigor) {
              AbaDoProfissional.feed => BotaoDeEscopo<EscopoDoProfissional>(
                opcoes: EscopoDoProfissional.values,
                selecionado: escopo,
                padrao: EscopoDoProfissional.geral,
                rotulo: (e) => e.rotulo,
                descricao: (e) => e.descricao,
                cor: cores.profissional,
                aoTrocar: (e) =>
                    ref.read(escopoDoProfissionalProvider.notifier).trocar(e),
              ),
              AbaDoProfissional.vagas => const BotaoDeFiltroDeVagas(),
              AbaDoProfissional.candidaturas => null,
            },
            acoes: [
              if (podePublicar && abaEmVigor == AbaDoProfissional.feed)
                Tooltip(
                  message: 'Novo post',
                  child: ShadIconButton.ghost(
                    icon: const Icon(LucideIcons.squarePen, size: 20),
                    onPressed: () => context.push(Rotas.comporPostProfissional),
                  ),
                ),
              if (perfil?.tipo == TipoConta.empresa &&
                  perfil?.ativadaEm != null &&
                  abaEmVigor == AbaDoProfissional.vagas)
                Tooltip(
                  message: 'Nova vaga',
                  child: ShadIconButton.ghost(
                    icon: const Icon(LucideIcons.plus, size: 20),
                    onPressed: () => context.push(Rotas.comporVaga),
                  ),
                ),
            ],
          ),

          AbasDeIcone<AbaDoProfissional>(
            abas: abas,
            selecionada: abaEmVigor,
            cor: cores.profissional,
            aoTrocar: (nova) =>
                ref.read(abaDoProfissionalProvider.notifier).trocar(nova),
          ),

          switch (abaEmVigor) {
            AbaDoProfissional.feed => const _Feed(),
            AbaDoProfissional.vagas => const ListaDeVagas(),
            AbaDoProfissional.candidaturas => const ListaDeCandidaturas(),
          },
        ],
      ),
    );
  }
}

class _Feed extends ConsumerWidget {
  const _Feed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProfissionalProvider);
    final perfil = ref.watch(perfilAtualProvider);

    return switch (feed) {
      AsyncError(:final error) => _Centrado(
        child: _Erro(
          mensagem: error is Failure
              ? error.mensagem
              : 'Não foi possível carregar o feed.',
          aoTentarDeNovo: () => ref.invalidate(feedProfissionalProvider),
        ),
      ),
      AsyncLoading() => const _Centrado(
        child: Center(child: CircularProgressIndicator()),
      ),
      AsyncData(:final value) when value.itens.isEmpty => _Centrado(
        child: _Vazio(
          escopo: ref.watch(escopoDoProfissionalProvider),
          temVinculo: perfil?.vinculo != null,
        ),
      ),
      AsyncData(:final value) => _Lista(estado: value),
    };
  }
}

/// Ocupa o que sobra da viewport, para vazio e erro ficarem centrados.
///
/// `hasScrollBody: false` é o que permite rolar mesmo com a tela vazia — sem isso o
/// cabeçalho, que só volta com uma rolagem para cima, ficaria escondido se o usuário
/// o tivesse recolhido.
class _Centrado extends StatelessWidget {
  const _Centrado({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}

class _Lista extends ConsumerWidget {
  const _Lista({required this.estado});

  final FeedProfissionalState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(feedProfissionalProvider.notifier);

    return SliverPadding(
      padding: const EdgeInsets.all(Espaco.md),
      sliver: SliverList.builder(
        // +1 para o rodapé de "carregar mais", quando há próxima página.
        itemCount: estado.itens.length + (estado.temMais ? 1 : 0),
        itemBuilder: (context, indice) {
          if (indice == estado.itens.length) {
            return _CarregarMais(
              carregando: estado.carregandoMais,
              aoTocar: notifier.carregarMais,
            );
          }

          final post = estado.itens[indice];
          return PostProfissionalCard(
            post: post,
            aoTocar: () => context.push(Rotas.postProfissional(post.id)),
            aoAtualizar: notifier.substituir,
            aoRemover: notifier.retirar,
          );
        },
      ),
    );
  }
}

/// Botão explícito em vez de rolagem infinita.
///
/// Mesma escolha do Acadêmico: um feed que carrega sozinho ao chegar no fim nunca tem
/// fim visível, e saber que a lista acabou é informação útil.
class _CarregarMais extends StatelessWidget {
  const _CarregarMais({required this.carregando, required this.aoTocar});

  final bool carregando;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Espaco.lg),
    child: Center(
      child: carregando
          ? const CircularProgressIndicator()
          : ShadButton.outline(
              onPressed: aoTocar,
              child: const Text('Carregar mais'),
            ),
    ),
  );
}

/// O vazio do feed profissional, em três versões.
///
/// As causas são diferentes e o que o usuário precisa fazer também — a mesma
/// disciplina dos dois vazios do Acadêmico:
///
/// - **`escopo=empresas` sem seguir empresa nenhuma**: empresa não entra por
///   recomendação, então o caminho é seguir. É a única versão que o escopo causa, e
///   ela existe para o usuário não ler um feed filtrado como um feed inexistente.
/// - **Sem vínculo e sem seguir ninguém**: nada recomendável e nada seguido. O
///   caminho é a busca.
/// - **Com vínculo e nada publicado**: não há o que fazer, e a tela não finge que há.
class _Vazio extends StatelessWidget {
  const _Vazio({required this.escopo, required this.temVinculo});

  final EscopoDoProfissional escopo;
  final bool temVinculo;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    if (escopo == EscopoDoProfissional.empresas) {
      return EstadoVazio(
        icone: LucideIcons.building2,
        cor: cores.profissional,
        titulo: 'Nenhuma empresa que você segue publicou',
        // A frase carrega a regra do contrato: empresa não tem vínculo, então não há
        // como recomendá-la por universidade. Um vazio genérico deixaria o usuário
        // achando que nenhuma empresa usa o app.
        descricao:
            'Posts de empresa só aparecem para quem as segue — não há '
            'recomendação de empresa, porque empresa não tem vínculo com '
            'universidade. Busque e siga as que te interessam.',
        acao: ShadButton(
          leading: const Icon(LucideIcons.search, size: 16),
          onPressed: () => context.push(Rotas.busca),
          child: const Text('Buscar empresas'),
        ),
      );
    }

    if (!temVinculo) {
      return EstadoVazio(
        icone: LucideIcons.users,
        cor: cores.profissional,
        titulo: 'Seu feed começa vazio',
        descricao:
            'Aparecem aqui os posts de quem você segue e de alunos da sua '
            'instituição. Informe seu CPF no perfil da sua faculdade para o '
            'vínculo nascer, ou siga pessoas e empresas pela busca.',
        acao: ShadButton(
          leading: const Icon(LucideIcons.search, size: 16),
          onPressed: () => context.push(Rotas.busca),
          child: const Text('Buscar pessoas e empresas'),
        ),
      );
    }

    return EstadoVazio(
      icone: LucideIcons.messageSquare,
      cor: cores.profissional,
      titulo: 'Nada por aqui ainda',
      descricao:
          'Quando alguém da sua instituição ou que você segue publicar, os '
          'posts aparecem aqui. Você também pode ser o primeiro.',
    );
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
