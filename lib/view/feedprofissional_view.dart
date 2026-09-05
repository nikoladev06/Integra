import 'package:flutter/material.dart';
import 'addprofessionalpost_view.dart';

class ProfessionalFeedView extends StatefulWidget {
  const ProfessionalFeedView({super.key});

  @override
  State<ProfessionalFeedView> createState() => _ProfessionalFeedViewState();
}

class _ProfessionalFeedViewState extends State<ProfessionalFeedView> {
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
        title: const Text(
          'Vagas e Oportunidades',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF45b5b7)),
            onPressed: _createProfessionalPost,
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

  void _createProfessionalPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProfessionalPostView(),
      ),
    ).then((_) {
      setState(() {});
    });
  }
}