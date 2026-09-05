import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/postevento_model.dart';
import '../model/user_model.dart';

class FeedEventos {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<List<Evento>> obterEventos() async {
    try {
      
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('eventos')
          .orderBy('createdAt', descending: true)
          .get();

      
      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<Evento> eventos = [];
      
      for (var doc in snapshot.docs) {
        
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          final user = UserModel(
            uid: data['userId'] ?? '', 
            email: data['userId'] ?? '',
            nomeCompleto: data['nomeCompleto'] ?? 'Usuário',
            username: data['username'] ?? 'usuario',
            universidade: 'FATEC RP',
            curso: 'ADS',
            telefone: '',
          );
          
          final evento = Evento(
            id: data['id'] ?? 0,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            date: data['date'] != null 
                ? (data['date'] as Timestamp).toDate()
                : DateTime.now(),
            location: data['location'] ?? '',
            latitude: data['latitude']?.toDouble(),  
            longitude: data['longitude']?.toDouble(), 
            imageUrl: data['imageUrl'] ?? '',
            user: user,
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            isLiked: data['isLiked'] ?? false,
            likesCount: data['likesCount'] ?? 0,
            comentarios: [],
          );
          
          eventos.add(evento);
        } catch (e) {
          rethrow;
        }
      }
      
      return eventos;
    } catch (e) {
      return [];
    }
  }
}