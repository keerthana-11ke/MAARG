import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/services_repository.dart';
import 'location_provider.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return StaticServicesRepository();
});

final nearbyServicesProvider = FutureProvider<List<EmergencyService>>((ref) async {
  final repository = ref.watch(servicesRepositoryProvider);
  final location = ref.watch(locationProvider);
  return repository.getNearbyServices(location.latitude, location.longitude);
});
