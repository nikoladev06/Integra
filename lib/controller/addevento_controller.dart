// controller/addevento_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/place_details_model.dart';

class AddEventoController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<bool> criarEventoComPlaceDetails(
    BuildContext context,
    String titulo,
    String descricao,
    DateTime? data,
    PlaceDetails? placeDetails,
  ) async {
    try {
      User? user = _firebaseAuth.currentUser;

      String? erroValidacao;
    
      if (user == null) {
        erroValidacao = 'Usuário não autenticado. Faça login novamente.';
      } else if (titulo.isEmpty) {
        erroValidacao = 'Título é obrigatório';
      } else if (descricao.isEmpty) {
        erroValidacao = 'Descrição é obrigatória';
      } else if (data == null) {
        erroValidacao = 'Data é obrigatória';
      } else if (placeDetails == null || placeDetails.formattedAddress.isEmpty) {
        erroValidacao = 'Localização é obrigatória';
      } else if (data.isBefore(DateTime.now())) {
        erroValidacao = 'A data do evento não pode ser no passado';
      }

      if (erroValidacao != null) {
        _mostrarSnackBarErro(context, erroValidacao);
        return false;
      }

      User userNonNull = user!;
      DateTime dataNonNull = data!;

      // Obter dados do usuário
      DocumentSnapshot userDoc =
          await _firebaseFirestore.collection('users').doc(userNonNull.uid).get();

      if (!userDoc.exists) {
        _mostrarSnackBarErro(context, 'Perfil do usuário não encontrado');
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Gerar ID único para o evento
      int eventoId = DateTime.now().millisecondsSinceEpoch;

      // Criar documento do evento
      await _firebaseFirestore.collection('eventos').add({
        'id': eventoId,
        'userId': userNonNull.uid,
        'title': titulo,
        'description': descricao,
        'date': Timestamp.fromDate(dataNonNull),
        'location': placeDetails!.formattedAddress, 
        'latitude': placeDetails.latitude,    
        'longitude': placeDetails.longitude,      
        'imageUrl': '',
        'nomeCompleto': userData['nomeCompleto'] ?? '',
        'username': userData['username'] ?? '',
        'createdAt': Timestamp.now(),
        'isLiked': false,
        'likesCount': 0,
        'comentarios': [],
      });

      _mostrarSnackBarSucesso(context, 'Evento criado com sucesso!');
      return true;
    } catch (e) {
      _mostrarSnackBarErro(context, 'Erro ao criar evento: $e');
      return false;
    }
  }

  // O método criarEvento antigo foi removido para evitar confusão.

  // SNACKBAR PARA ERROS (Vermelho)
  void _mostrarSnackBarErro(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red[800],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // SNACKBAR PARA DICAS (Azul)
  // void _mostrarSnackBarDica(BuildContext context, String mensagem) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(mensagem),
  //       backgroundColor: Colors.blue[800],
  //       duration: const Duration(seconds: 4),
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //     ),
  //   );
  // }

  // SNACKBAR PARA SUCESSO (Verde)
  void _mostrarSnackBarSucesso(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green[800],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}