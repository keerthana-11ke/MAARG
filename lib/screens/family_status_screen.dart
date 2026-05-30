import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';
import '../providers/incident_provider.dart';

class FamilyStatusScreen extends ConsumerStatefulWidget {
  final String name;
  final String hospital;

  const FamilyStatusScreen({
    required this.name,
    required this.hospital,
    super.key,
  });

  @override
  ConsumerState<FamilyStatusScreen> createState() => _FamilyStatusScreenState();
}

class _FamilyStatusScreenState extends ConsumerState<FamilyStatusScreen> {
  int _localTimerSeconds = 2700; // Fallback 45 mins countdown
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final active = ref.read(incidentStateProvider).activeIncident;
    if (active == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_localTimerSeconds > 0) {
          setState(() {
            _localTimerSeconds--;
          });
        } else {
          _ticker?.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF0A0A0A);
    const primaryRed = Color(0xFFE53935);
    final activeIncident = ref.watch(incidentStateProvider).activeIncident;

    final secondsRemaining = activeIncident != null
        ? ref.watch(timerProvider)
        : _localTimerSeconds;

    final timerColor = secondsRemaining < 600 ? primaryRed : Colors.amber;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Family Portal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.grey,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                
                // Main reassurance card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Colors.green, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'Your family member is safe.\nHelp is coming.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Status Page for: ${widget.name}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Countdown details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'GOLDEN HOUR TIME REMAINING',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(secondsRemaining),
                        style: TextStyle(
                          fontSize: 48,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          color: timerColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.local_hospital_rounded, color: primaryRed, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NEAREST DESIGNATED CLINIC',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.hospital,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Timeline updates
                const Text(
                  'STATUS TIMELINE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                _buildTimelineStep(
                  title: 'Ambulance called',
                  subtitle: 'GVK EMRI 108 ambulance is on route.',
                  isDone: true,
                ),
                _buildTimelineStep(
                  title: 'Bystanders helping',
                  subtitle: 'Trained first responders are coordinating support.',
                  isDone: true,
                ),
                _buildTimelineStep(
                  title: 'En route to hospital',
                  subtitle: 'Safe transit to ${widget.hospital}.',
                  isDone: false,
                ),

                const SizedBox(height: 36),

                // Disclaimer
                Text(
                  'This page updates in real-time. Keep it open for live location and progress coordinates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isDone ? Colors.green : Colors.white24,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isDone ? Icons.check : Icons.access_time_rounded,
                    size: 16,
                    color: isDone ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
