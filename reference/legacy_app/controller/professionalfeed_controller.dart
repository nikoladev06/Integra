import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/professionalpost_model.dart';
import '../model/user_model.dart';

class ProfessionalFeed {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<List<ProfessionalPost>> obterPostsProfissionais() async {
    try {
      
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('posts_profissionais')
          .orderBy('createdAt', descending: true)
          .get();

      
      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<ProfessionalPost> posts = [];
      
      for (var doc in snapshot.docs) {

        try {
          final user = UserModel(
            uid: doc['userId'] ?? '',
            email: doc['userId'] ?? '',
            nomeCompleto: doc['nomeCompleto'] ?? 'Usuário',
            username: doc['username'] ?? 'usuario',
            universidade: 'FATEC RP',
            curso: 'ADS',
            telefone: '',
          );
          
          final post = ProfessionalPost(
            id: doc['id'] ?? 0,
            title: doc['title'] ?? '',
            description: doc['description'] ?? '',
            company: doc['company'] ?? '',
            user: user,
            createdAt: doc['createdAt'] != null
                ? (doc['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            isLiked: doc['isLiked'] ?? false,
            likesCount: doc['likesCount'] ?? 0,
            comentarios: [],
          );
          
          posts.add(post);
        } catch (e) {
          rethrow;
        }
      }
      
      return posts;
    } catch (e) {
      return [];
    }
  }
}