import 'package:flutter/material.dart';

class SobreView extends StatefulWidget {
  const SobreView({super.key});

  @override
  State<SobreView> createState() => _SobreViewState();
}

class _SobreViewState extends State<SobreView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111112),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // cabeçalho
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF45b5b7),
                child: Icon(Icons.info, color: Colors.white, size: 40),
              ),
              
              const SizedBox(height: 60),
              
              // balão
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre o App',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 10),
                    Text(
                      'O Integra é uma rede social com o objetivo de facilitar a conexão entre estudantes, permitindo a divulgação de eventos (principalmente relacionados a estudos e faculdades) e vagas/posts relacionados ao mercado de trabalho (com foco em vagas de estágio e júnior).',
                      style: TextStyle(fontSize: 14),
                    ),
                    
                    SizedBox(height: 15),
                    Text(
                      'Participantes:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    Text('- Arthur Carvalho de Oliveira'),
                    Text('- Nicolas Ferreira Silva'),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
              
              // botão de voltar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF45b5b7),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Voltar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
