import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shake_sos_provider.dart';

class SOSCountdownScreen extends ConsumerStatefulWidget {
  const SOSCountdownScreen({super.key});

  @override
  ConsumerState<SOSCountdownScreen> createState() => _SOSCountdownScreenState();
}

class _SOSCountdownScreenState extends ConsumerState<SOSCountdownScreen> {
  @override
  void initState() {
    super.initState();
    // Start the countdown immediately when this screen is pushed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shakeSosProvider.notifier).startCountdown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shakeState = ref.watch(shakeSosProvider);

    // Listen to when SOS is sent, so we can show the "Sent" screen or close/navigate
    ref.listen(shakeSosProvider.select((s) => s.isSosSent), (prev, next) {
      if (next == true) {
        // Vibrate heavily
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.heavyImpact();
        });
      }
    });

    // Listen to countdown cancel, so we can pop the screen
    ref.listen(shakeSosProvider.select((s) => s.isCountingDown), (prev, next) {
      if (prev == true && next == false && !shakeState.isSosSent) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: shakeState.isSosSent ? const Color(0xFF121212) : const Color(0xFFE53935),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!shakeState.isSosSent) ...[
              const Spacer(),
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 96,
              ),
              const SizedBox(height: 16),
              const Text(
                "SOS ACTIVATING",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "SOS in ${shakeState.countdownSeconds}...",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Keep pressing volume down or wait to send automatic SOS alert",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 64),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Text(
                  "${shakeState.countdownSeconds}",
                  key: ValueKey<int>(shakeState.countdownSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(shakeSosProvider.notifier).cancelCountdown();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "CANCEL",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.withOpacity(0.3), width: 3),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green,
                  size: 96,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "SOS Sent ✅",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Emergency responders and your family contacts have been alerted with your live GPS location.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (shakeState.sosMethodResult.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shakeState.sosMethodResult,
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(shakeSosProvider.notifier).resetSos();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "DISMISS",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
