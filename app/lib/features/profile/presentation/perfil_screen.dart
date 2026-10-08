import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/jobs/presentation/jobs_providers.dart';
import 'package:integra/features/jobs/presentation/widgets/vaga_card.dart';
import 'package:integra/features/professional/presentation/profissional_providers.dart';
import 'package:integra/features/professional/presentation/widgets/post_profissional_card.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/domain/pode_seguir.dart';
import 'package:integra/features/profile/presentation/widgets/formacoes_e_vinculo.dart';
import 'package:integra/shared/widgets/abas_de_icone.dart';
import 'package:integra/shared/widgets/cabecalho_integra.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// `GET /users/{id}` — o perfil público de outra conta.
final perfilDeProvider = FutureProvider.autoDispose.family<Perfil, String>(
  (ref, userId) => ref.watch(profileRepositoryProvider).perfilDe(userId),
);

/// Os ids que o leitor segue, como conjunto.
///
/// Uma lista por sessão em vez de um campo `seguindo` em `PerfilPublico`: o campo
/// custaria uma consulta ao grafo em toda busca e em todo card, para responder algo
/// que uma chamada responde para todos de uma vez. Observa a sessão, senão trocar de
/// conta mostraria o grafo da anterior.
final usuariosSeguidosProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(perfilAtualProvider);
  final seguidos = await ref.watch(profileRepositoryProvider).usuariosSeguidos();
  return {for (final perfil in seguidos) perfil.id};
});

/// As partes de um perfil. **Quais existem depende do tipo de conta.**
///
/// A divisão vem do perfil da instituição, por um motivo comum: um perfil junta duas
/// coisas de naturezas diferentes — **o que a conta publicou** e **quem ela é** —, e
/// numa lista única a segunda empurra a primeira para fora da tela.
///
/// `curriculo` é de pessoa; `vagas` é de empresa. Nenhuma conta tem as duas, e é por
/// isso que são valores do mesmo enum em vez de dois enums: a barra de abas é
/// genérica sobre o valor, e o que ela recebe é sempre uma lista de duas.
enum AbaDoPerfil { posts, curriculo, vagas }

/// Perfil de uma conta — **a própria ou a de outra pessoa**.
///
/// É a tela que **prova a costura ponta a ponta**: os dados vêm do
/// `ProfileRepository`, que é o falso sobre o banco em memória ou o
/// `ApiProfileRepository` contra o `user-service`, e esta tela não muda na troca.
///
/// ## Uma tela para os dois lados
///
/// [userId] nulo é o próprio perfil, alcançado pela aba do rodapé; preenchido é o
/// perfil público de outra conta, alcançado pela busca, por um card do feed ou por uma
/// candidatura. O corpo é o mesmo nas duas, e as diferenças são duas:
///
/// - **o canto direito do cabeçalho**: o menu da conta no próprio perfil, o botão de
///   mensagens no de outra pessoa — ali a ação é falar com quem se está vendo, e não
///   administrar a própria conta;
/// - **o botão de seguir**, que só existe no perfil de outra conta, e só quando a
///   matriz de [podeSeguir] permite.
///
/// Duas telas para isso teriam que repetir identificação, abas e as três listas, e a
/// versão de cada lado divergiria na primeira aba nova.
///
/// ## O que mudou de lugar, e por quê
///
/// **As ações saíram do corpo e foram para o menu do canto.** Editar perfil, trocar
/// senha e sair eram três botões empilhados no fim da lista, o que fazia o conteúdo
/// do perfil competir com a administração da conta pelo mesmo espaço. Com as abas,
/// eles não teriam onde morar: não pertencem a nenhuma delas.
///
/// **O cartão "Conta" saiu inteiro**, e foi para a tela de edição. E-mail, telefone
/// e CPF são dados que se lê quando se vai mexer neles; no perfil eles ocupavam o
/// lugar do que o perfil é para mostrar. O CPF continua com a explicação de por que
/// não é editável — só agora ela aparece onde a pergunta surge.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({this.userId, super.key});

  /// Nulo é o perfil da conta autenticada.
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = userId;

    if (id == null) {
      final perfil = ref.watch(perfilAtualProvider);
      if (perfil == null) {
        // O roteador já impede chegar aqui sem sessão; isto cobre o instante entre o
        // logout e a troca de rota.
        return const Scaffold(body: SizedBox.shrink());
      }
      return _Perfil(perfil: perfil, proprio: true);
    }

    // O próprio perfil alcançado por id — tocar no próprio nome num card do feed — é
    // o mesmo perfil, com o menu da conta. Comparar aqui evita a tela oferecer
    // "seguir" para a conta de quem está olhando.
    final eu = ref.watch(perfilAtualProvider);
    if (eu != null && eu.id == id) {
      return _Perfil(perfil: eu, proprio: true);
    }

    return switch (ref.watch(perfilDeProvider(id))) {
      AsyncError(:final error) => _Moldura(
        child: EstadoVazio(
          icone: LucideIcons.cloudOff,
          titulo: 'Não foi possível abrir este perfil',
          descricao: error is Failure
              ? error.mensagem
              : 'O perfil não veio agora. Tente de novo em instantes.',
          acao: ShadButton.outline(
            onPressed: () => ref.invalidate(perfilDeProvider(id)),
            child: const Text('Tentar de novo'),
          ),
        ),
      ),
      AsyncLoading() => const _Moldura(
        child: Center(child: CircularProgressIndicator()),
      ),
      AsyncData(:final value) => _Perfil(perfil: value, proprio: false),
    };
  }
}

