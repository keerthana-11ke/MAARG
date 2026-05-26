import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/fcm_provider.dart';
import '../providers/incident_provider.dart';
import '../providers/location_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFFE53935);
    final fcmState = ref.watch(fcmProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Branding Header
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.radar_rounded, color: primaryColor, size: 36),
                          SizedBox(width: 12),
                          Text(
                            'M A A R G',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'GOLDEN HOUR EMERGENCY RESPONSE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Large Pulsing SOS Button
                  Expanded(
                    child: Center(
                      child: ReportAccidentButton(
                        onPressed: () {
                          final loc = ref.read(locationProvider);
                          // 1. Play TTS
                          ref.read(ttsProvider).speak("Stay calm. Help is being arranged.");
                          
                          // 2. Start the golden hour timer
                          ref.read(timerProvider.notifier).startTimer();

                          // 3. Trigger SOS
                          ref.read(incidentStateProvider.notifier).triggerSOS(loc.latitude, loc.longitude);

                          // 4. Navigate immediately to Activation screen
                          context.push('/activation');
                        },
                      ),
                    ),
                  ),

                  // Bottom reassurance and bystander counter
                  Column(
                    children: [
                      // Bystander responding counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.people_alt_rounded, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  '2 bystanders responding nearby',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.gavel_rounded, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Protected by Good Samaritan Act',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to report road crash & alert responders',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (fcmState.hasNotification && fcmState.lastMessageTitle != null)
            _buildNotificationBanner(context, ref, fcmState),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner(BuildContext context, WidgetRef ref, FcmState fcmState) {
    final title = fcmState.lastMessageTitle ?? 'Emergency Alert';
    final body = fcmState.lastMessageBody ?? 'A nearby emergency needs assistance.';
    final incidentId = fcmState.lastMessageIncidentId ?? '';

    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          ref.read(fcmProvider.notifier).dismissNotification();
          if (incidentId.isNotEmpty) {
            context.push('/responder/$incidentId');
          }
        },
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1E1E1E),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    ref.read(fcmProvider.notifier).dismissNotification();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportAccidentButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ReportAccidentButton({required this.onPressed, super.key});

  @override
  State<ReportAccidentButton> createState() => _ReportAccidentButtonState();
}

class _ReportAccidentButtonState extends State<ReportAccidentButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 200.0;
    const primaryColor = Color(0xFFE53935);

    return GestureDetector(
      onTap: widget.onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Rings
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: size * _scaleAnimation.value,
                height: size * _scaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(_opacityAnimation.value),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: size * (_scaleAnimation.value - 0.2).clamp(1.0, 1.4),
                height: size * (_scaleAnimation.value - 0.2).clamp(1.0, 1.4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity((_opacityAnimation.value * 1.5).clamp(0.0, 1.0)),
                ),
              );
            },
          ),
          // Center SOS Button
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 8,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'REPORT\nACCIDENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
