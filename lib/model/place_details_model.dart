// model/place_details_model.dart

class PlaceDetails {
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    
    return PlaceDetails(
      formattedAddress: json['formatted_address'] ?? '',
      latitude: location['lat'],
      longitude: location['lng'],
    );
  }

  @override
  String toString() {
    return 'PlaceDetails(formattedAddress: $formattedAddress, lat: $latitude, lng: $longitude)';
  }
}