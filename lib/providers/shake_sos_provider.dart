import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_provider.dart';
import '../services/countdown_controller.dart';
import '../services/sos_service.dart';

class ShakeSosState {
  final bool isCountingDown;
  final int countdownSeconds;
  final bool isSosSent;
  final String sosMethodResult; // 'WhatsApp opened' or 'SMS fallback used'

  ShakeSosState({
    required this.isCountingDown,
    required this.countdownSeconds,
    required this.isSosSent,
    required this.sosMethodResult,
  });

  ShakeSosState copyWith({
    bool? isCountingDown,
    int? countdownSeconds,
    bool? isSosSent,
    String? sosMethodResult,
  }) {
    return ShakeSosState(
      isCountingDown: isCountingDown ?? this.isCountingDown,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      isSosSent: isSosSent ?? this.isSosSent,
      sosMethodResult: sosMethodResult ?? this.sosMethodResult,
    );
  }
}

class ShakeSosNotifier extends Notifier<ShakeSosState> {
  @override
  ShakeSosState build() {
    return ShakeSosState(
      isCountingDown: false,
      countdownSeconds: 3,
      isSosSent: false,
      sosMethodResult: '',
    );
  }

  void startCountdown() {
    if (state.isCountingDown || state.isSosSent) return;

    // Reset and stop any active countdowns first
    CountdownController.instance.stop();

    state = state.copyWith(
      isCountingDown: true,
      countdownSeconds: 3,
      isSosSent: false,
    );

    CountdownController.instance.start(
      seconds: 3,
      onTick: (seconds) {
        state = state.copyWith(countdownSeconds: seconds);
      },
      onFinished: () {
        state = state.copyWith(
          isCountingDown: false,
          isSosSent: true,
        );
        sendEmergencySOS();
      },
    );
  }

  void cancelCountdown() {
    CountdownController.instance.stop();
    state = state.copyWith(
      isCountingDown: false,
      countdownSeconds: 3,
      sosMethodResult: '',
    );
  }

  void resetSos() {
    CountdownController.instance.stop();
    state = state.copyWith(
      isCountingDown: false,
      countdownSeconds: 3,
      isSosSent: false,
      sosMethodResult: '',
    );
  }

  Future<void> sendEmergencySOS() async {
    // Reset state before sending
    state = state.copyWith(sosMethodResult: '');
    
    // 1. Get current GPS details from location state provider
    final locationState = ref.read(locationProvider);

    // 2. Delegate execution to SOSService coordinator
    await SOSService.instance.sendEmergencySOS(
      defaultLat: locationState.latitude,
      defaultLng: locationState.longitude,
      defaultArea: locationState.areaName,
      onStatusUpdate: (status) {
        print("[ShakeSosNotifier] SOS status update: $status");
        if (status == "SOS SMS Sent ✅") {
          state = state.copyWith(sosMethodResult: "SOS SMS Sent ✅");
        } else if (status == "WhatsApp opened") {
          if (state.sosMethodResult.contains("SMS")) {
            state = state.copyWith(sosMethodResult: "SMS Sent & WhatsApp Backup Opened ✅");
          } else {
            state = state.copyWith(sosMethodResult: "WhatsApp opened");
          }
        } else if (status.contains("failed") || status.contains("fallback")) {
          state = state.copyWith(sosMethodResult: status);
        }
      },
      onError: (error) {
        print("[ShakeSosNotifier] SOS execution warning/error: $error");
      },
      onSuccess: () {
        print("[ShakeSosNotifier] SOS execution finished successfully.");
      },
    );
  }
}

final shakeSosProvider = NotifierProvider<ShakeSosNotifier, ShakeSosState>(ShakeSosNotifier.new);

