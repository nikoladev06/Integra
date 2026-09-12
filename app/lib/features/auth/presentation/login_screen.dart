import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/config/ambiente.dart';
import 'package:integra/core/error/failure.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/auth/domain/auth_validators.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/profile/data/fixtures.dart';

/// Entrada no app.
///
/// A validação vem de `auth_validators.dart`, extraído do protótipo na Sprint 0
/// — as mesmas mensagens que o `auth-service` vai devolver em Pydantic. O campo
/// erra localmente com o mesmo texto que erraria vindo do servidor.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formulario = GlobalKey<ShadFormState>();
  bool _enviando = false;
  String? _erroGeral;

  Future<void> _entrar() async {
    setState(() => _erroGeral = null);

    if (!(_formulario.currentState?.saveAndValidate() ?? false)) return;

    final valores = _formulario.currentState!.value;
    setState(() => _enviando = true);

    try {
      await ref.read(sessaoProvider.notifier).entrar(
        email: (valores['email'] as String?)?.trim() ?? '',
        senha: valores['senha'] as String? ?? '',
      );
      // Sem navegação aqui: o `redirect` do roteador observa a sessão e move o
      // usuário sozinho. Navegar à mão daqui competiria com a guarda.
    } on FalhaDeValidacao catch (falha) {
      // O servidor pode recusar o que o cliente aceitou. Mostra a mensagem dele.
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
    final cores = tema.colorScheme;

    // Motivo da volta ao login: sessão expirada, por exemplo.
    final sessao = ref.watch(sessaoProvider);
    final motivo = sessao is SessaoAusente ? sessao.motivo : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espaco.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ShadForm(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/logoappintegra.png', height: 64),
                    const SizedBox(height: Espaco.lg),
                    Text('Entrar', style: tema.textTheme.h2),
                    const SizedBox(height: Espaco.xs),
                    Text(
                      'Sua faculdade, sua turma e as vagas, em um lugar.',
                      style: tema.textTheme.muted,
                    ),
                    const SizedBox(height: Espaco.lg),

                    if (motivo != null) ...[
                      ShadAlert(
                        icon: const Icon(LucideIcons.info),
                        description: Text(motivo),
                      ),
                      const SizedBox(height: Espaco.md),
                    ],

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
                      id: 'senha',
                      label: const Text('Senha'),
                      placeholder: const Text('Sua senha'),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      validator: validarSenha,
                      onSubmitted: (_) => _entrar(),
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
                      onPressed: _enviando ? null : _entrar,
                      child: _enviando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Entrar'),
                    ),

                    const SizedBox(height: Espaco.lg),
                    // A recuperação de senha saiu do escopo, e a tela diz isso
                    // em vez de oferecer um link que não leva a nada.
                    Text(
                      'Esqueceu a senha? Procure a secretaria da sua '
                      'instituição — a redefinição por e-mail ainda não está '
                      'disponível.',
                      style: tema.textTheme.muted,
                      textAlign: TextAlign.center,
                    ),

                    const _AvisoDeFixtures(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: cores.background,
    );
  }
}

/// Mostra a credencial de exemplo quando o app roda sem backend.
///
/// Só aparece no modo de fixtures — em produção não existe conta de exemplo, e
/// o widget desaparece junto com ela.
class _AvisoDeFixtures extends StatelessWidget {
  const _AvisoDeFixtures();

  @override
  Widget build(BuildContext context) {
    if (!Ambiente.usarFalsos) return const SizedBox.shrink();

    final tema = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Espaco.lg),
      child: ShadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modo de demonstração', style: tema.textTheme.small),
            const SizedBox(height: Espaco.xs),
            Text(
              'Sem backend conectado. Entre com:\n'
              '${Fixtures.emailDemo}\n${Fixtures.senhaDemo}',
              style: tema.textTheme.muted,
            ),
          ],
        ),
      ),
    );
  }
}