/// Cabeçalho mais o que sobra da viewport. Serve ao carregando e ao erro.
class _Moldura extends StatelessWidget {
  const _Moldura({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      slivers: [
        const CabecalhoIntegra(),
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    ),
  );
}

class _Perfil extends ConsumerStatefulWidget {
  const _Perfil({required this.perfil, required this.proprio});

  final Perfil perfil;
  final bool proprio;

  @override
  ConsumerState<_Perfil> createState() => _PerfilState();
}

class _PerfilState extends ConsumerState<_Perfil> {
  AbaDoPerfil _aba = AbaDoPerfil.posts;

  Perfil get _perfil => widget.perfil;

  /// As abas desta conta. Vazia na faculdade, que não tem nenhuma das duas segundas.
  ///
  /// Pessoa tem currículo; empresa tem vagas. A faculdade não tem nem um nem outro:
  /// organização não estuda em lugar nenhum, e vaga é de empresa. Os comunicados dela
  /// moram no perfil público da instituição, com as três abas por alcance — listá-los
  /// aqui também criaria dois lugares para manter.
  List<AbaDeIcone<AbaDoPerfil>> get _abas => switch (_perfil.tipo) {
    TipoConta.aluno => const [
      (
        valor: AbaDoPerfil.posts,
        icone: LucideIcons.layoutGrid,
        rotulo: 'Publicações',
      ),
      (
        valor: AbaDoPerfil.curriculo,
        icone: LucideIcons.graduationCap,
        rotulo: 'Currículo',
      ),
    ],
    TipoConta.empresa => const [
      (
        valor: AbaDoPerfil.posts,
        icone: LucideIcons.layoutGrid,
        rotulo: 'Publicações',
      ),
      (
        valor: AbaDoPerfil.vagas,
        icone: LucideIcons.briefcase,
        rotulo: 'Vagas',
      ),
    ],
    TipoConta.faculdade => const [],
  };

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;
    final abas = _abas;

    // A aba guardada pode não existir nesta conta — abrir o perfil de uma empresa a
    // partir do currículo da própria pessoa. Cair nas publicações é mais honesto que
    // deixar o sublinhado em nenhuma das abas.
    final abaEmVigor = abas.any((a) => a.valor == _aba)
        ? _aba
        : AbaDoPerfil.posts;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CabecalhoIntegra(
            // No próprio perfil o menu ocupa o canto direito em vez de mensagens: a
            // ação aqui é sobre a **própria conta**, e mandar mensagem para si não
            // existe. No perfil de outra pessoa é o contrário, e o padrão do
            // cabeçalho — o botão de chat — é exatamente o certo.
            direita: widget.proprio ? _MenuDaConta(perfil: _perfil) : null,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Espaco.md,
              Espaco.md,
              Espaco.md,
              0,
            ),
            sliver: SliverList.list(
              children: [
                if (widget.proprio && _perfil.aguardandoAtivacao) ...[
                  const _AvisoDeAnalise(),
                  const SizedBox(height: Espaco.md),
                ],
                _Identificacao(perfil: _perfil),
                if (!widget.proprio) ...[
                  const SizedBox(height: Espaco.md),
                  _BotaoDeSeguir(perfil: _perfil),
                ],
                const SizedBox(height: Espaco.md),
              ],
            ),
          ),

