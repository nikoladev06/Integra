import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../controller/login_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
    final LoginController _controller = LoginController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _senhaController = TextEditingController();
    bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111112), // fundo dark
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'logoappintegra.png',
                height: 150,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 90),

              // E-mail
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'E-mail',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // Senha
              TextField(
                controller: _senhaController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Senha',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),

              //esqueceu senha
              SizedBox(
                width: double.infinity,
                child: RichText(
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    text: "Esqueci a senha",
                        style: const TextStyle(
                          color: Color(0xFF45b5b7),
                          fontSize: 18, // cor de destaque, tipo link
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline, // opcional
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navegar para a tela de recuperar a senha
                            Navigator.pushNamed(context, 'recuperar');
                          },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await _controller.fazerLogin(
                              context,
                              _emailController.text,
                              _senhaController.text,
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF45b5b7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(fontSize: 20),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Texto Cadastrar
              SizedBox(
                width: double.infinity,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "Não possui uma conta? ",
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    children: [
                      TextSpan(
                        text: "Cadastre-se",
                        style: const TextStyle(
                          color: Color(0xFF45b5b7), // cor de destaque, tipo link
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline, // opcional
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navegar para a tela de cadastro
                            Navigator.pushNamed(context, 'cadastrar');
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
}
