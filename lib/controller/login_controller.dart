import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginController extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // valida e-mail
  String? validarEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'E-mail não pode ficar em branco';
    }
    
    // Regex para validar email: usuario@dominio.extensao
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Insira um e-mail válido (ex: usuario@exemplo.com)';
    }
    
    return null;
  }

  // valida senha
  String? validarSenha(String? senha) {
    if (senha == null || senha.isEmpty) {
      return 'Senha não pode ficar em branco';
    }
    
    if (senha.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    
    return null;
  }

  // quando clicar no botão de login vai verificar
  Future<void> fazerLogin(BuildContext context, String email, String senha) async {
    // valida e-mail
    final erroEmail = validarEmail(email);
    if (erroEmail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erroEmail)),
      );
      return;
    }

    // valida senha
    final erroSenha = validarSenha(senha);
    if (erroSenha != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erroSenha)),
      );
      return;
    }

    try {
      // Faz login com Firebase
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );

      // se chegou aqui, ta tudo certo
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login realizado com sucesso!')),
        );
        
        // navega para a tela principal
        Navigator.pushReplacementNamed(context, 'principal');
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao fazer login';
      
      if (e.code == 'user-not-found') {
        mensagem = 'Usuário não encontrado';
      } else if (e.code == 'wrong-password') {
        mensagem = 'Senha incorreta';
      } else if (e.code == 'invalid-credential') {
        mensagem = 'E-mail ou senha incorretos';
      } else if (e.code == 'user-disabled') {
        mensagem = 'Usuário desabilitado';
      } else if (e.code == 'too-many-requests') {
        mensagem = 'Muitas tentativas. Tente mais tarde';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer login: ${e.toString()}')),
        );
      }
    }
  }
}