          if (abas.isEmpty)
            const _Conteudo(child: _PostsDaInstituicao())
          else ...[
            AbasDeIcone<AbaDoPerfil>(
              abas: abas,
              selecionada: abaEmVigor,
              cor: cores.primary,
              aoTrocar: (aba) => setState(() => _aba = aba),
            ),
            switch (abaEmVigor) {
              AbaDoPerfil.posts => _Conteudo(
                child: _PostsDaConta(perfil: _perfil, proprio: widget.proprio),
              ),
              AbaDoPerfil.vagas => _Conteudo(
                child: _VagasDaEmpresa(
                  empresaId: _perfil.id,
                  proprio: widget.proprio,
                ),
              ),
              AbaDoPerfil.curriculo => _Conteudo(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A ordem importa: quem lê de cima para baixo encontra o
                    // currículo e só então o que ele concede — que é nada, e o
                    // cartão seguinte diz isso.
                    CartaoDeFormacoes(formacoes: _perfil.formacoes),
                    const SizedBox(height: Espaco.md),
                    CartaoDeVinculo(vinculo: _perfil.vinculo),
                  ],
                ),
              ),
            },
          ],
        ],
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.all(Espaco.md),
    sliver: SliverToBoxAdapter(child: child),
  );
}

/// Seguir ou deixar de seguir a conta deste perfil.
///
/// Só aparece quando a matriz de [podeSeguir] permite — aluno segue qualquer conta,
/// faculdade só segue empresa, empresa não segue faculdade. Quando não permite, não há
/// botão desabilitado com explicação: a combinação nem faz sentido para quem está
/// olhando, e um controle morto é pior que controle nenhum.
///
/// O estado vem de [usuariosSeguidosProvider], e o toque o invalida. Não há otimismo
/// local: o que o perfil mostra depois do toque é o que o servidor confirma.
class _BotaoDeSeguir extends ConsumerStatefulWidget {
  const _BotaoDeSeguir({required this.perfil});

  final Perfil perfil;

  @override
  ConsumerState<_BotaoDeSeguir> createState() => _BotaoDeSeguirState();
}

class _BotaoDeSeguirState extends ConsumerState<_BotaoDeSeguir> {
  bool _ocupado = false;

