import 'user_model.dart';

class Comentario {
  final int id;
  final UserModel user;
  final String text;
  final DateTime createdAt;

  Comentario({
    required this.id,
    required this.user,
    required this.text,
    required this.createdAt,
  });
}