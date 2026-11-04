import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/academic/presentation/academic_providers.dart';
import 'package:integra/features/academic/presentation/widgets/botao_de_escopo.dart';
import 'package:integra/features/academic/presentation/widgets/post_card.dart';
import 'package:integra/features/auth/domain/auth_validators.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/institution/presentation/instituicoes_providers.dart';
import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/profile/data/models/instituicao.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/presentation/perfil_screen.dart';
import 'package:integra/shared/widgets/abas_de_icone.dart';
import 'package:integra/shared/widgets/cabecalho_integra.dart';

/// O perfil de uma universidade: o que o aluno alcança pela busca, e **o próprio
/// perfil da conta `faculdade`**.
///
/// É a tela onde o vínculo nasce. O menu do canto superior direito oferece
/// **"inserir CPF"** para quem não tem vínculo com esta instituição, e
/// **"encerrar vínculo"** para quem tem — a decisão vem de `temVinculo`, que o
/// serviço calcula para o leitor, em vez de a tela cruzar duas respostas.
///
/// Enquanto não há vínculo, o que se vê aqui são só os posts públicos. É a
/// consequência visível da regra: formação declarada, e mesmo formação
/// verificada antiga, não abrem os comunicados internos.
///
/// ## Uma tela para os dois lados
///
/// [universidadeId] nulo é **a própria instituição**, alcançada pela aba de perfil do
/// rodapé; preenchido é o perfil de uma instituição qualquer, alcançado pela busca.
/// O corpo é o mesmo, e as diferenças são três:
///
/// - **o canto direito**: o menu da conta no próprio perfil — editar, trocar senha,
///   administração, sair —, o menu do vínculo no de outra instituição. Nenhuma das
///   ações do segundo faz sentido na primeira: vínculo é de aluno;
/// - **o botão de seguir**, que não existe no próprio perfil;
/// - **o filtro de curso** na aba "por curso", que só a própria instituição tem:
///   para o aluno aquela aba já é "o meu curso", e não há o que escolher.
///
/// A conta `faculdade` via, até aqui, um perfil **vazio** com uma frase apontando
/// para "o perfil da instituição" — uma tela que ela não tinha como abrir, porque o
/// caminho era a busca e o resultado dela não traz a própria conta. Duas telas para
/// isso repetiriam identificação, as três abas e a lista; a versão de cada lado
/// divergiria na primeira aba nova.
class PerfilDeUniversidadeScreen extends ConsumerWidget {
  const PerfilDeUniversidadeScreen({this.universidadeId, super.key});

  /// Nulo é a instituição da conta autenticada.
  final String? universidadeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final id = universidadeId;

    // Duas fontes para o mesmo corpo: por id, ou `/universidades/me` quando o id não
    // existe no cliente — o elo conta → universidade mora no `user-service`.
    final perfil = id == null
        ? ref.watch(minhaUniversidadeProvider)
        : ref.watch(perfilDeUniversidadeProvider(id));

    void recarregar() => id == null
        ? ref.invalidate(minhaUniversidadeProvider)
        : ref.invalidate(perfilDeUniversidadeProvider(id));

