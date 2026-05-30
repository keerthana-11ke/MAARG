import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/incident_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/fcm_provider.dart';
import '../widgets/responsive.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Live Hospital Relay Simulation State
  bool _hospitalRelayConnecting = false;
  bool _hospitalRelayConnected = false;
  Timer? _relayConnectionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsProvider).speak("Stay calm. Help is being arranged.");
    });
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    _chatScrollController.dispose();
    _relayConnectionTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startHospitalRelay() {
    if (_hospitalRelayConnecting || _hospitalRelayConnected) return;

    setState(() {
      _hospitalRelayConnecting = true;
      _hospitalRelayConnected = false;
    });

    _relayConnectionTimer?.cancel();
    _relayConnectionTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _hospitalRelayConnecting = false;
        _hospitalRelayConnected = true;
      });

      _showHospitalRelayBottomSheet();
    });
  }

  void _showHospitalRelayBottomSheet() {
    final incidentState = ref.read(incidentStateProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _HospitalRelaySheet(
          incidentId: incidentState.activeIncident?.id ?? 'MAARG-2026-CHN-9964',
          onEndRelay: () {
            Navigator.pop(sheetContext);
            setState(() {
              _hospitalRelayConnecting = false;
              _hospitalRelayConnected = false;
            });
          },
        );
      },
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
    
    // Trigger hospital relay if ambulance is called
    if (phoneNumber == '108') {
      _startHospitalRelay();
    }
  }

  String _formatDuration(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showVolunteersBottomSheet(BuildContext context, List<Volunteer> volunteers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: context.paddingAll(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'RESPONDING VOLUNTEERS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...volunteers.map((vol) {
                    return Card(
                      color: Colors.white.withOpacity(0.02),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      child: Padding(
                        padding: context.paddingAll(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE53935).withOpacity(0.1),
                              child: const Icon(Icons.person_rounded, color: Color(0xFFE53935)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vol.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${vol.role} • ${vol.distance}km away',
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    vol.eta,
                                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                                    textAlign: TextAlign.end,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    vol.status,
                                    style: TextStyle(
                                      color: vol.status == 'Accepted' ? Colors.green : Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE53935);
    final secondsRemaining = ref.watch(timerProvider);
    final timerColor = secondsRemaining < 600 ? primaryColor : Colors.amber;

    final incidentState = ref.watch(incidentStateProvider);
    final isMuted = ref.watch(ttsMuteProvider);
    final fcmState = ref.watch(fcmProvider);

    final areaName = incidentState.evidenceAreaName ?? "Villivakkam, Chennai";
    final isHighRiskZone = areaName.toLowerCase().contains("chennai") || 
                           areaName.toLowerCase().contains("villivakkam") ||
                           areaName.toLowerCase().contains("sholinganallur") ||
                           areaName.toLowerCase().contains("omr");

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: context.paddingSymmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. "EMERGENCY IN PROGRESS" header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48), // balance mute button
                        const Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'EMERGENCY IN PROGRESS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.grey),
                          onPressed: () {
                            ref.read(ttsProvider).toggleMute();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Offline banner (if no internet) - Handled globally by ShakeSosWrapper

                    // 3. Victim/Reporter info card
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: context.paddingAll(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                incidentState.isVictimFlow ? Icons.person_pin_rounded : Icons.supervised_user_circle_rounded,
                                color: incidentState.isVictimFlow ? primaryColor : Colors.blueAccent,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    incidentState.isVictimFlow ? "VICTIM PROFILE (SELF)" : "VICTIM PROFILE (BYSTANDER REPORT)",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Name: ${incidentState.victimName ?? (incidentState.isVictimFlow ? 'Self' : 'Anonymous Victim')}",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "🩸 Blood: ${incidentState.victimBloodGroup ?? 'Unknown'}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "📞 Contact: ${incidentState.victimEmergencyContactPhone ?? 'Not Available'}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "🏥 Conditions: ${incidentState.victimMedical ?? 'None reported'}",
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    // 4. "📍 Villivakkam, Chennai" location
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: context.paddingSymmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text("📍 ", style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Text(
                              incidentState.evidenceAreaName ?? "Villivakkam, Chennai",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 5. Golden Hour countdown (BIG yellow timer)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: context.paddingSymmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'GOLDEN HOUR COUNTDOWN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatDuration(secondsRemaining),
                            style: const TextStyle(
                              fontSize: 64, // BIG yellow timer
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 6. High risk zone warning (if applicable)
                    if (isHighRiskZone) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: context.paddingAll(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A65).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFF8A65), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8A65), size: 28),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "HIGH RISK ZONE WARNING",
                                    style: TextStyle(
                                      color: Color(0xFFFF8A65),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "This area has a high frequency of road crashes. Responders should exercise extra caution.",
                                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Live Hospital Relay Connection Status Card
                    if (_hospitalRelayConnecting || _hospitalRelayConnected) ...[
                      GestureDetector(
                        onTap: _hospitalRelayConnected ? _showHospitalRelayBottomSheet : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _hospitalRelayConnected 
                                ? Colors.green.withOpacity(0.08) 
                                : Colors.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _hospitalRelayConnected ? Colors.green : Colors.amber,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_hospitalRelayConnecting)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                  ),
                                )
                              else
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hospitalRelayConnecting 
                                          ? "CONNECTING TO HOSPITAL..." 
                                          : "✅ Apollo Hospital ER Connected",
                                      style: TextStyle(
                                        color: _hospitalRelayConnected ? Colors.green.shade200 : Colors.amber.shade200,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (_hospitalRelayConnected) ...[
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Tap to view live vitals, surgeon standby status & instructions.",
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_hospitalRelayConnected)
                                const Icon(Icons.chevron_right_rounded, color: Colors.green, size: 24),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // 7. Nearby responders list with CALL buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'NEARBY RESPONDERS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildResponderRow(
                          name: 'GVK EMRI Ambulance (108)',
                          eta: '6 min (1.2 km)',
                          phone: '108',
                          icon: Icons.airport_shuttle_rounded,
                        ),
                        const SizedBox(height: 8),
                        _buildResponderRow(
                          name: incidentState.nearestHospitalName ?? 'Apollo Hospital',
                          eta: incidentState.nearestHospitalDistance ?? "8 min (2.1 km)",
                          phone: '044-28293333',
                          icon: Icons.local_hospital_rounded,
                        ),
                        const SizedBox(height: 8),
                        _buildResponderRow(
                          name: 'Adyar Police Station',
                          eta: '5 min (0.8 km)',
                          phone: '044-24426101',
                          icon: Icons.local_police_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 8. Family Notified badge
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: incidentState.familyNotified ? Colors.green.withOpacity(0.12) : Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: incidentState.familyNotified ? Colors.green.withOpacity(0.4) : Colors.amber.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            incidentState.familyNotified ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                            color: incidentState.familyNotified ? Colors.green : Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: incidentState.familyNotified
                                ? Text(
                                    'Family Notified: ${incidentState.familyMemberName ?? "Emergency Contact"} ✓',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Family not notified - no QR scanned",
                                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        "Scan victim QR profile to enable family tracking updates.",
                                        style: TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // 9. Volunteers responding counter
                    GestureDetector(
                      onTap: () {
                        if (incidentState.volunteers.isNotEmpty) {
                          _showVolunteersBottomSheet(context, incidentState.volunteers);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: incidentState.volunteers.isNotEmpty
                              ? Colors.green.withOpacity(0.1)
                              : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: incidentState.volunteers.isNotEmpty
                                ? Colors.green.withOpacity(0.4)
                                : Colors.white10,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              color: incidentState.volunteers.isNotEmpty ? Colors.green : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    incidentState.volunteers.isNotEmpty
                                        ? '${incidentState.volunteers.length} volunteers responding nearby'
                                        : 'Searching for nearby volunteers...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    incidentState.volunteers.isNotEmpty
                                        ? 'Tap to view ETAs and roles.'
                                        : 'Volunteers are notified automatically.',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (incidentState.volunteers.isNotEmpty)
                              const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.green, size: 20),
                          ],
                        ),
                      ),
                    ),

                    // 10. ASSESS VICTIM button at bottom
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/guidance');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'ASSESS VICTIM',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Animated Volunteer top alert notification overlay
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: incidentState.activeBannerVolunteer != null
                    ? Container(
                        key: ValueKey<String>(incidentState.activeBannerVolunteer!),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Circular Avatar
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE53935),
                              radius: 18,
                              child: Text(
                                incidentState.activeBannerVolunteer![0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    incidentState.activeBannerVolunteer == 'Ravi'
                                        ? 'Ravi (0.3km) is responding'
                                        : incidentState.activeBannerVolunteer == 'Priya'
                                            ? 'Priya (0.8km) accepted'
                                            : 'Karthik (1.2km) is on the way',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    incidentState.activeBannerVolunteer == 'Ravi'
                                        ? 'First Aid helper nearby'
                                        : incidentState.activeBannerVolunteer == 'Priya'
                                            ? 'Emergency caller dispatched'
                                            : 'Traffic controller en route',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Close Button
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                              onPressed: () {
                                ref.read(incidentStateProvider.notifier).dismissActiveBanner();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            if (fcmState.hasNotification && fcmState.lastMessageTitle != null)
              _buildNotificationBanner(context, ref, fcmState),
          ],
        ),
      ),
    );
  }

  Widget _buildResponderRow({
    required String name,
    required String eta,
    required String phone,
    required IconData icon,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.02),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eta,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(phone),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.07),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white12),
                  ),
                ),
                icon: const Icon(Icons.phone, size: 16, color: Colors.green),
                label: const Text(
                  'CALL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    const primaryColor = Color(0xFFE53935);
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: msg.isUser ? primaryColor : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 16),
          ),
          border: msg.isUser ? null : Border.all(color: Colors.white10),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        backgroundColor: Colors.white.withOpacity(0.04),
        side: const BorderSide(color: Colors.white10),
        onPressed: () {
          ref.read(chatProvider.notifier).sendMessage(text.substring(2));
          _scrollToBottom();
        },
      ),
    );
  }

  TableRow _buildServiceTableRow({
    required String name,
    required String eta,
    required String phone,
  }) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Text(
              eta,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(phone),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.07),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white12),
                  ),
                ),
                icon: const Icon(Icons.phone, size: 16, color: Colors.green),
                label: const Text(
                  'CALL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
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
            padding: context.paddingAll(16),
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
                  padding: context.paddingAll(8),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
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

class _HospitalRelaySheet extends StatefulWidget {
  final String incidentId;
  final VoidCallback onEndRelay;

  const _HospitalRelaySheet({
    required this.incidentId,
    required this.onEndRelay,
  });

  @override
  State<_HospitalRelaySheet> createState() => _HospitalRelaySheetState();
}

class _HospitalRelaySheetState extends State<_HospitalRelaySheet> {
  Timer? _vitalsTimer;
  Timer? _doctorTimer;
  Timer? _pulseTimer;

  bool _showDoctorMessage = false;
  int _simulatedHeartRate = 92;
  String _simulatedBP = '140/90';
  String _simulatedBreathing = 'Irregular';
  double _livePulseOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    // Vitals timer: fluctuate every 3 seconds
    _vitalsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _simulatedHeartRate = 90 + (DateTime.now().millisecond % 6);
        final bps = ['138/88', '140/90', '141/91', '139/89', '142/90'];
        _simulatedBP = bps[DateTime.now().second % bps.length];
        _simulatedBreathing = DateTime.now().second % 4 == 0 ? 'Shallow' : 'Irregular';
      });
    });

    // Doctor message timer: show after 5 seconds
    _doctorTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _showDoctorMessage = true;
      });
    });

    // Pulse animation timer
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) return;
      setState(() {
        _livePulseOpacity = _livePulseOpacity == 1.0 ? 0.2 : 1.0;
      });
    });
  }

  @override
  void dispose() {
    _vitalsTimer?.cancel();
    _doctorTimer?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }

  String _formatIncidentId(String id) {
    if (id.startsWith('MAARG-')) return id;
    final parts = id.split('-');
    if (parts.isNotEmpty && parts.first.length == 4) {
      return 'MAARG-2026-CHN-${parts.first.toUpperCase()}';
    }
    final clean = id.replaceAll('-', '').toUpperCase();
    final suffix = clean.length >= 4 ? clean.substring(0, 4) : clean.padRight(4, 'X');
    return 'MAARG-2026-CHN-$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 1. Connection Status Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedOpacity(
                    opacity: _livePulseOpacity,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "LIVE",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "•  Apollo Hospital ER  •  Dr. Ramesh",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Victim Vitals Panel
          const Text(
            "VICTIM VITALS (LIVE RELAY)",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              _buildVitalCard(
                icon: Icons.favorite_rounded,
                iconColor: Colors.red,
                label: "Heart Rate",
                value: "$_simulatedHeartRate bpm",
              ),
              _buildVitalCard(
                icon: Icons.bloodtype_rounded,
                iconColor: Colors.redAccent,
                label: "Blood Pressure",
                value: _simulatedBP,
              ),
              _buildVitalCard(
                icon: Icons.air_rounded,
                iconColor: Colors.blue,
                label: "Breathing",
                value: _simulatedBreathing,
              ),
              _buildVitalCard(
                icon: Icons.thermostat_rounded,
                iconColor: Colors.amber,
                label: "Status",
                value: "Critical",
                valueColor: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Pre-arrival Checklist
          const Text(
            "PRE-ARRIVAL CHECKLIST",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildChecklistItem("Trauma bay reserved", true),
                const SizedBox(height: 8),
                _buildChecklistItem("Blood type B+ available", true),
                const SizedBox(height: 8),
                _buildChecklistItem("Surgeon on standby", true),
                const SizedBox(height: 8),
                _buildChecklistItem("CT scan queued", false),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Doctor Message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _showDoctorMessage
                ? Container(
                    key: const ValueKey('doctor_msg_active'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: Colors.blueAccent, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Dr. Ramesh (Trauma Surgeon)",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Keep victim still. Do not remove helmet. We are ready for arrival. ETA: 6 minutes",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    key: const ValueKey('doctor_msg_waiting'),
                    height: 60,
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Waiting for doctor review...",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          // 5. Incident Shared Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Incident ID shared with hospital",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        _formatIncidentId(widget.incidentId),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. Bottom Status
          const Center(
            child: Text(
              "Hospital has been briefed. Continue first aid until ambulance arrives.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 7. End Relay Button
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: widget.onEndRelay,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "End Relay",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
   );
  }

  Widget _buildVitalCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
          color: isDone ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDone ? Colors.white : Colors.white60,
              fontSize: 13,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
