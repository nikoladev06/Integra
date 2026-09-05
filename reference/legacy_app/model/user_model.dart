class UserModel {
  final String uid;
  final String email;
  final String nomeCompleto;
  final String username;
  final String universidade;
  final String curso;
  final String telefone;
  final String? profileImage;
  final DateTime dataCriacao;
  final DateTime? dataAlteracao;

  UserModel({
    required this.uid,
    required this.email,
    required this.nomeCompleto,
    required this.username,
    required this.universidade,
    required this.curso,
    required this.telefone,
    this.profileImage,
    DateTime? dataCriacao,
    this.dataAlteracao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  // Converter para JSON para salvar no Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nomeCompleto': nomeCompleto,
      'username': username,
      'universidade': universidade,
      'curso': curso,
      'telefone': telefone,
      'profileImage': profileImage,
      'dataCriacao': dataCriacao,
      'dataAlteracao': dataAlteracao,
    };
  }

  // Criar UserModel a partir do JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      nomeCompleto: json['nomeCompleto'] ?? '',
      username: json['username'] ?? '',
      universidade: json['universidade'] ?? '',
      curso: json['curso'] ?? '',
      telefone: json['telefone'] ?? '',
      profileImage: json['profileImage'],
      dataCriacao: json['dataCriacao'] != null 
          ? DateTime.parse(json['dataCriacao']) 
          : DateTime.now(),
    );
  }
}