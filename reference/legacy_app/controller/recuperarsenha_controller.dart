import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecuperarsenhaController extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // valida email
  String? validarEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'E-mail não pode ficar em branco';
    }

    if (!email.contains('@') || !email.contains('.')) {
      return 'Insira um e-mail válido';
    }

    return null;
  }

  Future<void> recuperar(BuildContext context, String email) async {
    // valida email
    final erroEmail = validarEmail(email);
    if (erroEmail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erroEmail)),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      
      await _firebaseAuth.sendPasswordResetEmail(email: email);
            
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail enviado com sucesso! Verifique sua caixa de entrada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navega de volta para login após 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, 'login');
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      
      String mensagem = 'Erro ao enviar e-mail';
      
      if (e.code == 'user-not-found') {
        mensagem = 'E-mail não cadastrado no sistema';
      } else if (e.code == 'invalid-email') {
        mensagem = 'E-mail inválido';
      } else if (e.code == 'too-many-requests') {
        mensagem = 'Muitas tentativas. Tente novamente mais tarde';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}