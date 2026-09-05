import 'package:flutter/material.dart';
import '../model/user_profile_model.dart';
import '../controller/feedeventos_controller.dart';
import '../controller/professionalfeed_controller.dart';
import '../model/postevento_model.dart';
import '../model/professionalpost_model.dart';

class BuscaUserView extends StatefulWidget {
  final UserProfile usuario;

  const BuscaUserView({super.key, required this.usuario});

  @override
  State<BuscaUserView> createState() => _BuscaUserViewState();
}

class _BuscaUserViewState extends State<BuscaUserView> {
  late FeedEventos _feedEventosController;
  late ProfessionalFeed _feedProfissionalController;
  List<Evento> _eventosDoUsuario = [];
  List<ProfessionalPost> _postsProfDoUsuario = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _feedEventosController = FeedEventos();
    _feedProfissionalController = ProfessionalFeed();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await Future.wait([
      _carregarEventosDoUsuario(),
      _carregarPostsDoUsuario(),
    ]);
  }

  Future<void> _carregarEventosDoUsuario() async {
    try {
      final todosEventos = await _feedEventosController.obterEventos();
      final eventosFiletrados = todosEventos
          .where((e) => e.user.uid == widget.usuario.uid)
          .toList();

      if (mounted) {
        setState(() {
          _eventosDoUsuario = eventosFiletrados;
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _carregarPostsDoUsuario() async {
    try {
      final todosPosts = await _feedProfissionalController.obterPostsProfissionais();
      final postsFiletrados = todosPosts
          .where((p) => p.user.uid == widget.usuario.uid)
          .toList();

      if (mounted) {
        setState(() {
          _postsProfDoUsuario = postsFiletrados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111112),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '@${widget.usuario.username}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Cabeçalho do perfil
                  Container(
                    color: const Color(0xFF1F1F20),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                widget.usuario.nomeCompleto[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.usuario.nomeCompleto,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '@${widget.usuario.username}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${widget.usuario.curso} • ${widget.usuario.universidade}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // EVENTOS
                  if (_eventosDoUsuario.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Eventos (${_eventosDoUsuario.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (_eventosDoUsuario.isNotEmpty) const SizedBox(height: 12),
                  if (_eventosDoUsuario.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _eventosDoUsuario.length,
                        itemBuilder: (context, index) {
                          final evento = _eventosDoUsuario[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context, evento);
                            },
                            child: Container(
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
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      evento.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                      maxLines: 2,
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
                                          '${evento.date.day}/${evento.date.month}/${evento.date.year}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (_eventosDoUsuario.isEmpty && _postsProfDoUsuario.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Este usuário ainda não criou conteúdo',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  // POSTS PROFISSIONAIS
                  if (_postsProfDoUsuario.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Posts Profissionais (${_postsProfDoUsuario.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (_postsProfDoUsuario.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _postsProfDoUsuario.length,
                        itemBuilder: (context, index) {
                          final post = _postsProfDoUsuario[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context, post);
                            },
                            child: Container(
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
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
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}