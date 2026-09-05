import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CadastrarController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<bool> usernameJaExiste(String username) async {
    try {
      final query = await _firebaseFirestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      rethrow; 
    }
  }

  Future<bool> emailJaExiste(String email) async {
    try {
      final query = await _firebaseFirestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      rethrow; 
    }
  }

  Future<void> fazerCadastro(
    BuildContext context,
    String nomeCompleto,
    String email,
    String username,
    String universidade,
    String curso,
    String telefone,
    String senha,
    String confirmarSenha,
  ) async {
    try {

      // Validações
      if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
        throw 'Email inválido. Use o formato: usuario@exemplo.com';
      }
      
      if (nomeCompleto.isEmpty || nomeCompleto.split(' ').length < 2) {
        throw 'Nome completo deve ter pelo menos 2 nomes';
      }

      if (username.isEmpty || username.length < 3) {
        throw 'Username deve ter pelo menos 3 caracteres';
      }

      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        throw 'Username pode conter apenas letras, números e underscore';
      }

      if (universidade.isEmpty) {
        throw 'Universidade é obrigatória';
      }

      if (curso.isEmpty) {
        throw 'Curso é obrigatório';
      }

      if (senha.isEmpty || senha.length < 6) {
        throw 'Senha deve ter pelo menos 6 caracteres';
      }

      if (senha != confirmarSenha) {
        throw 'As senhas não correspondem';
      }

      if (telefone.isEmpty ||
        !RegExp(r'^\(?\d{2}\)?[\s-]?\d{4,5}-?\d{4}$').hasMatch(telefone)) {
        throw 'Telefone inválido. Use o formato (XX)XXXXX-XXXX ou XXXXXXXXXXX';
      }



      // Verificar email único
      bool emailExiste = await emailJaExiste(email);
      if (emailExiste) {
        throw 'Email já cadastrado';
      }

      // Verificar username único
      bool usernameExiste = await usernameJaExiste(username);
      if (usernameExiste) {
        throw 'Username já existe';
      }

      // Criar usuário no Firebase Auth
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: senha,
      );

      // Salvar dados no Firestore
      await _firebaseFirestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'nomeCompleto': nomeCompleto,
        'email': email.toLowerCase(),
        'username': username.toLowerCase(),
        'universidade': universidade,
        'curso': curso,
        'telefone': telefone,
        'profileImage': '',
        'criadoEm': DateTime.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login agora.')),
        );
        
        // Usar pop e push para garantir que navega
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushNamed('login');
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao cadastrar';

      if (e.code == 'weak-password') {
        mensagem = 'Senha muito fraca';
      } else if (e.code == 'email-already-in-use') {
        mensagem = 'Email já cadastrado';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Email inválido';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
    } on FirebaseException catch (e) { // Captura erros do Firestore (como permission-denied)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de permissão ao verificar dados. Verifique as regras do Firestore.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
