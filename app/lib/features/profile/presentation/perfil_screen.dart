import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/professional/presentation/profissional_providers.dart';
import 'package:integra/features/professional/presentation/widgets/post_profissional_card.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/presentation/widgets/formacoes_e_vinculo.dart';
import 'package:integra/shared/widgets/abas_de_icone.dart';
import 'package:integra/shared/widgets/cabecalho_integra.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// As duas partes do perfil de uma pessoa.
///
/// A divisão é a do perfil da instituição, e por um motivo comum: um perfil junta
/// duas coisas de naturezas diferentes — **o que a pessoa publicou** e **quem ela
/// é** —, e numa lista única a segunda empurra a primeira para fora da tela.
enum AbaDoPerfil { posts, curriculo }

/// Perfil do usuário autenticado.
///
/// É a tela que **prova a costura ponta a ponta**: os dados vêm do
/// `ProfileRepository`, que é o falso sobre o banco em memória ou o
/// `ApiProfileRepository` contra o `user-service`, e esta tela não muda na troca.
///
/// ## O que mudou de lugar, e por quê
///
/// **As ações saíram do corpo e foram para o menu do canto.** Editar perfil, trocar
/// senha e sair eram três botões empilhados no fim da lista, o que fazia o conteúdo
/// do perfil competir com a administração da conta pelo mesmo espaço. Com as abas,
/// eles não teriam onde morar: não pertencem nem aos posts nem ao currículo.
///
/// **O cartão "Conta" saiu inteiro**, e foi para a tela de edição. E-mail, telefone
/// e CPF são dados que se lê quando se vai mexer neles; no perfil eles ocupavam o
/// lugar do que o perfil é para mostrar. O CPF continua com a explicação de por que
/// não é editável — só agora ela aparece onde a pergunta surge.
///
/// **O menu só existe no próprio perfil.** Quando houver tela de perfil de outra
/// pessoa, o cabeçalho dela é o comum — com mensagens no canto direito, porque ali
/// a ação é falar com quem se está vendo, e não administrar a própria conta.
class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  AbaDoPerfil _aba = AbaDoPerfil.posts;

  @override
  Widget build(BuildContext context) {
    final cores = ShadTheme.of(context).colorScheme;
    final perfil = ref.watch(perfilAtualProvider);

    if (perfil == null) {
      // O roteador já impede chegar aqui sem sessão; isto cobre o instante entre o
      // logout e a troca de rota.
      return const Scaffold(body: SizedBox.shrink());
    }

    // Organização não tem currículo: empresa e faculdade não estudam em lugar
    // nenhum, e uma aba vazia por definição seria pior que aba nenhuma. Os
    // comunicados de uma faculdade aparecem no perfil público dela, alcançado pela
    // busca — e é para lá que a aba de posts aponta.
    final temCurriculo = !perfil.tipo.eInstitucional;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CabecalhoIntegra(
            // O menu ocupa o canto direito em vez de mensagens: neste perfil a ação
            // é sobre a **própria conta**, e mandar mensagem para si não existe.
            direita: _MenuDaConta(perfil: perfil),
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
                if (perfil.aguardandoAtivacao) ...[
                  const _AvisoDeAnalise(),
                  const SizedBox(height: Espaco.md),
                ],
                _Identificacao(perfil: perfil),
                const SizedBox(height: Espaco.md),
              ],
            ),
          ),

          if (temCurriculo)
            AbasDeIcone<AbaDoPerfil>(
              selecionada: _aba,
              cor: cores.primary,
              aoTrocar: (aba) => setState(() => _aba = aba),
              abas: const [
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
            ),

          if (!temCurriculo)
            const _Conteudo(child: _PostsDaInstituicao())
          else
            switch (_aba) {
              AbaDoPerfil.posts => _Conteudo(child: _PostsDaPessoa(userId: perfil.id)),
              AbaDoPerfil.curriculo => _Conteudo(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A ordem importa: quem lê de cima para baixo encontra o
                    // currículo e só então o que ele concede — que é nada, e o
                    // cartão seguinte diz isso.
                    CartaoDeFormacoes(formacoes: perfil.formacoes),
                    const SizedBox(height: Espaco.md),
                    CartaoDeVinculo(vinculo: perfil.vinculo),
                  ],
                ),
              ),
            },
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

/// As publicações de uma pessoa. **Deixaram de ser um vazio honesto na Sprint 5.**
///
/// Usa `GET /feed/usuarios/{id}/posts`, e não o feed: o feed é limitado ao conjunto do
/// leitor — quem ele segue e quem lhe é recomendado —, e o próprio perfil não está
/// nele por definição. A rota separada é o que faz esta aba mostrar o que a pessoa
/// publicou, e não o que ela veria.
///
/// Os cards vêm **compactos**: aqui eles são prévia, e o que se espera do toque é
/// abrir o post, não curtir. `origem` chega nula do servidor pelo mesmo motivo — a
/// pergunta "por que estou vendo isto?" não se faz numa lista que a pessoa pediu por
/// nome.
class _PostsDaPessoa extends ConsumerWidget {
  const _PostsDaPessoa({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final posts = ref.watch(postsDoUsuarioProvider(userId));

    return switch (posts) {
      AsyncError() => EstadoVazio(
        icone: LucideIcons.cloudOff,
        titulo: 'Não foi possível carregar',
        descricao: 'Suas publicações não vieram agora. Tente de novo em instantes.',
        acao: ShadButton.outline(
          onPressed: () => ref.invalidate(postsDoUsuarioProvider(userId)),
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
        titulo: 'Você ainda não publicou nada',
        descricao:
            'Seus posts no feed profissional aparecem aqui. Publique pelo botão '
            'do rodapé ou pelo lápis no topo do feed.',
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

/// As publicações de uma conta institucional: existem, mas moram noutro lugar.
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
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cores.academico.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          // `fotoUrl` existe no modelo mas o upload só entra na Sprint 5, com o
          // Object Storage. Até lá as iniciais são o avatar.
          child: Text(
            perfil.iniciais,
            style: tema.textTheme.large.copyWith(color: cores.academico),
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

/// A conta institucional entrou, mas ainda não pode agir.
///
/// O aviso lê `ativadaEm` do perfil — **o banco**, não um claim do token. Pôr o
/// estado no JWT faria uma conta desativada seguir publicando por até 15 minutos, o
/// tempo de vida do access token.
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
