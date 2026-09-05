import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../controller/recuperarsenha_controller.dart';

class RecuperarsenhaView extends StatefulWidget {
  const RecuperarsenhaView({super.key});

  @override
  State<RecuperarsenhaView> createState() => _RecuperarsenhaViewState();
}

class _RecuperarsenhaViewState extends State<RecuperarsenhaView> {
  final RecuperarsenhaController _controller = RecuperarsenhaController();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111112),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'logoappintegra.png',
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              const Text(
                'Recuperar Senha',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Digite seu e-mail para receber um link de recuperação',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'E-mail para recuperação',
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
              ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _controller.isLoading
                          ? null
                          : () {
                              _controller.recuperar(
                                context,
                                _emailController.text,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF45b5b7),
                        disabledBackgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Enviar e-mail',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "Voltou? ",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    children: [
                      TextSpan(
                        text: "Faça login",
                        style: const TextStyle(
                          color: Color(0xFF45b5b7),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacementNamed(context, 'login');
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
    _controller.dispose();
    super.dispose();
  }
}