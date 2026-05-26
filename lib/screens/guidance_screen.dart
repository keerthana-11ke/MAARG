import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';

class GuidanceScreen extends ConsumerStatefulWidget {
  const GuidanceScreen({super.key});

  @override
  ConsumerState<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends ConsumerState<GuidanceScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 1; // 1: Conscious question, 2: Breathing question, 3: Bleeding question, 4: Instruction display
  
  bool? _isConscious;
  bool? _isBreathing;
  bool? _isBleeding;

  late AnimationController _warningController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _warningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_warningController);
  }

  @override
  void dispose() {
    _warningController.dispose();
    super.dispose();
  }

  void _speakInstructions(List<String> instructions) {
    final tts = ref.read(ttsProvider);
    final text = instructions.join(". ");
    tts.speak(text);
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
    const primaryColor = Color(0xFFE53935);

    // Determine what to display in the interactive center panel
    Widget centerPanel;
    if (_currentStep == 1) {
      centerPanel = _buildQuestionCard(
        question: 'Is the victim conscious?',
        onYes: () {
          setState(() {
            _isConscious = true;
            _currentStep = 2;
          });
        },
        onNo: () {
          setState(() {
            _isConscious = false;
            _currentStep = 4; // Skip to unconscious instructions
          });
          _speakInstructions([
            "Check breathing immediately.",
            "If breathing, roll to Recovery Position.",
            "If not breathing, begin chest compressions immediately.",
            "Do not move the victim unnecessarily."
          ]);
        },
      );
    } else if (_currentStep == 2) {
      centerPanel = _buildQuestionCard(
        question: 'Is the victim breathing normally?',
        onYes: () {
          setState(() {
            _isBreathing = true;
            _currentStep = 3;
          });
        },
        onNo: () {
          setState(() {
            _isBreathing = false;
            _currentStep = 4; // Skip to CPR instructions
          });
          _speakInstructions([
            "Perform CPR immediately.",
            "Push hard and fast in the center of the chest.",
            "Keep one hundred to one hundred twenty compressions per minute.",
            "Do not stop until help arrives."
          ]);
        },
      );
    } else if (_currentStep == 3) {
      centerPanel = _buildQuestionCard(
        question: 'Is there severe bleeding?',
        onYes: () {
          setState(() {
            _isBleeding = true;
            _currentStep = 4;
          });
          _speakInstructions([
            "Apply firm pressure using a clean cloth.",
            "Do not move the victim unnecessarily.",
            "Keep the victim warm and calm.",
            "Talk to them and say: Help is coming."
          ]);
        },
        onNo: () {
          setState(() {
            _isBleeding = false;
            _currentStep = 4;
          });
          _speakInstructions([
            "Keep the victim warm and calm.",
            "Talk to them, say: Help is coming.",
            "Monitor breathing and pulse closely.",
            "Do not let them move."
          ]);
        },
      );
    } else {
      // Step 4: Show Instructions based on responses
      centerPanel = _buildInstructionCard();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FIRST AID TRIAGE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
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
              // 1. Critical Flashing Warning Banner (Helmet) - ALWAYS VISIBLE
              AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withOpacity(_opacityAnimation.value),
                        width: 2.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.warning_rounded, color: primaryColor, size: 28),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            '⚠ Do NOT remove the helmet unless breathing is blocked. Improper movement may worsen spinal injuries.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 2. Interactive Triage / Guidance Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: centerPanel,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Primary Bottom Navigation CTA: Assign Roles
              SizedBox(
                height: 64, // Minimum height 64px
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to Role screen
                    context.push('/role-assignment');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.people_rounded),
                  label: const Text(
                    'ASSIGN ROLES',
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
    );
  }

  Widget _buildQuestionCard({
    required String question,
    required VoidCallback onYes,
    required VoidCallback onNo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.help_outline, color: Colors.blueAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: onYes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'YES',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: onNo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'NO',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    List<String> items = [];
    String title = "First Aid Instructions";
    IconData cardIcon = Icons.medical_services_rounded;
    Color iconColor = Colors.green;

    if (_isConscious == false) {
      title = "UNCONSCIOUS PATIENT CARE";
      cardIcon = Icons.hotel_rounded;
      iconColor = Colors.orange;
      items = [
        "Check breathing immediately.",
        "If breathing, roll to Recovery Position.",
        "If NOT breathing, begin chest compressions immediately.",
        "Do NOT move the victim unnecessarily."
      ];
    } else if (_isBreathing == false) {
      title = "CPR INTERVENTION REQUIRED";
      cardIcon = Icons.favorite_rounded;
      iconColor = const Color(0xFFE53935);
      items = [
        "Perform CPR immediately.",
        "Push hard and fast in the center of the chest.",
        "Keep 100-120 compressions per minute.",
        "Do NOT stop compressions until medical help arrives."
      ];
    } else if (_isBleeding == true) {
      title = "BLEEDING CONTROL GUIDE";
      cardIcon = Icons.opacity_rounded;
      iconColor = const Color(0xFFE53935);
      items = [
        "Apply firm pressure using a clean cloth",
        "Do NOT move the victim unnecessarily",
        "Keep the victim warm and calm",
        "Talk to them. Say: \"Help is coming.\""
      ];
    } else {
      title = "PATIENT STABILIZED";
      cardIcon = Icons.check_circle_rounded;
      iconColor = Colors.green;
      items = [
        "Keep the victim warm and calm.",
        "Talk to them. Say: \"Help is coming.\"",
        "Monitor breathing and pulse closely.",
        "Do NOT let them move."
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cardIcon, color: iconColor, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                  _isConscious = null;
                  _isBreathing = null;
                  _isBleeding = null;
                });
              },
              icon: const Icon(Icons.restart_alt, color: Colors.grey),
              label: const Text(
                'RE-ASSESS',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
