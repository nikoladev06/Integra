import 'package:flutter/material.dart';
import '../controller/userprofile_controller.dart';
import '../model/user_profile_model.dart';
import '../controller/feedeventos_controller.dart' as feed_eventos;
import '../controller/professionalfeed_controller.dart' as feed_profissional;
import '../model/postevento_model.dart';
import '../model/professionalpost_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';



import 'userprofile_view.dart';
import 'addevento_view.dart';
import 'addprofessionalpost_view.dart';
import '../controller/buscausers_controller.dart';
import 'buscausers_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final UserProfileController _profileController = UserProfileController();
  final feed_eventos.FeedEventos _feedEventosController =
      feed_eventos.FeedEventos();
  final feed_profissional.ProfessionalFeed _feedProfissionalController =
      feed_profissional.ProfessionalFeed();
  final BuscaUsersController _buscaUsersController = BuscaUsersController();

  int _currentIndex = 0;
  late List<Evento> _eventosAtuais;
  late List<ProfessionalPost> _postsAtuais;
  bool _isLoadingEventos = true;
  UserProfile? _userProfile;
  bool _isLoadingProfissional = true;
  String _searchQuery = '';
  List<UserProfile> _searchResults = [];
  late ScrollController _scrollController; 

  @override
  void initState() {
    super.initState();
    _eventosAtuais = [];
    _postsAtuais = [];
    _scrollController = ScrollController();
    _carregarDados();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    await _carregarPerfil();
    await _carregarEventos();
    await _carregarPostsProfissionais();
  }

  Future<void> _carregarEventos() async {
  setState(() => _isLoadingEventos = true);
  
  try {
    // FORÇA UM NOVO FETCH DOS DADOS
    final novosEventos = await _feedEventosController.obterEventos();
        
    setState(() {
      _eventosAtuais = novosEventos;
      _isLoadingEventos = false;
    });
    
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingEventos = false);
    }
  }
}

  Future<void> _carregarPostsProfissionais() async {
    setState(() => _isLoadingProfissional = true);
    try {
      _postsAtuais =
          await _feedProfissionalController.obterPostsProfissionais();
      if (mounted) {
        setState(() => _isLoadingProfissional = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfissional = false);
      }
    }
  }

  Future<void> _carregarPerfil() async {
    try {
      UserProfile? perfil = await _profileController.obterPerfilAtual();
      if (mounted) {
        setState(() {
          _userProfile = perfil;
        });
      }
    } catch (e) {
      rethrow;   
    }
  }

  Widget _buildMapPreview(double? lat, double? lng, String location) {
    if (lat == null || lng == null) {
      // Fallback: mostrar apenas o texto da localização
      return Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              location,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini mapa preview
        GestureDetector(
          onTap: () {
            _mostrarDialogoMapa(location, lat, lng);
          },
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, color: Colors.grey, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    'Ver no Google Maps',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '(${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }


  void _mostrarDialogoMapa(String location, double lat, double lng) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1F1F20),
      title: const Row(
        children: [
          Icon(Icons.map, color: Colors.white),
          SizedBox(width: 8),
          Text('Localização', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(location, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Text('Coordenadas: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}', 
               style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          const SizedBox(height: 16),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EE)),
          onPressed: () async {
            final String url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
            try {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              } else {
                // SE NÃO ABRIR, OFERECE COPIAR
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Não foi possível abrir o mapa automaticamente'),
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Copiar Link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copiado!'), duration: Duration(seconds: 2)),
                        );
                      },
                    ),
                  ),
                );
              }
            } catch (e) {
              // EM CASO DE ERRO, OFERECE COPIAR
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Link do Maps: '),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Copiar Link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copiado!'), duration: Duration(seconds: 2)),
                      );
                    },
                  ),
                ),
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Abrir no Maps', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Pesquisar pelo username',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFF1F1F20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchResults = [];
                        });
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
            ),
            onChanged: (value) async {
              setState(() => _searchQuery = value);
              if (value.isNotEmpty) {
                final resultados =
                    await _buscaUsersController.buscarPorUsername(value);
                setState(() => _searchResults = resultados);
              } else {
                setState(() => _searchResults = []);
              }
            },
          ),
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final usuario = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      child: Text(
                        usuario.nomeCompleto[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      usuario.nomeCompleto,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '@${usuario.username}',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BuscaUserView(usuario: usuario),
                        ),
                        ).then((resultado) { 
                        if (resultado != null) {
                          if (resultado is Evento) {
                            // SE FOR EVENTO
                            setState(() {
                              _currentIndex = 0;
                              _searchQuery = '';
                              _searchResults = [];
                            });
                            
                            Future.delayed(const Duration(milliseconds: 300), () {
                              final indexEvento = _eventosAtuais.indexWhere((e) => e.id == resultado.id);
                              if (indexEvento != -1 && mounted && _scrollController.hasClients) {
                                _scrollController.animateTo(
                                  indexEvento * 250.0,
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOut,
                                );
                              }
                            });
                          } else if (resultado is ProfessionalPost) {
                            // SE FOR POST PROFISSIONAL
                            setState(() {
                              _currentIndex = 1;  // Muda para aba profissional
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          }
                        } else {
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        }
                      });
                    },
                  );
                },
              ),
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
          backgroundColor: const Color(0xFF1F1F20),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white), // Garante que a seta de voltar e outros ícones sejam brancos
          leading: Builder( // O leading é mantido para a lógica do drawer
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text(
            'Integra',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1F1F20),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF6200EE),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF6200EE),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userProfile?.nomeCompleto ?? 'Carregando...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile != null ? '@${_userProfile!.username}' : '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
