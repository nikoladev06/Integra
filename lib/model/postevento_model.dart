import 'user_model.dart';
import 'comentario_model.dart';

class Evento {
  final int id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final UserModel user;
  final DateTime createdAt;
  bool isLiked;
  int likesCount;
  List<Comentario> comentarios;

  Evento({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.user,
    DateTime? createdAt,
    this.isLiked = false,
    this.likesCount = 0,
    this.comentarios = const [],
  }) : createdAt = createdAt ?? DateTime.now();
}