    return Scaffold(
      backgroundColor: tema.colorScheme.background,
      body: switch (perfil) {
        AsyncError(:final error) => CustomScrollView(
          slivers: [
            const CabecalhoIntegra(),
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Erro(
                mensagem: error is Failure
                    ? error.mensagem
                    : 'Não foi possível carregar esta instituição.',
              ),
            ),
          ],
        ),
        AsyncLoading() => const CustomScrollView(
          slivers: [
            CabecalhoIntegra(),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        AsyncData(:final value) => _Conteudo(
          universidade: value,
          propria: id == null,
          aoConcluirAcao: recarregar,
        ),
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

/// O corpo do perfil: identificação, ação, e as **três abas** de comunicados.
///
/// Um [CustomScrollView] só, com o cabeçalho retrátil no topo e a barra de abas
/// fixada logo abaixo. Não há `TabBarView`: cada aba é uma lista, e só uma aparece
/// por vez, então basta um estado e um sliver de conteúdo. `TabBarView` traria um
/// segundo eixo de rolagem aninhado no primeiro — e é aí que o cabeçalho deixa de
/// saber que a lista rolou.
class _Conteudo extends ConsumerStatefulWidget {
  const _Conteudo({
    required this.universidade,
    required this.propria,
    required this.aoConcluirAcao,
  });

  final PerfilDeUniversidade universidade;

  /// Se quem olha é a conta que administra esta instituição.
  final bool propria;

  /// Recarrega o perfil depois de inserir CPF, encerrar vínculo ou seguir — as
  /// três mudam `temVinculo`, `seguindo` ou o total de alunos.
  final VoidCallback aoConcluirAcao;

  @override
  ConsumerState<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends ConsumerState<_Conteudo> {
  Visibilidade _aba = Visibilidade.publico;

  /// O curso escolhido no filtro da aba "por curso". **Nulo é todos**, que é como
  /// a aba nasce: a instituição abre a aba para ver o que publicou, e começar
  /// filtrada esconderia a maior parte sem ela ter pedido nada.
  String? _cursoId;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final universidade = widget.universidade;
    final eu = ref.watch(perfilAtualProvider);

    return CustomScrollView(
      slivers: [
        CabecalhoIntegra(
          // Só na própria instituição, e só na aba restrita a curso: é a única lista
          // desta tela que tem mais de um recorte possível. Para o aluno a aba já é
          // "o meu curso" — o vínculo é um só —, e um filtro com uma opção seria um
          // controle que não controla nada.
          escopo: widget.propria && _aba == Visibilidade.curso
              ? _FiltroDeCurso(
                  selecionado: _cursoId,
                  aoTrocar: (curso) => setState(() => _cursoId = curso),
                )
              : null,
          // O menu ocupa o canto direito em vez do botão de mensagens: aqui ele é
          // **a** ação da tela, e é por ele que o vínculo nasce. Mensagens está a
          // um toque em qualquer aba; o menu só existe neste perfil.
          //
          // No próprio perfil é o menu da **conta**: inserir CPF e encerrar vínculo
          // não existem para quem é a instituição, e sair da conta precisa morar em
          // algum lugar alcançável.
          direita: widget.propria
              ? (eu == null ? null : MenuDaConta(perfil: eu))
              : _MenuDaInstituicao(
                  universidade: universidade,
                  aoConcluir: widget.aoConcluirAcao,
                ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(Espaco.md),
          sliver: SliverList.list(
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
                        // A sigla faz o papel do título que saiu do cabeçalho:
                        // quem chegou aqui pela busca precisa saber onde chegou, e
                        // "FATEC RP" diz mais que "Instituição".
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

              // Nenhum selo de vínculo aqui, e os dois que existiam saíram por
              // razões diferentes.
              //
              // **"N com vínculo"** era agregado e não expunha quem — mas expunha
              // quantos, e quantos alunos uma faculdade tem no Integra é informação
              // dela. Saiu da resposta da API junto (contrato de `user` 2.2.0), não
              // só da tela: um campo escondido no cliente continua legível para
              // quem ler o JSON.
              //
              // **"Você tem vínculo aqui"** era redundante. O menu do canto já
              // oferece "encerrar vínculo" em vez de "inserir CPF", e as abas
              // restritas já mostram conteúdo em vez de explicar o que falta —
              // duas respostas à mesma pergunta, nos lugares onde ela é feita.
              // Ninguém segue a si mesmo. No próprio perfil o lugar é do aviso de
              // análise, que é o que a conta pendente precisa ler aqui — e que a
              // ativada não vê, porque não há nada a avisar.
              if (!widget.propria)
                _BotaoDeSeguir(universidade: universidade)
              else if (eu?.aguardandoAtivacao ?? false)
                const AvisoDeAnalise(),
              const SizedBox(height: Espaco.md),
            ],
          ),
        ),

        // As três abas de alcance, no formato que o Instagram usa para separar
        // posts, reels e marcações. A ordem vai do mais aberto para o mais fechado,
        // e não é arrumação: quem abre o perfil sem vínculo vê a primeira cheia e
        // as outras duas explicando o que falta — a regra do vínculo dita pela
        // própria tela, no momento em que ela importa.
        AbasDeIcone<Visibilidade>(
          selecionada: _aba,
          cor: cores.academico,
          aoTrocar: (aba) => setState(() {
            _aba = aba;
            // Sair da aba de curso solta o filtro: voltar a ela dias depois com um
            // curso escolhido e esquecido é como alguém lê uma lista filtrada como
            // uma lista vazia — e o botão do cabeçalho nem está à vista nas outras.
            if (aba != Visibilidade.curso) _cursoId = null;
          }),
          abas: const [
            (
              valor: Visibilidade.publico,
              icone: LucideIcons.globe,
              rotulo: 'Geral',
            ),
            (
              valor: Visibilidade.institucional,
              icone: LucideIcons.lock,
              rotulo: 'Institucional',
            ),
            (
              valor: Visibilidade.curso,
              icone: LucideIcons.graduationCap,
              rotulo: 'Por curso',
            ),
          ],
        ),

        _ListaDaAba(
          universidade: universidade,
          aba: _aba,
          propria: widget.propria,
          cursoId: _cursoId,
        ),
      ],
    );
  }
}

/// O filtro de curso da aba restrita, no canto esquerdo do cabeçalho.
///
/// Reusa o [BotaoDeEscopo] do feed: é o mesmo controle — uma lista de opções com
/// uma marcada, num ícone que ganha cor quando a lista está estreitada. Escrever um
/// segundo seletor com a mesma função é como os dois divergiriam no primeiro ajuste.
///
/// `null` é **todos os cursos**, e é a opção marcada por padrão. Ela é um valor da
/// lista em vez de um botão de "limpar": limpar um filtro é a mesma escolha que
/// escolher tudo, e duas formas de fazê-lo é uma a mais.
class _FiltroDeCurso extends ConsumerWidget {
  const _FiltroDeCurso({required this.selecionado, required this.aoTrocar});

  final String? selecionado;
  final ValueChanged<String?> aoTrocar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ShadTheme.of(context).colorScheme;
    // Os cursos que a **própria** instituição cadastrou, que é exatamente o conjunto
    // de valores possíveis em `visibilidade: curso` dos posts dela.
    final cursos = ref.watch(meusCursosProvider).value ?? const <Curso>[];

    // Sem curso cadastrado não há comunicado restrito a curso, e portanto nada a
    // filtrar. O botão não aparece em vez de aparecer com uma opção só.
    if (cursos.isEmpty) return const SizedBox.shrink();

    final nomes = {for (final curso in cursos) curso.id: curso.nome};

    return BotaoDeEscopo<String?>(
      titulo: 'Curso',
      icone: LucideIcons.graduationCap,
      opcoes: [null, ...cursos.map((c) => c.id)],
      selecionado: selecionado,
      padrao: null,
      cor: cores.academico,
      rotulo: (id) => id == null ? 'Todos os cursos' : nomes[id] ?? 'Curso',
      descricao: (id) => id == null
          ? 'Os comunicados restritos de qualquer curso'
          : 'Só os restritos a este curso',
      aoTrocar: aoTrocar,
    );
  }
}

/// A lista da aba escolhida.
///
/// Cada aba é uma chamada com `visibilidade` própria, e o filtro é **de
/// apresentação**: ele estreita o que a matriz de visibilidade já autorizou e nunca
/// amplia. Pedir a aba "por curso" sem vínculo naquele curso devolve lista vazia —
/// não os restritos.
///
/// As três abas aparecem para todo mundo, inclusive para quem não tem vínculo. A
/// alternativa, esconder as duas restritas, deixaria o aluno sem saber que existe
/// conteúdo que ele não alcança — e é justamente isso que o precisa levar a informar
/// o CPF. O vazio de cada uma explica o que falta.
class _ListaDaAba extends ConsumerWidget {
  const _ListaDaAba({
    required this.universidade,
    required this.aba,
    required this.propria,
    required this.cursoId,
  });

  final PerfilDeUniversidade universidade;
  final Visibilidade aba;
  final bool propria;

  /// O curso escolhido no filtro, ou nulo para todos. Só a própria instituição
  /// escolhe, e o filtro é **de apresentação**: a instituição é a autora de tudo que
  /// aparece aqui, então não há nada que ele pudesse abrir indevidamente.
  final String? cursoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final pagina = ref.watch(
      postsDaUniversidadeProvider((
        universidadeId: universidade.id,
        visibilidade: aba,
      )),
    );

    // O filtro de curso não vai na query: a aba já pede `visibilidade=curso`, e os
    // posts restritos de uma instituição cabem numa página. Mandá-lo ao servidor
    // exigiria um parâmetro novo no contrato para estreitar o que já está na mão.
    final posts = cursoId == null
        ? pagina
        : pagina.whenData(
            (p) => p.copyWith(
              itens: p.itens.where((post) => post.curso?.id == cursoId).toList(),
            ),
          );

    return switch (posts) {
      AsyncError(:final error) => _MensagemDaAba(
        texto: error is Failure
            ? error.mensagem
            : 'Não foi possível carregar os comunicados.',
      ),
      AsyncLoading() => const SliverPadding(
        padding: EdgeInsets.symmetric(vertical: Espaco.xl),
        sliver: SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      AsyncData(:final value) when value.itens.isEmpty => _MensagemDaAba(
        texto: _explicacaoDoVazio(),
        estilo: tema.textTheme.muted,
      ),
      AsyncData(:final value) => SliverPadding(
        padding: const EdgeInsets.all(Espaco.md),
        sliver: SliverList.builder(
          itemCount: value.itens.length,
          itemBuilder: (context, indice) {
            final post = value.itens[indice];
            return PostCard(
              post: post,
              compacto: true,
              aoTocar: () => context.push(Rotas.post(post.id)),
            );
          },
        ),
      ),
    };
  }

  /// Por que esta aba está vazia — e são quatro razões diferentes.
  ///
  /// A distinção é o que faz a tela ensinar o modelo em vez de só informar a
  /// ausência: sem vínculo, a aba restrita está vazia **porque falta o vínculo**, e
  /// não porque a instituição não publica.
  String _explicacaoDoVazio() {
    // A quarta razão, e a única que não é sobre vínculo: a própria instituição vê
    // tudo que publicou, então um vazio aqui é "ainda não publiquei" — ou "não neste
    // curso", quando o filtro está ligado. As frases sobre informar CPF seriam
    // absurdas para quem é a instituição.
    if (propria) {
      if (cursoId != null) {
        return 'Nada restrito a este curso ainda. Troque o curso no filtro do '
            'canto superior esquerdo para ver os outros.';
      }
      return switch (aba) {
        Visibilidade.publico =>
          'Você ainda não publicou nenhum comunicado público.',
        Visibilidade.institucional =>
          'Você ainda não publicou nada interno. Comunicados institucionais '
              'aparecem para quem tem vínculo com a ${universidade.sigla}.',
        Visibilidade.curso =>
          'Você ainda não publicou nada restrito a um curso.',
      };
    }

    if (aba == Visibilidade.publico) {
      return 'Nenhum comunicado público por aqui ainda.';
    }

    if (!universidade.temVinculo) {
      return aba == Visibilidade.institucional
          ? 'Os comunicados internos da ${universidade.sigla} só aparecem para '
                'quem tem vínculo com ela. Declarar a formação no perfil não '
                'basta — informe seu CPF pelo menu do canto superior direito.'
          : 'Os comunicados restritos a um curso só aparecem para quem tem '
                'vínculo ativo naquele curso. Informe seu CPF pelo menu para '
                'criar o seu.';
    }

    return aba == Visibilidade.institucional
        ? 'A ${universidade.sigla} ainda não publicou nada internamente.'
        : 'Nada restrito ao seu curso ainda. Comunicados de outros cursos da '
              '${universidade.sigla} não aparecem aqui.';
  }
}

class _MensagemDaAba extends StatelessWidget {
  const _MensagemDaAba({required this.texto, this.estilo});

  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.all(Espaco.lg),
    sliver: SliverToBoxAdapter(
      child: Text(
        texto,
        style: estilo ?? ShadTheme.of(context).textTheme.muted,
        textAlign: TextAlign.center,
      ),
    ),
  );
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
        ShadToaster.of(context)
            .show(ShadToast.destructive(description: Text(falha.mensagem)));
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
        ShadToaster.of(context)
            .show(ShadToast.destructive(description: Text(falha.mensagem)));
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
        ShadToaster.of(context)
            .show(ShadToast.destructive(description: Text(falha.mensagem)));
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
