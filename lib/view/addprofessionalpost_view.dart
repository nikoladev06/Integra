import 'package:flutter/material.dart';
import '../controller/addprofessionalpost_controller.dart';

class AddProfessionalPostView extends StatefulWidget {
  const AddProfessionalPostView({super.key});

  @override
  State<AddProfessionalPostView> createState() =>
      _AddProfessionalPostViewState();
}

class _AddProfessionalPostViewState extends State<AddProfessionalPostView> {
  final AddProfessionalPostController _controller =
      AddProfessionalPostController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _tituloController = TextEditingController();
  String? _tipoSelecionado;
  bool _isLoading = false;

  final List<String> _tipos = [
    'Vaga de Emprego',
    'Estágio',
    'Oportunidade',
    'Freelance',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  Future<void> _criarPost() async {
    if (_tituloController.text.isEmpty ||
        _descricaoController.text.isEmpty ||
        _empresaController.text.isEmpty ||
        _tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _controller.criarPostProfissional(
        _tituloController.text, 
        _descricaoController.text,
        _tipoSelecionado!,
        _empresaController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post criado com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
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
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1F1F20),
        title: const Text('Criar Post Profissional', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _tipoSelecionado,
              dropdownColor: const Color(0xFF1F1F20),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tipo de Publicação',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF6200EE)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _tipos.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoSelecionado = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
            controller: _tituloController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Título',
              labelStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[600]!),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF6200EE)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
            const SizedBox(height: 16),
            TextField(
              controller: _empresaController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Empresa',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF6200EE)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              style: const TextStyle(color: Colors.white),
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Descrição',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText:
                    'Descreva a vaga, requisitos, benefícios, etc.',
                hintStyle: TextStyle(color: Colors.grey[600]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF6200EE)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _criarPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EE),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Publicar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}