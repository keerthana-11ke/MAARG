import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  final double latitude;
  final double longitude;
  final bool isMock;
  final String statusMessage;

  LocationState({
    required this.latitude,
    required this.longitude,
    this.isMock = false,
    this.statusMessage = 'Acquiring GPS...',
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isMock,
    String? statusMessage,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isMock: isMock ?? this.isMock,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    // Trigger location acquisition asynchronously
    Future.microtask(() => updateLocation());
    return LocationState(
      latitude: 13.0827,
      longitude: 80.2707,
      isMock: true,
      statusMessage: 'Initializing...',
    );
  }

  Future<void> updateLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isMock: true,
          statusMessage: 'Location services disabled. Using default.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isMock: true,
            statusMessage: 'Permission denied. Using default.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isMock: true,
          statusMessage: 'Permission permanently denied.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      ).catchError((e) {
        return Geolocator.getLastKnownPosition() ?? Position(
          latitude: 28.6139,
          longitude: 77.2090,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });

      state = LocationState(
        latitude: position.latitude,
        longitude: position.longitude,
        isMock: false,
        statusMessage: 'GPS Locked',
      );
    } catch (e) {
      state = state.copyWith(
        isMock: true,
        statusMessage: 'Mock GPS (Desktop/No GPS)',
      );
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
