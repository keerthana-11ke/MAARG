import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  @override
  void initState() {
    super.initState();
    // Speak on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsProvider).speak("Stay calm. Help is being arranged.");
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  String _formatDuration(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final secondsRemaining = ref.watch(timerProvider);
    final timerColor = secondsRemaining < 600 ? const Color(0xFFE53935) : Colors.amber;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'EMERGENCY IN PROGRESS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP SECTION: Golden Hour Timer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'GOLDEN HOUR REMAINING',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(secondsRemaining),
                        style: TextStyle(
                          fontSize: 54,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          color: timerColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Critical Window for Medical Intervention',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // Blackspot warning banner (Old Mahabalipuram Road)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE53935), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 28),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          '⚠ High-risk zone. Drive carefully.\n(Old Mahabalipuram Road Hotspot)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. MIDDLE SECTION: Nearby Services Table
                const Text(
                  'NEARBY EMERGENCY RESPONDERS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),

                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: IntrinsicColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Row 1: Ambulance
                    _buildServiceTableRow(
                      name: 'GVK EMRI Ambulance (108)',
                      eta: '6 min (1.2 km)',
                      phone: '108',
                    ),
                    // Row 2: Trauma Hospital
                    _buildServiceTableRow(
                      name: 'Apollo Hospital (Chennai)',
                      eta: '8 min (2.1 km)',
                      phone: '044-28293333',
                    ),
                    // Row 3: Police
                    _buildServiceTableRow(
                      name: 'Adyar Police Station',
                      eta: '5 min (0.8 km)',
                      phone: '044-24426101',
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // 3. BOTTOM SECTION: Assess Victim Primary CTA Button
                SizedBox(
                  height: 64, // Minimum height 64px
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/guidance');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ASSESS VICTIM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                fontSize: 16,
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
                fontSize: 16,
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(phone),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.07),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white12),
                  ),
                ),
                icon: const Icon(Icons.phone, size: 16, color: Colors.green),
                label: const Text(
                  'CALL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
