import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/profile/domain/password_change_validator.dart';

/// Troca de senha do usuário autenticado — `PUT /auth/password`.
///
/// **É o único caminho de mudança de senha no sistema**: não há recuperação por
/// e-mail, e o `auth-service` não emite token de reset. Exigir a senha atual é o
/// que impede que um token roubado sozinho baste para sequestrar a conta.
///
/// A troca revoga todas as sessões, inclusive a que a fez. A tela não esconde
/// isso: avisa antes e leva ao login depois, em vez de deixar o usuário
/// descobrir na próxima requisição que caiu.
class TrocarSenhaScreen extends ConsumerStatefulWidget {
  const TrocarSenhaScreen({super.key});

  @override
  ConsumerState<TrocarSenhaScreen> createState() => _TrocarSenhaScreenState();
}

class _TrocarSenhaScreenState extends ConsumerState<TrocarSenhaScreen> {
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmacao = TextEditingController();

  List<String> _erros = const [];
  String? _erroGeral;
  bool _enviando = false;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    // As regras vêm de `password_change_validator.dart`, extraído do protótipo
    // na Sprint 0, e devolvem a lista inteira de erros de uma vez — o
    // `auth-service` reproduz as mesmas mensagens em Pydantic.
    final erros = validarTrocaDeSenha(
      senhaAtual: _atual.text,
      novaSenha: _nova.text,
      confirmacao: _confirmacao.text,
    );

    setState(() {
      _erros = erros;
      _erroGeral = null;
    });
    if (erros.isNotEmpty) return;

    setState(() => _enviando = true);
    try {
      await ref.read(authRepositoryProvider).trocarSenha(
        senhaAtual: _atual.text,
        novaSenha: _nova.text,
        confirmacao: _confirmacao.text,
      );

      // Todas as sessões foram revogadas, inclusive esta. Sair daqui é o estado
      // honesto: o token que ainda está em memória não vale mais nada.
      await ref.read(sessaoProvider.notifier).sair();
    } on FalhaDeValidacao catch (falha) {
      setState(() => _erros = falha.campos.values.expand((e) => e).toList());
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
        title: const Text('Trocar senha'),
        backgroundColor: tema.colorScheme.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espaco.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ShadAlert(
                    icon: Icon(LucideIcons.info),
                    description: Text(
                      'Trocar a senha encerra todas as sessões, inclusive esta. '
                      'Você vai precisar entrar de novo.',
                    ),
                  ),
                  const SizedBox(height: Espaco.lg),

                  ShadInput(
                    controller: _atual,
                    placeholder: const Text('Senha atual'),
                    obscureText: true,
                  ),
                  const SizedBox(height: Espaco.md),
                  ShadInput(
                    controller: _nova,
                    placeholder: const Text('Nova senha'),
                    obscureText: true,
                  ),
                  const SizedBox(height: Espaco.md),
                  ShadInput(
                    controller: _confirmacao,
                    placeholder: const Text('Confirme a nova senha'),
                    obscureText: true,
                    onSubmitted: (_) => _enviar(),
                  ),

                  if (_erros.isNotEmpty) ...[
                    const SizedBox(height: Espaco.md),
                    ShadAlert.destructive(
                      icon: const Icon(LucideIcons.circleAlert),
                      description: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // Todos os erros de uma vez, e não o primeiro: corrigir
                        // um por vez, com uma requisição entre cada, é o que o
                        // protótipo fazia.
                        children: [for (final erro in _erros) Text('• $erro')],
                      ),
                    ),
                  ],
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
                        : const Text('Trocar senha'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
