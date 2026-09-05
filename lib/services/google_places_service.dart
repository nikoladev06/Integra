import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:proj_compras/model/place_details_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion(this.placeId, this.description);

  @override
  String toString() {
    return 'Suggestion(description: $description, placeId: $placeId)';
  }
}

/// Modelo para armazenar os detalhes de um local obtidos da API Place Details.
/// O ideal é que este modelo fique em seu próprio arquivo, como 'model/place_details_model.dart'.


class GooglePlacesService {
  final String _apiKey = dotenv.env['GOOGLE_API_KEY'] ?? 'CHAVE_NAO_ENCONTRADA';
  String _sessionToken = Uuid().v4();

  Future<List<PlaceSuggestion>> fetchSuggestions(String input) async {
    if (input.isEmpty) {
      return [];
    }

    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey&sessiontoken=$_sessionToken&language=pt_BR&components=country:br';

    final response = await http.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        return result['predictions']
            .map<PlaceSuggestion>((p) => PlaceSuggestion(p['place_id'], p['description']))
            .toList();
      } else {
        if (result['error_message'] != null) {
          print('   -> Mensagem: ${result['error_message']}');
        }
      }
    } else {
      // MOSTRA ERRO DE CONEXÃO
      print(' GooglePlacesService: Erro de conexão HTTP: ${response.statusCode}');
      print(' -> Corpo da resposta: ${response.body}');
    }

    _sessionToken = Uuid().v4();
    return [];
  }

  /// Busca os detalhes de um local usando o placeId.
  /// Esta chamada deve ser feita após o usuário selecionar uma sugestão.
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final request =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=address_component,name,formatted_address,geometry&key=$_apiKey&sessiontoken=$_sessionToken&language=pt_BR';

    final response = await http.get(Uri.parse(request));

    // Após esta chamada, a sessão é considerada encerrada.
    // O token é reiniciado para a próxima busca do usuário.
    restartSessionToken();

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        // Converte o resultado JSON em um objeto PlaceDetails.
        return PlaceDetails.fromJson(result['result']);
      }
    }
    return null;
  }

  /// Reinicia o token de sessão.
  /// Deve ser chamado após um local ser selecionado ou a busca ser cancelada.
  void restartSessionToken() {
    _sessionToken = Uuid().v4();
    print('GooglePlacesService: Session Token reiniciado.');
  }
}