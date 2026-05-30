import 'dart:math';
import 'package:geolocator/geolocator.dart';

enum ServiceType { hospital, police, fire }

class EmergencyService {
  final String id;
  final String name;
  final ServiceType type;
  final String phone;
  final double latitude;
  final double longitude;
  final double? calculatedDistance; // in km

  EmergencyService({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.calculatedDistance,
  });

  EmergencyService copyWithDistance(double distance) {
    return EmergencyService(
      id: id,
      name: name,
      type: type,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      calculatedDistance: distance,
    );
  }
}

abstract class ServicesRepository {
  Future<List<EmergencyService>> getNearbyServices(double userLat, double userLng);
}

class StaticServicesRepository implements ServicesRepository {
  // Mock data of emergency response services around a default coordinate
  final List<EmergencyService> _allServices = [
    EmergencyService(
      id: 'hosp_max',
      name: 'Max Super Speciality Hospital',
      type: ServiceType.hospital,
      phone: '102',
      latitude: 28.5276,
      longitude: 77.2118,
    ),
    EmergencyService(
      id: 'hosp_aiims',
      name: 'All India Institute of Medical Sciences (AIIMS)',
      type: ServiceType.hospital,
      phone: '01126588500',
      latitude: 28.5672,
      longitude: 77.2100,
    ),
    EmergencyService(
      id: 'hosp_fortis',
      name: 'Fortis Flt. Lt. Rajan Dhall Hospital',
      type: ServiceType.hospital,
      phone: '0114277 6222',
      latitude: 28.5218,
      longitude: 77.1601,
    ),
    EmergencyService(
      id: 'police_saket',
      name: 'Saket Police Station',
      type: ServiceType.police,
      phone: '112',
      latitude: 28.5222,
      longitude: 77.2088,
    ),
    EmergencyService(
      id: 'police_vihar',
      name: 'Vasant Vihar Police Station',
      type: ServiceType.police,
      phone: '112',
      latitude: 28.5583,
      longitude: 77.1654,
    ),
    EmergencyService(
      id: 'fire_bhikaji',
      name: 'Bhikaji Cama Place Fire Station',
      type: ServiceType.fire,
      phone: '101',
      latitude: 28.5694,
      longitude: 77.1868,
    ),
  ];

  @override
  Future<List<EmergencyService>> getNearbyServices(double userLat, double userLng) async {
    // Simulate slight networking latency
    await Future.delayed(const Duration(milliseconds: 300));
    
    final List<EmergencyService> results = [];
    for (final service in _allServices) {
      double distanceInMeters = Geolocator.distanceBetween(
        userLat, userLng,
        service.latitude, service.longitude,
      );
      double distanceInKm = distanceInMeters / 1000;

      // Show only hospitals within 20km.
      if (service.type == ServiceType.hospital && distanceInKm > 20) {
        continue;
      }
      
      results.add(service.copyWithDistance(distanceInKm));
    }

    // Sort by distance ascending
    results.sort((a, b) => (a.calculatedDistance ?? double.infinity).compareTo(b.calculatedDistance ?? double.infinity));
    return results;
  }
}
