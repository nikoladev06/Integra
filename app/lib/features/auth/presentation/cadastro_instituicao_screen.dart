import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/auth/domain/auth_validators.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// Cadastro de faculdade ou empresa — `POST /auth/register/instituicao`.
///
/// **Duas telas, uma rota.** O que muda entre faculdade e empresa é o texto e o
/// campo `sigla`, que só a faculdade usa; o corpo enviado é o mesmo, com `tipo`
/// diferente. Duas rotas quase idênticas divergiriam com o tempo.
///
/// Substitui o provisionamento manual do plano original: não existe conta de
/// administrador e não existe operador no caminho do cadastro. O que sustenta
/// isso é a conta **nascer pendente** — CNPJ é dado público, está no cadastro
/// aberto da Receita, e o número identifica a organização sem provar que quem
/// digitou a representa. Sem o estado pendente, consultar o CNPJ de uma
/// faculdade bastaria para distribuir formações "verificadas" no nome dela.
class CadastroInstituicaoScreen extends ConsumerStatefulWidget {
  const CadastroInstituicaoScreen({required this.tipo, super.key});

  final TipoConta tipo;

  bool get eFaculdade => tipo == TipoConta.faculdade;

  @override
  ConsumerState<CadastroInstituicaoScreen> createState() =>
      _CadastroInstituicaoScreenState();
}

class _CadastroInstituicaoScreenState
    extends ConsumerState<CadastroInstituicaoScreen> {
  final _formulario = GlobalKey<ShadFormState>();

  String? _erroGeral;
  bool _enviando = false;

  Future<void> _enviar() async {
    setState(() => _erroGeral = null);
    if (!(_formulario.currentState?.saveAndValidate() ?? false)) return;

    final valores = _formulario.currentState!.value;
    setState(() => _enviando = true);

    try {
      await ref.read(authRepositoryProvider).cadastrarInstituicao(
        tipo: widget.tipo,
        nome: (valores['nome'] as String).trim(),
        cnpj: valores['cnpj'] as String,
        email: (valores['email'] as String).trim(),
        username: (valores['username'] as String).trim(),
        senha: valores['senha'] as String,
        telefone: (valores['telefone'] as String).trim(),
        sigla: (valores['sigla'] as String?)?.trim(),
      );

      if (!mounted) return;
      context.go(
        Rotas.login,
        extra:
            'Conta criada e em análise. Você já pode entrar e editar o perfil; '
            'publicar e matricular liberam quando a ativação sair.',
      );
    } on FalhaDeValidacao catch (falha) {
      setState(() => _erroGeral = falha.campos.values.firstOrNull?.firstOrNull);
    } on Failure catch (falha) {
      setState(() => _erroGeral = falha.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final eFaculdade = widget.eFaculdade;

    return Scaffold(
      backgroundColor: tema.colorScheme.background,
      appBar: AppBar(
        title: Text(eFaculdade ? 'Cadastro de faculdade' : 'Cadastro de empresa'),
        backgroundColor: tema.colorScheme.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espaco.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ShadForm(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShadAlert(
                      icon: const Icon(LucideIcons.clock),
                      title: const Text('A conta entra em análise'),
                      description: Text(
                        eFaculdade
                            ? 'Você entra e edita o perfil assim que criar a '
                                  'conta. Publicar comunicados e cadastrar '
                                  'alunos liberam depois da ativação — é o que '
                                  'impede alguém de distribuir formações '
                                  'verificadas em nome da sua instituição.'
                            : 'Você entra e edita o perfil assim que criar a '
                                  'conta. Publicar vagas libera depois da '
                                  'ativação.',
                      ),
                    ),
                    const SizedBox(height: Espaco.lg),

                    ShadInputFormField(
                      id: 'nome',
                      label: Text(
                        eFaculdade ? 'Nome da instituição' : 'Nome da empresa',
                      ),
                      placeholder: Text(
                        eFaculdade
                            ? 'Faculdade de Tecnologia de Ribeirão Preto'
                            : 'Órbita Tecnologia',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: validarNomeDaInstituicao,
                    ),
                    const SizedBox(height: Espaco.md),

                    if (eFaculdade) ...[
                      ShadInputFormField(
                        id: 'sigla',
                        label: const Text('Sigla (opcional)'),
                        placeholder: const Text('FATEC RP'),
                        textInputAction: TextInputAction.next,
                        description: const Text(
                          'Rótulo curto nas listas e na busca. Em branco, as '
                          'iniciais do nome servem até você editar o perfil.',
                        ),
                      ),
                      const SizedBox(height: Espaco.md),
                    ],

                    ShadInputFormField(
                      id: 'cnpj',
                      label: const Text('CNPJ'),
                      placeholder: const Text('00.000.000/0001-00'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: validarCnpj,
                      description: Text(
                        eFaculdade
                            ? 'É o CNPJ que identifica a instituição: casando '
                                  'com uma já catalogada, sua conta assume '
                                  'aquela página — a mesma que os alunos já '
                                  'seguem.'
                            : 'Único por conta, e usado para identificar a '
                                  'empresa.',
                      ),
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'email',
                      label: const Text('E-mail'),
                      placeholder: const Text('contato@instituicao.edu.br'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: validarEmail,
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'username',
                      label: const Text('Nome de usuário'),
                      placeholder: Text(eFaculdade ? 'fatec_rp' : 'orbita_tech'),
                      textInputAction: TextInputAction.next,
                      validator: validarUsername,
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'telefone',
                      label: const Text('Telefone'),
                      placeholder: const Text('(16)3333-0000'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: validarTelefone,
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'senha',
                      label: const Text('Senha'),
                      placeholder: const Text('Pelo menos 6 caracteres'),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: validarSenha,
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'confirmacao',
                      label: const Text('Confirme a senha'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (valor) => validarConfirmacaoSenha(
                        _formulario.currentState?.value['senha'] as String?,
                        valor,
                      ),
                    ),

                    if (_erroGeral != null) ...[
                      const SizedBox(height: Espaco.md),
                      ShadAlert.destructive(
                        icon: const Icon(LucideIcons.circleAlert),
                        description: Text(_erroGeral!),
                      ),
                    ],

                    const SizedBox(height: Espaco.lg),
                    ShadButton(
                      onPressed: _enviando ? null : _enviar,
                      child: _enviando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Criar conta'),
                    ),
                    const SizedBox(height: Espaco.sm),
                    ShadButton.link(
                      onPressed: () => context.go(Rotas.cadastro),
                      child: const Text('Sou aluno, quero a outra conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
