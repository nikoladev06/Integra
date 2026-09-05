// views/addevento_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../controller/addevento_controller.dart';
import '../model/place_details_model.dart';
import '../services/google_places_service.dart';


class AddEventoView extends StatefulWidget {
  const AddEventoView({super.key});

  @override
  State<AddEventoView> createState() => _AddEventoViewState();
}

class _AddEventoViewState extends State<AddEventoView> {
  final AddEventoController _controller = AddEventoController();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _localizacaoController = TextEditingController();
  DateTime? _dataSelecionada;
  TimeOfDay _horaSelecionada = TimeOfDay.now();
  PlaceDetails? _placeDetails; // ARMAZENA OS DETALHES DO LOCAL
  final GooglePlacesService _placesService = GooglePlacesService();
  bool _isLoading = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _localizacaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF45b5b7),
              onPrimary: Colors.white,
              surface: Color(0xFF1F1F20),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  Future<void> _selecionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF45b5b7),
              onPrimary: Colors.white,
              surface: Color(0xFF111112),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _horaSelecionada = picked;
      });
    }
  }

Future<void> _criarEvento() async {
  setState(() => _isLoading = true);

  try {
    // ENVIA DateTime? E DEIXA O CONTROLLER VALIDAR
    DateTime? dataParaEnviar;
    if (_dataSelecionada != null) {
      dataParaEnviar = DateTime(
        _dataSelecionada!.year,
        _dataSelecionada!.month,
        _dataSelecionada!.day,
        _horaSelecionada.hour,
        _horaSelecionada.minute,
      );
    }

    final sucesso = await _controller.criarEventoComPlaceDetails(
      context,
      _tituloController.text,
      _descricaoController.text,
      dataParaEnviar,
      _placeDetails,
    );

    if (sucesso && mounted) {
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
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
        iconTheme: const IconThemeData(color: Colors.white), // Cor do ícone de voltar
        backgroundColor: const Color(0xFF111112), // Cor de fundo igual ao corpo da tela
        title: const Text('Criar Evento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Título do Evento',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF45b5b7)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Descrição',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF45b5b7)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TypeAheadField<PlaceSuggestion>(
              controller: _localizacaoController,
              suggestionsCallback: (pattern) async {

                // Chama a API apenas se o usuário digitar algo
                if (pattern.isNotEmpty) {
                  try {
                    return await _placesService.fetchSuggestions(pattern);
                  } catch (e) {
                    return []; // Retorna lista vazia em caso de erro
                  }
                }
                return [];
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                  title: Text(suggestion.description, style: const TextStyle(color: Colors.white)),
                  tileColor: const Color(0xFF1F1F20),
                );
              },
              onSelected: (suggestion) async {
                //Atualiza o campo de texto com a descrição
                _localizacaoController.text = suggestion.description;

                //BUSCA OS DETALHES (LAT/LNG) USANDO O placeId
                final details = await _placesService.getPlaceDetails(suggestion.placeId);
                if (details != null) {
                  setState(() {
                    _placeDetails = details;
                  });
                }
                // O token de sessão já foi reiniciado dentro de getPlaceDetails
              },
              builder: (context, controller, focusNode) {
                //TextField continua usando o controller.
                return TextField( 
                controller: _localizacaoController,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Localização', 
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Ex: Av. Paulista, 1000 - São Paulo, SP',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF45b5b7)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              },
              emptyBuilder: (context) => const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Nenhum endereço encontrado.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              // O debounce é controlado aqui (em milissegundos)
              // A API só será chamada 500ms após o usuário parar de digitar
              debounceDuration: const Duration(milliseconds: 500),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selecionarData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[600]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      _dataSelecionada == null
                          ? 'Selecione a data'
                          : '${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year}',
                      style: TextStyle(
                        color: _dataSelecionada == null
                            ? Colors.grey
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selecionarHora,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[600]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      _horaSelecionada.format(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _criarEvento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF45b5b7), // Cor padrão do app
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Criar Evento',
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