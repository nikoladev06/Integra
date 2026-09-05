import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_profile_model.dart';
import '../model/user_model.dart';
import '../model/postevento_model.dart';
import '../model/professionalpost_model.dart';

class UserProfileController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Obter dados do usuário atual
  Future<UserProfile?> obterPerfilAtual() async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        return null;
      }

      DocumentSnapshot doc =
          await _firebaseFirestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Atualizar dados do usuário
  Future<bool> atualizarPerfil(
    String nomeCompleto,
    String username,
    String universidade,
    String curso,
  ) async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        throw 'Usuário não autenticado';
      }

      // Validações
      if (nomeCompleto.isEmpty || nomeCompleto.split(' ').length < 2) {
        throw 'Nome completo deve ter pelo menos 2 nomes';
      }

      if (username.isEmpty || username.length < 3) {
        throw 'Username deve ter pelo menos 3 caracteres';
      }

      if (universidade.isEmpty) {
        throw 'Universidade é obrigatória';
      }

      if (curso.isEmpty) {
        throw 'Curso é obrigatório';
      }

      // Verificar se novo username já existe (se foi alterado)
      UserProfile? perfilAtual = await obterPerfilAtual();
      if (perfilAtual?.username != username.toLowerCase()) {
        bool usernameExiste = await _usernameJaExiste(username);
        if (usernameExiste) {
          throw 'Username já existe';
        }
      }

      await _firebaseFirestore.collection('users').doc(user.uid).update({
        'nomeCompleto': nomeCompleto,
        'username': username.toLowerCase(),
        'universidade': universidade,
        'curso': curso,
        'alteradoEm': DateTime.now(),
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar senha
  Future<bool> atualizarSenha(
    String senhaAtual,
    String novaSenha,
    String confirmarSenha,
  ) async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        throw 'Usuário não autenticado';
      }

      // Validações
      if (senhaAtual.isEmpty) {
        throw 'Senha atual é obrigatória';
      }

      if (novaSenha.isEmpty || novaSenha.length < 6) {
        throw 'Nova senha deve ter pelo menos 6 caracteres';
      }

      if (novaSenha != confirmarSenha) {
        throw 'As senhas não correspondentem';
      }

      if (senhaAtual == novaSenha) {
        throw 'A nova senha deve ser diferente da atual';
      }

      // Reautenticar usuário
      String email = user.email ?? '';
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: senhaAtual,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(novaSenha);

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'Senha atual está incorreta';
      }
      throw 'Erro ao atualizar senha: ${e.message}';
    } catch (e) {
      rethrow;
    }
  }

  // Obter posts de eventos do usuário
  Future<List<Evento>> obterPostsEventos() async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        return [];
      }

      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('eventos')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();


      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<Evento> eventos = [];
      
      for (var doc in snapshot.docs) {
        
        try {
          final userModel = UserModel(
            uid: doc['userId'] ?? '',
            email: doc['userId'] ?? '',
            nomeCompleto: doc['nomeCompleto'] ?? 'Usuário',
            username: doc['username'] ?? 'usuario',
            universidade: 'FATEC RP',
            curso: 'ADS',
            telefone: '',
          );

          final evento = Evento(
            id: doc['id'] ?? 0,
            title: doc['title'] ?? '',
            description: doc['description'] ?? '',
            date: doc['date'] != null
                ? (doc['date'] as Timestamp).toDate()
                : DateTime.now(),
            location: doc['location'] ?? '',
            imageUrl: doc['imageUrl'] ?? '',
            user: userModel,
            createdAt: doc['createdAt'] != null
                ? (doc['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            isLiked: doc['isLiked'] ?? false,
            likesCount: doc['likesCount'] ?? 0,
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

  // Obter posts profissionais do usuário
  Future<List<ProfessionalPost>> obterPostsProfissionais() async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        return [];
      }

      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('posts_profissionais')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();


      List<ProfessionalPost> posts = [];
      
      for (var doc in snapshot.docs) {
        try {
          final userModel = UserModel(
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
            user: userModel,
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

  // Deletar post de evento
  Future<bool> deletarPostEvento(int postId) async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user == null) throw 'Usuário não autenticado';

      //BUSCA PELO ID NUMÉRICO NO CAMPO 'id'
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('eventos')
          .where('id', isEqualTo: postId)
          .where('userId', isEqualTo: user.uid)
          .get();


      if (snapshot.docs.isEmpty) {
        return false;
      }

      // DELETA CADA DOCUMENTO ENCONTRADO
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Deletar post profissional
  Future<bool> deletarPostProfissional(int postId) async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user == null) throw 'Usuário não autenticado';

      await _firebaseFirestore
          .collection('posts_profissionais')
          .where('id', isEqualTo: postId)
          .where('userId', isEqualTo: user.uid)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> atualizarPostEvento(Evento evento) async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user == null) throw 'Usuário não autenticado';

      await _firebaseFirestore
          .collection('eventos')
          .where('id', isEqualTo: evento.id)
          .where('userId', isEqualTo: user.uid)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({
            'title': evento.title,
            'description': evento.description,
            'location': evento.location,
          });
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> atualizarPostProfissional(ProfessionalPost post) async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user == null) throw 'Usuário não autenticado';

      await _firebaseFirestore
          .collection('posts_profissionais')
          .where('id', isEqualTo: post.id)
          .where('userId', isEqualTo: user.uid)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({
            'description': post.description,
          });
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Fazer logout
  Future<bool> fazerLogout() async {
    try {
      await _firebaseAuth.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verificar username único
  Future<bool> _usernameJaExiste(String username) async {
    try {
      final query = await _firebaseFirestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}