  Future<void> _alternar({required bool seguindo}) async {
    setState(() => _ocupado = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .seguirUsuario(widget.perfil.id, seguir: !seguindo);

      ref.invalidate(usuariosSeguidosProvider);
      // Seguir muda **o feed**, e não só este botão: o conjunto do feed profissional
      // é "quem eu sigo" mais "quem me é recomendado". Sem isto, a pessoa seguiria
      // alguém e voltaria para um feed inalterado.
      ref.invalidate(feedProfissionalProvider);
    } on Failure catch (falha) {
      if (mounted) {
        ShadToaster.of(
          context,
        ).show(ShadToast.destructive(description: Text(falha.mensagem)));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eu = ref.watch(perfilAtualProvider);
    if (eu == null ||
        !podeSeguir(de: eu.tipo, para: widget.perfil.tipo)) {
      return const SizedBox.shrink();
    }

    final seguidos = ref.watch(usuariosSeguidosProvider);
    // Enquanto o conjunto não chegou, o botão não aparece: nascer "Seguir" e virar
    // "Seguindo" um quadro depois é a troca que faz alguém tocar duas vezes.
    final seguindo = seguidos.value?.contains(widget.perfil.id);
    if (seguindo == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: seguindo
          ? ShadButton.outline(
              leading: const Icon(LucideIcons.check, size: 16),
              onPressed: _ocupado ? null : () => _alternar(seguindo: true),
              child: const Text('Seguindo'),
            )
          : ShadButton(
              leading: const Icon(LucideIcons.plus, size: 16),
              onPressed: _ocupado ? null : () => _alternar(seguindo: false),
              child: const Text('Seguir'),
            ),
    );
  }
}

/// O menu de conta, no canto direito do cabeçalho.
///
/// As quatro ações que se fazem **sobre a própria conta**, e não sobre o que ela
/// publicou. A administração da instituição entra aqui pelo mesmo critério das
/// outras três: é ação de conta, e com as abas não teria onde morar no corpo.
class _MenuDaConta extends ConsumerWidget {
  const _MenuDaConta({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      builder: (context, controlador, _) => Tooltip(
        message: 'Opções da conta',
        child: ShadIconButton.ghost(
          icon: const Icon(LucideIcons.menu, size: 20),
          onPressed: () =>
              controlador.isOpen ? controlador.close() : controlador.open(),
        ),
      ),
      menuChildren: [
        // Aparece para toda conta `faculdade`, **inclusive a pendente**: a tela de
        // lá explica por que ainda não pode agir, e esconder o caminho deixaria a
        // conta em análise sem saber que ele existe.
        if (perfil.tipo == TipoConta.faculdade)
          MenuItemButton(
            leadingIcon: const Icon(LucideIcons.settings, size: 16),
            onPressed: () => context.push(Rotas.administracao),
            child: const Text('Administração da instituição'),
          ),
        MenuItemButton(
          leadingIcon: const Icon(LucideIcons.pencil, size: 16),
          onPressed: () => context.push(Rotas.editarPerfil),
          child: const Text('Editar perfil'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(LucideIcons.keyRound, size: 16),
          onPressed: () => context.push(Rotas.trocarSenha),
          child: const Text('Trocar senha'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(LucideIcons.logOut, size: 16),
          onPressed: () => ref.read(sessaoProvider.notifier).sair(),
          child: const Text('Sair da conta'),
        ),
      ],
    );
  }
}

/// As publicações de uma conta no feed profissional.
///
/// Usa `GET /feed/usuarios/{id}/posts`, e não o feed: o feed é limitado ao conjunto do
/// leitor — quem ele segue e quem lhe é recomendado —, e um perfil não está nele por
/// definição. A rota separada é o que faz esta aba mostrar o que a conta publicou, e
/// não o que ela veria.
///
/// Os cards vêm **compactos**: aqui eles são prévia, e o que se espera do toque é
/// abrir o post, não curtir. `origem` chega nula do servidor pelo mesmo motivo — a
/// pergunta "por que estou vendo isto?" não se faz numa lista que a pessoa pediu por
/// nome.
class _PostsDaConta extends ConsumerWidget {
  const _PostsDaConta({required this.perfil, required this.proprio});

  final Perfil perfil;
  final bool proprio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final posts = ref.watch(postsDoUsuarioProvider(perfil.id));

    return switch (posts) {
      AsyncError() => EstadoVazio(
        icone: LucideIcons.cloudOff,
        titulo: 'Não foi possível carregar',
        descricao: proprio
            ? 'Suas publicações não vieram agora. Tente de novo em instantes.'
            : 'As publicações desta conta não vieram agora. Tente de novo em '
                  'instantes.',
        acao: ShadButton.outline(
          onPressed: () => ref.invalidate(postsDoUsuarioProvider(perfil.id)),
          child: const Text('Tentar de novo'),
        ),
      ),
      AsyncLoading() => const Padding(
        padding: EdgeInsets.all(Espaco.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      AsyncData(:final value) when value.itens.isEmpty => EstadoVazio(
        icone: LucideIcons.layoutGrid,
        cor: tema.colorScheme.profissional,
        titulo: proprio
            ? 'Você ainda não publicou nada'
            : 'Nada publicado ainda',
        descricao: proprio
            ? 'Seus posts no feed profissional aparecem aqui. Publique pelo '
                  'botão do rodapé ou pelo lápis no topo do feed.'
            : 'Os posts desta conta no feed profissional aparecem aqui.',
      ),
      AsyncData(:final value) => Column(
        children: [
          for (final post in value.itens)
            PostProfissionalCard(
              post: post,
              compacto: true,
              aoTocar: () => context.push(Rotas.postProfissional(post.id)),
            ),
        ],
      ),
    };
  }
}

/// As vagas de uma empresa — **abertas e encerradas**.
///
/// É a diferença entre esta aba e a área de vagas do pilar: lá a lista é das abertas,
/// porque uma vaga encerrada é um beco para quem procura trabalho. Aqui a pergunta é
/// "o que esta empresa publicou", e o histórico é parte da resposta — a etiqueta de
/// "Encerrada" no card diz qual é qual.
///
/// Mesmos cards da área de vagas, e o toque leva ao mesmo detalhe: uma vaga é a mesma
/// coisa nos dois lugares, e um card próprio daqui divergiria no primeiro campo novo.
class _VagasDaEmpresa extends ConsumerWidget {
  const _VagasDaEmpresa({required this.empresaId, required this.proprio});

  final String empresaId;
  final bool proprio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final vagas = ref.watch(vagasDaEmpresaProvider(empresaId));

    return switch (vagas) {
      AsyncError(:final error) => EstadoVazio(
        icone: LucideIcons.cloudOff,
        titulo: 'Não foi possível carregar',
        descricao: error is Failure
            ? error.mensagem
            : 'As vagas não vieram agora. Tente de novo em instantes.',
        acao: ShadButton.outline(
          onPressed: () => ref.invalidate(vagasDaEmpresaProvider(empresaId)),
          child: const Text('Tentar de novo'),
        ),
      ),
      AsyncLoading() => const Padding(
        padding: EdgeInsets.all(Espaco.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      AsyncData(:final value) when value.isEmpty => EstadoVazio(
        icone: LucideIcons.briefcase,
        cor: tema.colorScheme.profissional,
        titulo: proprio ? 'Você ainda não publicou vagas' : 'Nenhuma vaga ainda',
        descricao: proprio
            ? 'As vagas que você publicar aparecem aqui — as abertas e as que '
                  'você encerrar. Publique pelo botão do rodapé.'
            : 'As vagas desta empresa aparecem aqui quando houver.',
      ),
      AsyncData(:final value) => Column(
        children: [
          for (final vaga in value)
            VagaCard(
              vaga: vaga,
              aoTocar: () => context.push(Rotas.vaga(vaga.id)),
            ),
        ],
      ),
    };
  }
}

/// As publicações de uma faculdade: existem, mas moram noutro lugar.
///
/// Só a conta `faculdade` chega aqui. A empresa tinha esta mesma tela até a Sprint 5 e
/// era errado: ela não tem instituição nenhuma, então a frase apontava para uma
/// página que não existe. O perfil dela agora tem as duas abas que ela de fato enche —
/// posts e vagas.
class _PostsDaInstituicao extends StatelessWidget {
  const _PostsDaInstituicao();

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;

    return EstadoVazio(
      icone: LucideIcons.megaphone,
      cor: cores.academico,
      titulo: 'Seus comunicados ficam no perfil da instituição',
      // Aponta em vez de duplicar: os comunicados já têm uma tela, com as três abas
      // por alcance, e listá-los aqui também criaria dois lugares para manter.
      descricao:
          'Eles aparecem no feed Acadêmico de quem tem vínculo, e no perfil '
          'público da instituição — separados por alcance: geral, interno e por '
          'curso. Publique pelo botão do rodapé.',
    );
  }
}

/// Nome, arroba, tipo de conta e bio. O bloco que responde "quem é esta conta".
///
/// Chamava-se `_Cabecalho` e foi renomeado quando o cabeçalho da tela passou a ser
/// o `CabecalhoIntegra`: dois "cabeçalhos" no mesmo arquivo, um deles sem relação
/// com o outro, é confusão garantida na próxima leitura.
class _Identificacao extends StatelessWidget {
  const _Identificacao({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Row(
      children: [
        // A foto, com as iniciais atrás dela.
        //
        // O `errorBuilder` não é zelo excessivo, é o caminho normal: a imagem vive
        // num storage separado e o perfil só guarda a URL. No modo de fixtures nada
        // é enviado, e um objeto que nunca chegou é um estado possível também
        // contra o serviço — sem este ramo, o perfil viraria um X de framework.
        ClipOval(
          child: Container(
            width: 64,
            height: 64,
            color: cores.academico.withValues(alpha: 0.12),
            alignment: Alignment.center,
            child: perfil.fotoUrl == null
                ? _Iniciais(perfil: perfil)
                : Image.network(
                    perfil.fotoUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Iniciais(perfil: perfil),
                  ),
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
              Wrap(
                spacing: Espaco.xs,
                runSpacing: Espaco.xs,
                children: [
                  ShadBadge.secondary(child: Text(perfil.tipo.rotulo)),
                  if (perfil.vinculo != null)
                    ShadBadge.outline(
                      child: Text(perfil.vinculo!.universidade.sigla),
                    ),
                ],
              ),
              if (perfil.bio != null) ...[
                const SizedBox(height: Espaco.sm),
                Text(perfil.bio!, style: tema.textTheme.muted),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// O avatar de quem não tem foto, ou cuja foto não carregou.
class _Iniciais extends StatelessWidget {
  const _Iniciais({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return Text(
      perfil.iniciais,
      style: tema.textTheme.large.copyWith(color: tema.colorScheme.academico),
    );
  }
}

/// A conta institucional entrou, mas ainda não pode agir.
///
/// O aviso lê `ativadaEm` do perfil — **o banco**, não um claim do token. Pôr o
/// estado no JWT faria uma conta desativada seguir publicando por até 15 minutos, o
/// tempo de vida do access token.
///
/// Só no próprio perfil: `ativadaEm` não existe em `PerfilPublico`, e o estado de
/// análise de uma conta é assunto dela com o Integra, não de quem abre o perfil.
class _AvisoDeAnalise extends StatelessWidget {
  const _AvisoDeAnalise();

  @override
  Widget build(BuildContext context) {
    return const ShadAlert(
      icon: Icon(LucideIcons.clock),
      title: Text('Conta em análise'),
      description: Text(
        'Você pode editar o perfil normalmente. Publicar e cadastrar alunos '
        'ficam disponíveis quando a instituição for ativada.',
      ),
    );
  }
}
