import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_profile_model.dart';

class BuscaUsersController {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<List<UserProfile>> buscarPorUsername(String username) async {
    if (username.isEmpty) return [];
    
    try {
      
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: username.toLowerCase())
          .where('username', isLessThan: '${username.toLowerCase()}z')
          .limit(10)
          .get();

      List<UserProfile> usuarios = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final usuario = UserProfile.fromJson(data);
          usuarios.add(usuario);
        } catch (e) {
           rethrow;
        }
      }

      return usuarios;
    } catch (e) {
      return [];
    }
  }
}