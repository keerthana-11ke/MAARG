import 'dart:async';
import 'package:flutter/foundation.dart';

class CountdownController {
  static final CountdownController instance = CountdownController._internal();
  CountdownController._internal();

  Timer? _timer;
  int _secondsRemaining = 3;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  int get secondsRemaining => _secondsRemaining;

  /// Starts a countdown sequence from specified seconds.
  /// Calls `onTick` every second and `onFinished` when the countdown completes.
  void start({
    required int seconds,
    required void Function(int) onTick,
    required VoidCallback onFinished,
  }) {
    // If already running, stop the current one first to prevent duplicate timer tasks
    if (_isRunning) {
      print("[CountdownController] Already running. Restarting countdown...");
      stop();
    }

    _isRunning = true;
    _secondsRemaining = seconds;
    
    print("[CountdownController] Starting countdown from $_secondsRemaining seconds...");
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        print("[CountdownController] Ticking: $_secondsRemaining seconds left.");
        onTick(_secondsRemaining);
      } else {
        print("[CountdownController] Countdown complete.");
        stop();
        onFinished();
      }
    });
  }

  /// Cancels and resets the countdown timer.
  void stop() {
    print("[CountdownController] Stopping and clearing countdown timer.");
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _secondsRemaining = 3;
  }
}
