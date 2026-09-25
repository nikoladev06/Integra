import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/presentation/widgets/formacoes_e_vinculo.dart';
import 'package:integra/shared/domain/documentos.dart';
import 'package:integra/shared/widgets/cabecalho_integra.dart';

/// Perfil do usuário autenticado.
///
/// É a tela que **prova a costura ponta a ponta**: os dados vêm do
/// `ProfileRepository`, que é o falso sobre o banco em memória ou o
/// `ApiProfileRepository` contra o `user-service`, e esta tela não muda na
/// troca.
///
/// A diferença visível em relação à v1 é a separação em dois cartões. Antes
/// havia um só, "Vínculo institucional", que mostrava a afiliação declarada — o
/// que dava a entender que declarar era pertencer. Agora são duas coisas com
/// cartões, textos e consequências diferentes.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final perfil = ref.watch(perfilAtualProvider);

    if (perfil == null) {
      // O roteador já impede chegar aqui sem sessão; isto cobre o instante
      // entre o logout e a troca de rota.
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: const CabecalhoIntegra(titulo: 'Perfil'),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          if (perfil.aguardandoAtivacao) ...[
            const _AvisoDeAnalise(),
            const SizedBox(height: Espaco.md),
          ],

          _Cabecalho(perfil: perfil),
          const SizedBox(height: Espaco.md),

          // A ordem importa: quem lê o perfil de cima para baixo encontra o
          // currículo e só então o que ele concede — que é nada, e o cartão
          // seguinte diz isso.
          if (!perfil.tipo.eInstitucional) ...[
            CartaoDeFormacoes(formacoes: perfil.formacoes),
            const SizedBox(height: Espaco.md),
            CartaoDeVinculo(vinculo: perfil.vinculo),
            const SizedBox(height: Espaco.md),
          ],

          _CartaoDeContato(perfil: perfil),
          const SizedBox(height: Espaco.lg),

          ShadButton.outline(
            leading: const Icon(LucideIcons.pencil, size: 16),
            onPressed: () => context.push(Rotas.editarPerfil),
            child: const Text('Editar perfil'),
          ),
          const SizedBox(height: Espaco.sm),
          ShadButton.outline(
            leading: const Icon(LucideIcons.keyRound, size: 16),
            onPressed: () => context.push(Rotas.trocarSenha),
            child: const Text('Trocar senha'),
          ),
          const SizedBox(height: Espaco.sm),
          ShadButton.outline(
            leading: const Icon(LucideIcons.logOut, size: 16),
            onPressed: () => ref.read(sessaoProvider.notifier).sair(),
            child: const Text('Sair da conta'),
          ),
          const SizedBox(height: Espaco.md),
          Text(
            'Não há recuperação de senha por e-mail: a troca exige a senha '
            'atual e acontece dentro do app.',
            style: tema.textTheme.muted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A conta institucional entrou, mas ainda não pode agir.
///
/// O aviso lê `ativadaEm` do perfil — **o banco**, não um claim do token. Pôr o
/// estado no JWT faria uma conta desativada seguir publicando por até 15
/// minutos, o tempo de vida do access token.
class _AvisoDeAnalise extends StatelessWidget {
  const _AvisoDeAnalise();

  @override
  Widget build(BuildContext context) {
    return const ShadAlert(
      icon: Icon(LucideIcons.clock),
      title: Text('Conta em análise'),
      description: Text(
        'Você pode editar o perfil normalmente. Publicar e cadastrar alunos '
        'liberam quando a ativação sair.',
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.perfil});

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

class _CartaoDeContato extends StatelessWidget {
  const _CartaoDeContato({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return ShadCard(
      title: const Text('Conta'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Espaco.sm),
          // Só o próprio perfil traz contato e documento; o público omite os
          // dois, por contrato — nem mascarados.
          _Linha(rotulo: 'E-mail', valor: perfil.email ?? 'não disponível'),
          _Linha(rotulo: 'Telefone', valor: perfil.telefone ?? 'não informado'),
          if (perfil.cpf != null)
            _Linha(rotulo: 'CPF', valor: formatarCpf(perfil.cpf!)),
          if (perfil.cnpj != null)
            _Linha(rotulo: 'CNPJ', valor: formatarCnpj(perfil.cnpj!)),
          const SizedBox(height: Espaco.sm),
          if (perfil.cpf != null)
            Text(
              'O CPF não é editável e não aparece para mais ninguém: é a chave '
              'que liga sua conta à lista de alunos da instituição.',
              style: tema.textTheme.muted,
            ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(rotulo, style: tema.textTheme.muted),
          ),
          Expanded(child: Text(valor, style: tema.textTheme.small)),
        ],
      ),
    );
  }
}
