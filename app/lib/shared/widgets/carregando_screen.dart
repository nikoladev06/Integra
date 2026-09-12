import 'package:flutter/material.dart';

/// Tela de abertura, enquanto o app checa se há sessão guardada.
///
/// Existe para o login não piscar antes de entrar: sem este estado, quem abre
/// já autenticado vê a tela de login por um instante.
class CarregandoScreen extends StatelessWidget {
  const CarregandoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logoappintegra.png', height: 72),
            const SizedBox(height: 24),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
