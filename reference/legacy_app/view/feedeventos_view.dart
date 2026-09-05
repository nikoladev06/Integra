import 'package:flutter/material.dart';
import 'addevento_view.dart';

class FeedEventosView extends StatefulWidget {
  const FeedEventosView({super.key});

  @override
  State<FeedEventosView> createState() => _FeedEventosViewState();
}

class _FeedEventosViewState extends State<FeedEventosView> {
  void _criarEvento() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEventoView(),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111112),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 99, 99, 102),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, 'inicio');
          },
        ),
        title: const Text('Feed de Eventos', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF45b5b7)),
            onPressed: _criarEvento,
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Esta view não é mais usada. Use HomeView',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

}