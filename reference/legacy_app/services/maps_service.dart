// services/geocoding_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  static Future<Map<String, double>?> getCoordinates(String address) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final response = await http.get(
        Uri.parse('$_baseUrl?q=${Uri.encodeComponent(address)}&format=json&limit=1'),
        headers: {
          'User-Agent': 'IntegraApp/1.0 (arthur.oliveira35@fatec.sp.gov.br)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          return {
            'lat': double.parse(data[0]['lat']),
            'lng': double.parse(data[0]['lon']),
          };
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Erro no geocoding: $e');
      return null;
    }
  }
}

