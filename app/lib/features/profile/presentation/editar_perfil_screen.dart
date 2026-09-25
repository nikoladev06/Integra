import 'package:flutter/material.dart';
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
  String? _erroGeral;
  String? _aviso;

  Future<void> _executar(
    Future<Perfil> Function() acao, {
    String? aviso,
  }) async {
    setState(() {
      _erroGeral = null;
      _aviso = null;
      _salvando = true;
    });
    try {
      // O perfil volta da mesma chamada que o alterou, e a sessão passa a
      // carregar o novo — sem refazer login e sem uma segunda requisição.
      ref.read(sessaoProvider.notifier).atualizarPerfil(await acao());
      if (mounted) setState(() => _aviso = aviso);
    } on FalhaDeValidacao catch (falha) {
      setState(() => _erroGeral = falha.campos.values.firstOrNull?.firstOrNull);
    } on Failure catch (falha) {
      setState(() => _erroGeral = falha.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _salvar() async {
    if (!(_formulario.currentState?.saveAndValidate() ?? false)) return;

    final valores = _formulario.currentState!.value;
    final repo = ref.read(profileRepositoryProvider);

    await _executar(
      () => repo.atualizarMeuPerfil(
        nomeCompleto: (valores['nomeCompleto'] as String).trim(),
        username: (valores['username'] as String).trim(),
        telefone: (valores['telefone'] as String).trim(),
        bio: (valores['bio'] as String?)?.trim() ?? '',
      ),
      aviso: 'Perfil atualizado.',
    );
    if (mounted && _erroGeral == null) context.pop();
  }

  Future<void> _declararFormacao(String universidadeId, String cursoId) async {
    final repo = ref.read(profileRepositoryProvider);
    await _executar(() async {
      await repo.declararFormacao(
        universidadeId: universidadeId,
        cursoId: cursoId,
      );
      // Recarrega o perfil inteiro: a rota de formação devolve só a linha
      // criada, e a tela mostra a lista.
      return repo.meuPerfil();
    }, aviso: 'Formação adicionada. Ela não concede acesso — o vínculo é que concede.');
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
      aviso:
          'Vínculo encerrado. A formação continua verificada — você estudou lá.',
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
            if (_aviso != null) ...[
              ShadAlert(
                icon: const Icon(LucideIcons.info),
                description: Text(_aviso!),
              ),
              const SizedBox(height: Espaco.md),
            ],
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
