import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/auth/domain/auth_validators.dart';
import 'package:integra/features/institution/presentation/widgets/seletor_de_formacao.dart';

/// Cadastro de aluno — `POST /auth/register`.
///
/// Duas coisas mudaram em relação ao protótipo, e as duas vêm da revisão de
/// modelo da v2:
///
/// **CPF é obrigatório.** É a chave que liga a conta às matrículas que as
/// faculdades cadastram, e sem ele o vínculo não teria como nascer. Não é
/// editável depois — trocar o próprio CPF pelo de outra pessoa permitiria
/// assumir a matrícula dela.
///
/// **Universidade e curso são opcionais.** No protótipo eram obrigatórios e
/// texto livre; na v1 eram obrigatórios e concediam acesso aos posts internos da
/// instituição. Agora declarar é cosmético: quem preenche ganha uma linha de
/// currículo, não um vínculo.
class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  final _formulario = GlobalKey<ShadFormState>();

  String? _universidadeId;
  String? _cursoId;
  String? _erroDaFormacao;
  String? _erroGeral;
  bool _enviando = false;

  Future<void> _enviar() async {
    setState(() {
      _erroGeral = null;
      _erroDaFormacao = validarFormacaoDeclarada(
        universidadeId: _universidadeId,
        cursoId: _cursoId,
      );
    });

    final camposOk = _formulario.currentState?.saveAndValidate() ?? false;
    if (!camposOk || _erroDaFormacao != null) return;

    final valores = _formulario.currentState!.value;
    setState(() => _enviando = true);

    try {
      await ref.read(authRepositoryProvider).cadastrar(
        nomeCompleto: (valores['nomeCompleto'] as String).trim(),
        email: (valores['email'] as String).trim(),
        username: (valores['username'] as String).trim(),
        senha: valores['senha'] as String,
        telefone: (valores['telefone'] as String).trim(),
        cpf: valores['cpf'] as String,
        universidadeId: _universidadeId,
        cursoId: _cursoId,
      );

      if (!mounted) return;
      // O contrato não faz login automático, e a tela não finge que fez: volta
      // ao login com o aviso, em vez de deixar o usuário adivinhar se deu certo.
      context.go(Rotas.login, extra: 'Conta criada. Entre com seu e-mail e senha.');
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

    return Scaffold(
      backgroundColor: tema.colorScheme.background,
      appBar: AppBar(
        title: const Text('Criar conta'),
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
                    Text('Conta de aluno', style: tema.textTheme.h3),
                    const SizedBox(height: Espaco.xs),
                    Text(
                      'Para faculdade ou empresa, o cadastro é outro — o link '
                      'está no fim desta página.',
                      style: tema.textTheme.muted,
                    ),
                    const SizedBox(height: Espaco.lg),

                    ShadInputFormField(
                      id: 'nomeCompleto',
                      label: const Text('Nome completo'),
                      placeholder: const Text('Ana Paula Souza'),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: validarNomeCompleto,
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'email',
                      label: const Text('E-mail'),
                      placeholder: const Text('voce@faculdade.edu.br'),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: validarEmail,
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'username',
                      label: const Text('Nome de usuário'),
                      placeholder: const Text('ana_souza'),
                      textInputAction: TextInputAction.next,
                      validator: validarUsername,
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'cpf',
                      label: const Text('CPF'),
                      placeholder: const Text('000.000.000-00'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: validarCpf,
                      // Dito na tela porque é a pergunta que todo mundo faz, e
                      // porque a resposta é o que justifica pedir o número.
                      description: const Text(
                        'Usado só para a sua faculdade confirmar que você é '
                        'aluno dela. Não aparece no seu perfil.',
                      ),
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'telefone',
                      label: const Text('Telefone'),
                      placeholder: const Text('(16)99999-9999'),
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
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      validator: validarSenha,
                    ),
                    const SizedBox(height: Espaco.md),

                    ShadInputFormField(
                      id: 'confirmacao',
                      label: const Text('Confirme a senha'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      // Não vai no corpo da requisição: o contrato de
                      // `/auth/register` não tem este campo. É conferência de
                      // digitação, e o lugar dela é aqui.
                      validator: (valor) => validarConfirmacaoSenha(
                        _formulario.currentState?.value['senha'] as String?,
                        valor,
                      ),
                    ),
                    const SizedBox(height: Espaco.lg),

                    SeletorDeFormacao(
                      universidadeId: _universidadeId,
                      cursoId: _cursoId,
                      erro: _erroDaFormacao,
                      aoMudar: (universidadeId, cursoId) => setState(() {
                        _universidadeId = universidadeId;
                        _cursoId = cursoId;
                        _erroDaFormacao = null;
                      }),
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
                    const SizedBox(height: Espaco.md),
                    ShadButton.link(
                      onPressed: () => context.go(Rotas.login),
                      child: const Text('Já tenho conta'),
                    ),

                    const SizedBox(height: Espaco.lg),
                    const Divider(),
                    const SizedBox(height: Espaco.sm),
                    Text('Cadastro institucional', style: tema.textTheme.small),
                    const SizedBox(height: Espaco.xs),
                    Text(
                      'Faculdade e empresa se cadastram com CNPJ, em formulário '
                      'próprio. A conta entra em análise antes de poder publicar.',
                      style: tema.textTheme.muted,
                    ),
                    const SizedBox(height: Espaco.sm),
                    Row(
                      children: [
                        Expanded(
                          child: ShadButton.outline(
                            onPressed: () =>
                                context.push(Rotas.cadastroDeFaculdade),
                            child: const Text('Sou faculdade'),
                          ),
                        ),
                        const SizedBox(width: Espaco.sm),
                        Expanded(
                          child: ShadButton.outline(
                            onPressed: () =>
                                context.push(Rotas.cadastroDeEmpresa),
                            child: const Text('Sou empresa'),
                          ),
                        ),
                      ],
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
