import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/incident_provider.dart';

class RoleAssignmentScreen extends ConsumerStatefulWidget {
  const RoleAssignmentScreen({super.key});

  @override
  ConsumerState<RoleAssignmentScreen> createState() => _RoleAssignmentScreenState();
}

class _RoleAssignmentScreenState extends ConsumerState<RoleAssignmentScreen> {
  String? _claimedRoleId; // 'call', 'traffic', 'assistant'

  void _claimRole(String roleId) {
    setState(() {
      _claimedRoleId = roleId;
    });
    ref.read(incidentStateProvider.notifier).setChosenRole(roleId);
    ref.read(ttsProvider).speak("Thank you. You are helping save a life.");
  }

  void _showSamaritanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoodSamaritanBottomSheet(),
    );
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'COORDINATION BOARD',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: timerColor.withOpacity(0.1),
                border: Border.all(color: timerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(secondsRemaining),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: timerColor,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Subtitle
              const Text(
                'Who will you be?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap your role. Every second counts.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // 3 Role Cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildRoleCard(
                      id: 'call',
                      title: '🔴 CALL FACILITATOR',
                      description: 'Call 108 ambulance. Stay on the line. Give them exact GPS location.',
                      icon: Icons.phone_in_talk_rounded,
                      roleColor: const Color(0xFFE53935),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      id: 'traffic',
                      title: '🟡 TRAFFIC CONTROLLER',
                      description: 'Stop vehicles. Create a clear path. Wave down approaching cars now.',
                      icon: Icons.traffic_rounded,
                      roleColor: Colors.amber,
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      id: 'assistant',
                      title: '🟢 VICTIM ASSISTANT',
                      description: 'Stay with the victim. Follow the guidance steps.',
                      icon: Icons.healing_rounded,
                      roleColor: Colors.green,
                    ),
                  ],
                ),
              ),

              // Reassurance & Done Button Bottom Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Under Good Samaritan Guidelines 2015, you are legally protected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: InkWell(
                      onTap: () => _showSamaritanSheet(context),
                      child: const Text(
                        'I have concerns (View Legal Protections)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Done Button - visible only when role is claimed
                  if (_claimedRoleId != null)
                    SizedBox(
                      height: 64, // Minimum height 64px
                      child: ElevatedButton(
                        onPressed: () {
                          _showEvidenceCapturePopup(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 64),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEvidenceCapturePopup(BuildContext context) async {
    final goRouter = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(dialogContext, false), // Skip
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    '📸 Capture Evidence?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Take a photo for the incident report. This helps police and insurance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false), // Skip
                        child: const Text('SKIP', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true), // Take Photo
                        child: const Text('TAKE PHOTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? photo = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );

        if (photo != null) {
          ref.read(incidentStateProvider.notifier).setEvidencePhotoPath(photo.path);
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Evidence captured ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          goRouter.push('/debrief');
        } else {
          ref.read(incidentStateProvider.notifier).setEvidencePhotoPath(null);
          goRouter.push('/debrief');
        }
      } catch (e) {
        print("Camera capture error: $e");
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error accessing camera: $e')),
        );
        goRouter.push('/debrief');
      }
    } else {
      ref.read(incidentStateProvider.notifier).setEvidencePhotoPath(null);
      if (context.mounted) {
        context.push('/debrief');
      }
    }
  }

  Widget _buildRoleCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required Color roleColor,
  }) {
    final isClaimed = _claimedRoleId == id;
    final isAnyClaimed = _claimedRoleId != null;
    final displayColor = isClaimed ? Colors.green.shade800 : Colors.white.withOpacity(0.03);
    final borderColor = isClaimed ? Colors.green : Colors.white10;

    return GestureDetector(
      onTap: () {
        if (!isClaimed) {
          _claimRole(id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: displayColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isClaimed ? Colors.white : roleColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isClaimed ? Colors.white : Colors.white,
                    ),
                  ),
                ),
                if (isClaimed)
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: isClaimed ? Colors.white : Colors.grey.shade300,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (!isClaimed) {
                    _claimRole(id);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClaimed ? Colors.green.shade900 : Colors.white.withOpacity(0.08),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isClaimed ? Colors.green : Colors.white24,
                    ),
                  ),
                ),
                child: Text(
                  isClaimed ? 'ROLE CLAIMED' : 'I WILL DO THIS',
                  style: const TextStyle(
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
    );
  }
}

class GoodSamaritanBottomSheet extends StatelessWidget {
  const GoodSamaritanBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'You are protected by law.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Card 1 - The Law
            _buildLawCard(
              title: 'THE LAW',
              content: "India's Good Samaritan Guidelines 2015 protect anyone who helps an accident victim in good faith.",
              icon: Icons.gavel_rounded,
              cardColor: Colors.blueAccent,
            ),
            const SizedBox(height: 16),

            // Card 2 - What This Means
            _buildLawCard(
              title: 'WHAT THIS MEANS',
              content: 'Police CANNOT detain you for helping. Hospitals CANNOT refuse treatment. You are a hero, not a suspect.',
              icon: Icons.verified_user_rounded,
              cardColor: Colors.green,
            ),
            const SizedBox(height: 16),

            // Card 3 - If Questioned
            _buildLawCard(
              title: 'IF QUESTIONED',
              content: 'State: I am a Good Samaritan under MV Act Section 134 and 2015 Guidelines. I am legally protected.',
              icon: Icons.chat_bubble_rounded,
              cardColor: Colors.amber,
            ),
            const SizedBox(height: 32),

            // Green Understand Button
            SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'I UNDERSTAND — HELP NOW',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLawCard({
    required String title,
    required String content,
    required IconData icon,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: cardColor.withOpacity(0.1),
            child: Icon(icon, color: cardColor),
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
                    fontWeight: FontWeight.w900,
                    color: cardColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.4,
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