// No drawer do HomeView - MODIFIQUE ASSIM:
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.grey),
              title: const Text('Perfil', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileView(),
                  ),
                ).then((_) {
                  
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _carregarEventos();
                      _carregarPostsProfissionais();
                    }
                  });
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Sair',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final homeContext = context;
                final bool? deveSair = await showDialog<bool>(
                  context: homeContext,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: const Color(0xFF1F1F20),
                    title: const Text(
                      'Sair',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'Você deseja sair da sua conta?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text(
                          'Sair',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (deveSair == true) {
                  final bool logoutSucesso = await _profileController.fazerLogout();
                  if (logoutSucesso && homeContext.mounted) {
                    Navigator.pushNamed(homeContext, 'inicio');
                  }
                }
              },
            ),
          ],
        ),
      ),

      body: Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildBody()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6200EE),
        onPressed: () async {
          if (_currentIndex == 0) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEventoView(),
              ),
            );
            if (result == true) {
              await _carregarEventos();
            }
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProfessionalPostView(),
              ),
            );
            if (result == true) {
              await _carregarPostsProfissionais();
            }
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1F1F20),
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF6200EE),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Profissional',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 0) {
      return _isLoadingEventos
          ? const Center(child: CircularProgressIndicator())
          : _eventosAtuais.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum evento ainda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarEventos,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _eventosAtuais.length,
                    itemBuilder: (context, index) {
                      final evento = _eventosAtuais[index];
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${evento.user.nomeCompleto} • @${evento.user.username}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
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
                              _buildMapPreview(evento.latitude, evento.longitude, evento.location),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
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
                                ],
                              ),
                              // const SizedBox(height: 12),
                              // Row(
                              //   children: [
                              //     Icon(
                              //       evento.isLiked
                              //           ? Icons.favorite
                              //           : Icons.favorite_outline,
                              //       size: 18,
                              //       color: evento.isLiked
                              //           ? Colors.red
                              //           : Colors.grey,
                              //     ),
                              //     const SizedBox(width: 4),
                              //     Text(
                              //       '${evento.likesCount}',
                              //       style: const TextStyle(
                              //         fontSize: 12,
                              //         color: Colors.grey,
                              //       ),
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
    } else {
      return _isLoadingProfissional
          ? const Center(child: CircularProgressIndicator())
          : _postsAtuais.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma oportunidade ainda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarPostsProfissionais,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _postsAtuais.length,
                    itemBuilder: (context, index) {
                      final post = _postsAtuais[index];
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.user.nomeCompleto} • @${post.user.username}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
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
                              // const SizedBox(height: 12),
                              // Row(
                              //   children: [
                              //     Icon(
                              //       post.isLiked
                              //           ? Icons.favorite
                              //           : Icons.favorite_outline,
                              //       size: 18,
                              //       color: post.isLiked
                              //           ? Colors.red
                              //           : Colors.grey,
                              //     ),
                              //     const SizedBox(width: 4),
                              //     Text(
                              //       '${post.likesCount}',
                              //       style: const TextStyle(
                              //         fontSize: 12,
                              //         color: Colors.grey,
                              //       ),
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
    }
  }
}