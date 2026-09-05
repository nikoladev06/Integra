import 'package:flutter/material.dart';
import '../controller/userprofile_controller.dart';
import '../model/user_profile_model.dart';
import '../model/postevento_model.dart';
import '../model/professionalpost_model.dart';
import 'edituserprofile_view.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final UserProfileController _controller = UserProfileController();
  UserProfile? _userProfile;
  List<Evento> _postsEventos = [];
  List<ProfessionalPost> _postsProfissionais = [];
  bool _isLoadingEventos = true;
  bool _isLoadingProfissionais = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await _carregarPerfil();
    await _carregarEventos();
    await _carregarPostsProfissionais();
  }

  Future<void> _carregarPerfil() async {
    try {
      UserProfile? perfil = await _controller.obterPerfilAtual();
      if (mounted) {
        setState(() {
          _userProfile = perfil;
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _carregarEventos() async {
    setState(() => _isLoadingEventos = true);
    try {
      List<Evento> eventos = await _controller.obterPostsEventos();
      if (mounted) {
        setState(() {
          _postsEventos = eventos;
          _isLoadingEventos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEventos = false);
      }
    }
  }

  Future<void> _carregarPostsProfissionais() async {
    setState(() => _isLoadingProfissionais = true);
    try {
      List<ProfessionalPost> posts =
          await _controller.obterPostsProfissionais();
      if (mounted) {
        setState(() {
          _postsProfissionais = posts;
          _isLoadingProfissionais = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfissionais = false);
      }
    }
  }

  void _deletarEvento(int eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F20),
        title: const Text('Deletar Evento', style: TextStyle(color: Colors.white)),
        content: const Text('Tem certeza que deseja deletar este evento?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              bool sucesso = await _controller.deletarPostEvento(eventId);
              
              if (sucesso && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evento deletado com sucesso')),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao deletar evento')),
                );
              }
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deletarPostProfissional(int postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F20),
        title: const Text('Deletar Post', style: TextStyle(color: Colors.white)),
        content: const Text('Tem certeza que deseja deletar este post?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool sucesso = await _controller.deletarPostProfissional(postId);
              if (sucesso && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deletado com sucesso')),
                );
                _carregarPostsProfissionais();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao deletar post')),
                );
              }
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editarEvento(Evento evento) {
    TextEditingController titleController = TextEditingController(text: evento.title);
    TextEditingController descriptionController = TextEditingController(text: evento.description);
    TextEditingController locationController = TextEditingController(text: evento.location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F20),
        title: const Text('Editar Evento', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Título',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF111112),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Descrição',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF111112),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Localização',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF111112),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
                Navigator.pop(context);

                final eventoAtualizado = Evento(
                  id: evento.id,
                  title: titleController.text,
                  description: descriptionController.text,
                  location: locationController.text,
                  date: evento.date,
                  latitude: evento.latitude,
                  longitude: evento.longitude,
                  user: evento.user,
                  isLiked: evento.isLiked,
                  likesCount: evento.likesCount,
                );

              bool sucesso = await _controller.atualizarPostEvento(eventoAtualizado);
              if (sucesso && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evento atualizado com sucesso')),
                );
                _carregarEventos();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao atualizar evento')),
                );
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _editarPostProfissional(ProfessionalPost post) { 
    TextEditingController titleController = TextEditingController(text: post.title);
    TextEditingController companyController = TextEditingController(text: post.company);
    TextEditingController descriptionController = TextEditingController(text: post.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F20),
        title: const Text('Editar Post', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Título',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF111112),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: companyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Empresa',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF111112),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Descrição',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF111112),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final postAtualizado = ProfessionalPost(
                id: post.id,
                title: titleController.text,
                description: descriptionController.text,
                company: companyController.text,
                user: post.user,
                isLiked: post.isLiked,
                likesCount: post.likesCount,
                createdAt: post.createdAt,
                imageUrl: post.imageUrl,
                comentarios: post.comentarios,
              );

              bool sucesso = await _controller.atualizarPostProfissional(postAtualizado);
              if (sucesso && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post atualizado com sucesso')),
                );
                _carregarPostsProfissionais();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao atualizar post')),
                );
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111112),
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F1F20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Seção de Perfil
            Container(
              color: const Color(0xFF1F1F20),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF6200EE),
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userProfile?.nomeCompleto ?? 'Usuário',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_userProfile?.username ?? 'usuario'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_userProfile?.universidade ?? 'FATEC'} - ${_userProfile?.curso ?? 'ADS'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _userProfile == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditUserProfileView(
                                    userProfile: _userProfile!,
                                  ),
                                ),
                              ).then((_) => _carregarPerfil());
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                      ),
                      child: const Text(
                        'Editar Perfil',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Abas de Posts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = 0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _currentIndex == 0
                                  ? const Color(0xFF6200EE)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Eventos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentIndex == 0
                                ? const Color(0xFF6200EE)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _currentIndex == 1
                                  ? const Color(0xFF6200EE)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Profissional',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentIndex == 1
                                ? const Color(0xFF6200EE)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Conteúdo das Abas
            _currentIndex == 0
                ? _buildEventosTab()
                : _buildProfissionalTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventosTab() {
    if (_isLoadingEventos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_postsEventos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento criado',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _postsEventos.length,
      itemBuilder: (context, index) {
        final evento = _postsEventos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  evento.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        evento.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${evento.date.day}/${evento.date.month}/${evento.date.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  // ],
                // ),
                // const SizedBox(height: 12),
                // Row(
                //   children: [
                    // Icon(
                    //   evento.isLiked ? Icons.favorite : Icons.favorite_outline,
                    //   size: 18,
                    //   color: evento.isLiked ? Colors.red : Colors.grey,
                    // ),
                    // const SizedBox(width: 4),
                    // Text(
                    //   '${evento.likesCount}',
                    //   style: const TextStyle(
                    //     fontSize: 12,
                    //     color: Colors.grey,
                    //   ),
                    // ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 18,
                      ),
                      onPressed: () => _editarEvento(evento),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () => _deletarEvento(evento.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfissionalTab() {
    if (_isLoadingProfissionais) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_postsProfissionais.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Nenhum post profissional criado',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _postsProfissionais.length,
      itemBuilder: (context, index) {
        final post = _postsProfissionais[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.business,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        post.company,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  // ],
                // ),
                // const SizedBox(height: 12),
                // Row(
                //   children: [
                    // Icon(
                    //   post.isLiked ? Icons.favorite : Icons.favorite_outline,
                    //   size: 18,
                    //   color: post.isLiked ? Colors.red : Colors.grey,
                    // ),
                    // const SizedBox(width: 4),
                    // Text(
                    //   '${post.likesCount}',
                    //   style: const TextStyle(
                    //     fontSize: 12,
                    //     color: Colors.grey,
                    //   ),
                    // ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 18,
                      ),
                      onPressed: () => _editarPostProfissional(post),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () => _deletarPostProfissional(post.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}