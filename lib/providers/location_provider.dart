import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';

Future<String> reverseGeocode(double lat, double lon) async {
  return LocationService.instance.reverseGeocode(lat, lon);
}

class LocationState {
  final double latitude;
  final double longitude;
  final bool isMock;
  final String statusMessage;
  final String areaName;

  LocationState({
    required this.latitude,
    required this.longitude,
    this.isMock = false,
    this.statusMessage = 'Acquiring GPS...',
    this.areaName = 'OMR Sholinganallur, Chennai',
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isMock,
    String? statusMessage,
    String? areaName,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isMock: isMock ?? this.isMock,
      statusMessage: statusMessage ?? this.statusMessage,
      areaName: areaName ?? this.areaName,
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
      areaName: 'OMR Sholinganallur, Chennai',
    );
  }

  Future<void> updateLocation() async {
    try {
      final hasPermission = await LocationService.instance.checkAndRequestPermission();
      if (!hasPermission) {
        state = state.copyWith(
          isMock: true,
          statusMessage: 'Location permission denied / disabled.',
        );
        return;
      }

      state = state.copyWith(statusMessage: 'Acquiring GPS...');
      final position = await LocationService.instance.getCurrentPosition();
      
      if (position != null) {
        final area = await LocationService.instance.reverseGeocode(position.latitude, position.longitude);
        state = LocationState(
          latitude: position.latitude,
          longitude: position.longitude,
          isMock: false,
          statusMessage: 'GPS Locked',
          areaName: area,
        );
      } else {
        state = state.copyWith(
          isMock: true,
          statusMessage: 'Failed to acquire location. Using default.',
        );
      }
    } catch (e) {
      print("[LocationNotifier] Error updating location: $e");
      state = state.copyWith(
        isMock: true,
        statusMessage: 'Location error: $e',
      );
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
