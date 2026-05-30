import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  /// Checks if location services are enabled and checks/requests fine location permission.
  Future<bool> checkAndRequestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("[LocationService] Location services disabled.");
        return false;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("[LocationService] Permission denied.");
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print("[LocationService] Permission permanently denied.");
        return false;
      }
      return true;
    } catch (e) {
      print("[LocationService] Error checking permissions: $e");
      return false;
    }
  }

  /// Fetches current GPS position.
  /// Falls back to last known location, or null if none is available.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        print("[LocationService] Location permissions not granted.");
        return null;
      }

      print("[LocationService] Fetching current position...");
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print("[LocationService] Current position failed, attempting last known location: $e");
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (err) {
        print("[LocationService] Last known position failed: $err");
        return null;
      }
    }
  }

  /// Converts latitude/longitude coordinates into a user-friendly area name.
  Future<String> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json');
      print("[LocationService] Requesting reverse geocoding from Nominatim: lat=$lat, lon=$lon");
      final response = await http.get(url, headers: {
        'User-Agent': 'MAARG Emergency App - com.keerthana.maarg',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['street'] ?? address['pedestrian'];
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['village'] ?? address['subdivision'];
          final city = address['city'] ?? address['town'] ?? address['county'] ?? address['state'];
          
          final List<String> parts = [];
          if (road != null) parts.add(road.toString());
          if (suburb != null && suburb != road) parts.add(suburb.toString());
          if (city != null) parts.add(city.toString());
          
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }
    } catch (e) {
      print('[LocationService] Reverse geocoding error: $e');
    }
    return "OMR Sholinganallur, Chennai";
  }
}
