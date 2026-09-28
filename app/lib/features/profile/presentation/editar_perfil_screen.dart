import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/auth/domain/auth_validators.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/institution/presentation/widgets/seletor_de_formacao.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/presentation/widgets/formacoes_e_vinculo.dart';
import 'package:integra/shared/domain/documentos.dart';

/// Edição do próprio perfil — `PATCH /users/me` mais as rotas de formação.
///
/// O formulário mudou de forma na v2. No protótipo eram dois campos de texto
/// livre, universidade e curso, e editá-los mudava tanto o que o perfil exibia
/// quanto o que o usuário conseguia ler. Agora:
///
/// - os dados de conta (nome, username, telefone, bio) vão num `PATCH`;
/// - **formação** é uma lista, com rota própria para declarar e remover;
/// - **vínculo** não se edita aqui. Ele não é um campo — nasce do CPF conferido
///   contra a lista da instituição, e o que se pode fazer com ele daqui é
///   encerrar.
///
/// E-mail e CPF não aparecem: o e-mail é credencial e pertence ao
/// `auth-service`; o CPF é a chave que liga a conta às matrículas, e deixá-lo
/// editável permitiria assumir a matrícula de outra pessoa.
class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _formulario = GlobalKey<ShadFormState>();

  bool _salvando = false;

  /// Erro que não pertence a um campo — conflito de username, rede, 500.
  ///
  /// Fica no corpo da tela, e não em toast, porque o usuário precisa dele **à
  /// vista enquanto corrige**. O oposto da confirmação de sucesso, que é toast
  /// justamente porque a tela fecha em seguida.
  String? _erroGeral;

  /// Roda a ação, atualiza a sessão, e devolve **se deu certo**.
  ///
  /// Devolve um booleano em vez de só mexer no estado porque quem chama precisa
  /// decidir o que vem depois — e no caso de salvar, o que vem depois é fechar a
  /// tela, o que muda de onde a confirmação pode ser mostrada.
  Future<bool> _executar(
    Future<Perfil> Function() acao, {
    String? aviso,
  }) async {
    setState(() {
      _erroGeral = null;
      _salvando = true;
    });
    try {
      // O perfil volta da mesma chamada que o alterou, e a sessão passa a
      // carregar o novo — sem refazer login e sem uma segunda requisição.
      ref.read(sessaoProvider.notifier).atualizarPerfil(await acao());

      // As ações que **não** fecham a tela confirmam daqui: declarar formação,
      // remover formação, encerrar vínculo. Salvar confirma de fora, depois do
      // `pop` — ver `_salvar`.
      if (mounted && aviso != null) {
        ShadToaster.of(context).show(
          ShadToast(title: const Text('Pronto'), description: Text(aviso)),
        );
      }
      return true;
    } on FalhaDeValidacao catch (falha) {
      setState(() => _erroGeral = falha.campos.values.firstOrNull?.firstOrNull);
    } on Failure catch (falha) {
      setState(() => _erroGeral = falha.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
    return false;
  }

  Future<void> _salvar() async {
    if (!(_formulario.currentState?.saveAndValidate() ?? false)) return;

    final valores = _formulario.currentState!.value;
    final repo = ref.read(profileRepositoryProvider);

    // O toaster é resolvido **agora**, com a tela montada, porque a confirmação vem
    // depois do `pop` — e depois do `pop` este `context` já não serve.
    //
    // A ordem importa e foi medida: mostrando o toast antes de fechar, o `pop`
    // seguinte fechava o **toast** e o formulário continuava aberto. Com a
    // confirmação depois, as duas coisas acontecem.
    final toaster = ShadToaster.of(context);

    final deuCerto = await _executar(
      () => repo.atualizarMeuPerfil(
        nomeCompleto: (valores['nomeCompleto'] as String).trim(),
        username: (valores['username'] as String).trim(),
        telefone: (valores['telefone'] as String).trim(),
        bio: (valores['bio'] as String?)?.trim() ?? '',
      ),
    );

    if (!deuCerto || !mounted) return;

    // **Esperar o fim do frame antes de fechar, e a razão é sutil.**
    //
    // Salvar atualiza a sessão, e a sessão é o `refreshListenable` do go_router: a
    // notificação faz o roteador reavaliar a rota atual, o que **reconstrói a pilha
    // a partir da URI**. Um `pop` feito antes disso é desfeito — a tela reaparecia,
    // e foi o que aconteceu desde a Sprint 3, sem ninguém notar porque nenhum teste
    // afirmava o fechamento.
    //
    // A notificação do Riverpod chega numa microtarefa, e microtarefas drenam antes
    // do próximo frame. Esperar o fim do frame põe as duas coisas em ordem definida
    // — refresh primeiro, `pop` depois — em vez de deixá-las correndo juntas.
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;

    context.pop();
    toaster.show(
      const ShadToast(
        title: Text('Salvo'),
        description: Text('Suas alterações foram gravadas.'),
      ),
    );
  }

  Future<void> _declararFormacao(String universidadeId, String cursoId) async {
    final repo = ref.read(profileRepositoryProvider);
    await _executar(
      () async {
        await repo.declararFormacao(
          universidadeId: universidadeId,
          cursoId: cursoId,
        );
        // Recarrega o perfil inteiro: a rota de formação devolve só a linha
        // criada, e a tela mostra a lista.
        return repo.meuPerfil();
      },
      aviso: 'Formação adicionada. Ela não concede acesso — o vínculo é que concede.',
    );
  }

  Future<void> _removerFormacao(Formacao formacao) async {
    final repo = ref.read(profileRepositoryProvider);
    await _executar(() async {
      await repo.removerFormacao(formacao.id);
      return repo.meuPerfil();
    }, aviso: 'Formação removida.');
  }

  Future<void> _encerrarVinculo() async {
    final repo = ref.read(profileRepositoryProvider);
    await _executar(
      () async {
        await repo.encerrarVinculo();
        return repo.meuPerfil();
      },
      aviso: 'Vínculo encerrado. A formação continua verificada — você estudou lá.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final perfil = ref.watch(perfilAtualProvider);

    if (perfil == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      backgroundColor: tema.colorScheme.background,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: tema.colorScheme.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Espaco.md),
          children: [
            if (_erroGeral != null) ...[
              ShadAlert.destructive(
                icon: const Icon(LucideIcons.circleAlert),
                description: Text(_erroGeral!),
              ),
              const SizedBox(height: Espaco.md),
            ],

            ShadForm(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Os dois travados vêm primeiro, como campos e não como cartão à
                  // parte: quem abre a tela vê a conta inteira num lugar só, e o
                  // que não se mexe se parece com o que se mexe — até tentar.
                  _CampoTravado(
                    rotulo: 'E-mail',
                    valor: perfil.email ?? '',
                    motivo:
                        'O e-mail não pode ser alterado: ele é a credencial com '
                        'que você entra.',
                  ),
                  const SizedBox(height: Espaco.md),
                  if (perfil.cpf != null) ...[
                    _CampoTravado(
                      rotulo: 'CPF',
                      valor: formatarCpf(perfil.cpf!),
                      motivo:
                          'O CPF não pode ser alterado: é a chave que liga sua '
                          'conta à lista de alunos da instituição. Se fosse '
                          'editável, daria para assumir a matrícula de outra '
                          'pessoa.',
                    ),
                    const SizedBox(height: Espaco.md),
                  ],
                  if (perfil.cnpj != null) ...[
                    _CampoTravado(
                      rotulo: 'CNPJ',
                      valor: formatarCnpj(perfil.cnpj!),
                      motivo:
                          'O CNPJ não pode ser alterado: é ele que identifica a '
                          'organização no Integra, e foi por ele que esta conta '
                          'reivindicou a instituição.',
                    ),
                    const SizedBox(height: Espaco.md),
                  ],
                  ShadInputFormField(
                    id: 'nomeCompleto',
                    label: Text(
                      perfil.tipo.eInstitucional ? 'Nome' : 'Nome completo',
                    ),
                    initialValue: perfil.nomeCompleto,
                    textInputAction: TextInputAction.next,
                    validator: perfil.tipo.eInstitucional
                        ? validarNomeDaInstituicao
                        : validarNomeCompleto,
                  ),
                  const SizedBox(height: Espaco.md),
                  ShadInputFormField(
                    id: 'username',
                    label: const Text('Nome de usuário'),
                    initialValue: perfil.username,
                    textInputAction: TextInputAction.next,
                    validator: validarUsername,
                  ),
                  const SizedBox(height: Espaco.md),
                  ShadInputFormField(
                    id: 'telefone',
                    label: const Text('Telefone'),
                    initialValue: perfil.telefone ?? '',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: validarTelefone,
                  ),
                  const SizedBox(height: Espaco.md),
                  ShadInputFormField(
                    id: 'bio',
                    label: const Text('Bio'),
                    initialValue: perfil.bio ?? '',
                    maxLines: 3,
                    maxLength: 280,
                    validator: (valor) => valor.length > 280
                        ? 'Bio deve ter no máximo 280 caracteres'
                        : null,
                  ),
                  const SizedBox(height: Espaco.lg),
                  ShadButton(
                    onPressed: _salvando ? null : _salvar,
                    child: const Text('Salvar alterações'),
                  ),
                ],
              ),
            ),

            // Conta institucional não tem currículo nem vínculo: organização
            // não estuda em lugar nenhum.
            if (!perfil.tipo.eInstitucional) ...[
              const SizedBox(height: Espaco.lg),
              CartaoDeFormacoes(
                formacoes: perfil.formacoes,
                aoRemover: _salvando ? null : _removerFormacao,
                acao: ShadButton.outline(
                  leading: const Icon(LucideIcons.plus, size: 16),
                  onPressed: _salvando
                      ? null
                      : () => _abrirDialogoDeFormacao(context),
                  child: const Text('Declarar formação'),
                ),
              ),
              const SizedBox(height: Espaco.md),
              CartaoDeVinculo(
                vinculo: perfil.vinculo,
                acao: perfil.vinculo == null
                    ? null
                    : ShadButton.destructive(
                        onPressed: _salvando ? null : _encerrarVinculo,
                        child: const Text('Encerrar vínculo'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _abrirDialogoDeFormacao(BuildContext context) async {
    String? universidadeId;
    String? cursoId;

    final escolhido = await showShadDialog<bool>(
      context: context,
      builder: (dialogo) => StatefulBuilder(
        builder: (dialogo, redesenhar) => ShadDialog(
          title: const Text('Declarar formação'),
          description: const Text(
            'Entra no seu currículo sem verificação, como no LinkedIn. O selo '
            'só vem quando a instituição confirma pelo seu CPF.',
          ),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.of(dialogo).pop(false),
              child: const Text('Cancelar'),
            ),
            ShadButton(
              onPressed: universidadeId == null || cursoId == null
                  ? null
                  : () => Navigator.of(dialogo).pop(true),
              child: const Text('Declarar'),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Espaco.md),
            child: SeletorDeFormacao(
              universidadeId: universidadeId,
              cursoId: cursoId,
              opcional: false,
              aoMudar: (u, c) => redesenhar(() {
                universidadeId = u;
                cursoId = c;
              }),
            ),
          ),
        ),
      ),
    );

    if (escolhido == true && universidadeId != null && cursoId != null) {
      await _declararFormacao(universidadeId!, cursoId!);
    }
  }
}

/// Um campo que existe, mostra o valor, e **recusa a edição explicando por quê**.
///
/// Parece um campo e não um item de lista de propósito: o usuário chega a esta tela
/// procurando o que pode mudar, e um dado exibido como texto corrido ele lê como
/// "aqui não tem nada para mim". Um campo desabilitado responde a pergunta certa —
/// *este* eu não mexo, e o motivo aparece quando eu tento.
///
/// A mensagem vem no toque, e não como legenda fixa embaixo. Legenda ocupa espaço
/// permanente para explicar algo que a maioria nunca vai tentar; o toque é o momento
/// em que a pergunta existe. Foi o que substituiu o parágrafo "o e-mail é sua
/// credencial de acesso…", que ficava na tela para todos, sempre.
///
/// `GestureDetector` por fora com `HitTestBehavior.opaque`: um [ShadInput]
/// desabilitado não recebe toque nenhum, então sem o detector o campo seria um
/// pedaço morto de tela — e "não acontece nada" é indistinguível de defeito.
class _CampoTravado extends StatelessWidget {
  const _CampoTravado({
    required this.rotulo,
    required this.valor,
    required this.motivo,
  });

  final String rotulo;
  final String valor;

  /// Por que este campo não se edita. Cada um tem o seu — credencial, chave de
  /// matrícula, identidade da organização são três razões diferentes.
  final String motivo;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          ShadToaster.of(context)
              .show(ShadToast(title: Text(rotulo), description: Text(motivo))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(rotulo, style: tema.textTheme.small),
          const SizedBox(height: Espaco.xs),
          // `enabled: false` e não `readOnly`: o segundo deixa o campo com cara de
          // editável e o cursor aparece, o que promete uma edição que não vem.
          ShadInput(
            initialValue: valor,
            enabled: false,
            trailing: Icon(
              LucideIcons.lock,
              size: 14,
              color: tema.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
