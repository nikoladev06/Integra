import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class InicioView extends StatelessWidget {
  const InicioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111112), // Fundo preto (dark)
      body: SafeArea(
        child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 70), // Espaço superior

                // Logo
                Image.asset(
                  'logoappintegra.png', 
                  height: 225,
                  width: 225,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 5),

                 Text(
                    'Integra',
                    style: TextStyle(
                      color: const Color(0xFF45b5b7),
                      fontSize: 60,
                      fontWeight: FontWeight.w900, // Mais negrito
                      letterSpacing: 2.0, // Espaçamento entre letras
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 20),

                // Subtítulo
                const Text(
                  'Descubra. Participe. Integre-se!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Botão Login
                SizedBox(
                  height: 50,
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, 'login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF45b5b7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Login',
                    style: TextStyle(fontSize: 20)),
                  ),
                ),

                const SizedBox(height: 16),

                // Botão Cadastrar
                SizedBox(
                  height: 50,
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, 'cadastrar');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cadastro',
                    style: TextStyle(fontSize: 20)),
                  ),
                ),


                const SizedBox(height: 24),


                //Sobre
                SizedBox(
                width: double.infinity,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "Sobre",
                        style: const TextStyle(
                          color: Color(0xFF45b5b7),
                          fontSize: 16, // cor de destaque, tipo link
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline, // opcional
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navegar para a tela de cadastro
                            Navigator.pushNamed(context, 'sobre');
                          },
                  ),
                ),
              )


              ],
            ),
        ),
      ),
    );
  }
}
