import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/incident_provider.dart';

class DebriefScreen extends ConsumerStatefulWidget {
  const DebriefScreen({super.key});

  @override
  ConsumerState<DebriefScreen> createState() => _DebriefScreenState();
}

class _DebriefScreenState extends ConsumerState<DebriefScreen> {
  int _currentPage = 1; // 1: Reassurance, 2: What you did, 3: Feeling check-in
  String? _feeling; // 'okay', 'shaken', 'support'

  @override
  void initState() {
    super.initState();
    // Speak on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsProvider).speak("You were a hero today.");
    });
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
    });
  }

  void _finishDebrief() {
    // 1. Reset golden hour timer
    ref.read(timerProvider.notifier).resetTimer();
    // 2. Stop TTS if active
    ref.read(ttsProvider).stop();
    // 3. Go to Community Impact & Heatmap Screen
    context.push('/heatmap');
  }

  void _onDonePressed() {
    if (_feeling == 'okay') {
      _showCompletionDialog();
    } else {
      _finishDebrief();
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showCompletionDialog() {
    final state = ref.read(incidentStateProvider);
    final incidentId = state.evidenceIncidentId ?? state.lastActiveIncidentId ?? 'MAARG-INC-0000';
    final timestamp = state.evidenceTimestamp?.toLocal().toString().substring(0, 16) ?? DateTime.now().toLocal().toString().substring(0, 16);
    final location = "${state.evidenceLatitude?.toStringAsFixed(4) ?? '12.9716'}, ${state.evidenceLongitude?.toStringAsFixed(4) ?? '77.5946'}";
    final family = state.familyNotified ? "Yes (${state.familyMemberName})" : "No";
    
    final respondersList = state.volunteers.map((v) => "${v.name} (${v.role})").join(', ');
    final respondersText = respondersList.isEmpty ? "None" : respondersList;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text(
              "Thank You!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Thank you for stepping forward as a Good Samaritan today. Your support and actions during the golden hour have made a massive difference.",
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            const Text(
              "INCIDENT SUMMARY",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildDialogInfoRow("Incident ID", incidentId),
            _buildDialogInfoRow("Time of Report", timestamp),
            _buildDialogInfoRow("Location", location),
            _buildDialogInfoRow("Family Notified", family),
            _buildDialogInfoRow("Responders", respondersText),
            _buildDialogInfoRow("Welfare Tracking", "😊 I'm okay"),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _finishDebrief();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "CLOSE & FINISH",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$label:",
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalmingBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Calming Breathing Tips",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Following a stressful incident, it is natural to feel shaken. Try the 4-7-8 breathing technique to calm your heart rate and nervous system.",
                style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              const BreatheVisualizer(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showSupportBottomSheet() {
    final state = ref.read(incidentStateProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mental Health Support",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "You stepped forward to help today. Now, let these professional trauma and counseling counselors support you. Tapping a contact will initiate a call.",
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              
              _buildSupportContactTile(
                title: "NIMHANS Helpline",
                number: "080-46110007",
                subtitle: "Govt. of India mental health support",
              ),
              const SizedBox(height: 10),
              
              _buildSupportContactTile(
                title: "iCall Counseling",
                number: "9152987821",
                subtitle: "TISS confidential emotional helpline",
              ),
              const SizedBox(height: 10),

              _buildSupportContactTile(
                title: "Vandrevala Foundation",
                number: "1860-2662-345",
                subtitle: "24/7 free counseling & trauma response",
              ),
              const SizedBox(height: 24),
              
              const Text(
                "CONNECT TO ACTIVE RESPONDERS",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              if (state.volunteers.isEmpty)
                const Text(
                  "No active volunteer responders listed for counseling.",
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                )
              else
                ...state.volunteers.map((vol) {
                  return Card(
                    color: Colors.white.withOpacity(0.02),
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE53935).withOpacity(0.1),
                        child: const Icon(Icons.person_outline, color: Color(0xFFE53935)),
                      ),
                      title: Text(
                        "${vol.name} (${vol.role})",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text(
                        "Responded to your incident; available for peer support",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Connecting to peer counselor ${vol.name} via helpline..."),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("CONNECT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildSupportContactTile({
    required String title,
    required String number,
    required String subtitle,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              number,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.phone_in_talk, color: Colors.green),
          onPressed: () => _makeCall(number),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE53935);

    Widget content;
    Widget? bottomButton;

    if (_currentPage == 1) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Large Green Checkmark Circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green, width: 3),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.green,
              size: 72,
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            'You did the right thing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Because of you, the victim had a better chance. You stepped forward when others stood back.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ),
        ],
      );

      bottomButton = SizedBox(
        height: 64,
        child: ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'NEXT',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
      );
    } else if (_currentPage == 2) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'What you did:',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildActionItem('Activated emergency response network'),
          _buildActionItem('Guided first aid triage correctly'),
          _buildActionItem('Assigned vital bystander coordination roles'),
          _buildActionItem('Prevented harmful actions and crowd panic'),
        ],
      );

      bottomButton = SizedBox(
        height: 64,
        child: ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'NEXT',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'How are you feeling right now?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Feeling buttons
          Row(
            children: [
              Expanded(
                child: _buildFeelingButton('😊 I\'m okay', 'okay'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeelingButton('😟 A bit shaken', 'shaken'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeelingButton('🆘 Need support', 'support'),

          if (_feeling == 'shaken') ...[
            const SizedBox(height: 24),
            InkWell(
              onTap: _showCalmingBottomSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.spa, color: Colors.amber),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Tap here to re-open the calming breathing exercise.",
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.amber),
                  ],
                ),
              ),
            ),
          ] else if (_feeling == 'support') ...[
            const SizedBox(height: 24),
            InkWell(
              onTap: _showSupportBottomSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.support_agent, color: primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Tap here to re-open emergency mental health contacts & responder list.",
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: primaryColor),
                  ],
                ),
              ),
            ),
          ]
        ],
      );

      bottomButton = SizedBox(
        height: 64,
        child: ElevatedButton(
          onPressed: _feeling == null ? null : _onDonePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            disabledBackgroundColor: Colors.grey.shade900,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'DONE',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'POST-INCIDENT DEBRIEF (${_currentPage}/3)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.grey,
            ),
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Indicators (Dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageDot(1),
                  const SizedBox(width: 8),
                  _buildPageDot(2),
                  const SizedBox(width: 8),
                  _buildPageDot(3),
                ],
              ),
              const SizedBox(height: 24),

              // Page Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: content,
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Button
              if (bottomButton != null) bottomButton,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageDot(int pageNum) {
    final isActive = _currentPage == pageNum;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFFE53935) : Colors.grey.shade800,
      ),
    );
  }

  Widget _buildActionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
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
    );
  }

  Widget _buildFeelingButton(String label, String value) {
    final isSelected = _feeling == value;
    final primaryColor = const Color(0xFFE53935);

    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _feeling = value;
          });
          ref.read(incidentStateProvider.notifier).setDebriefFeeling(value);
          if (value == 'shaken') {
            _showCalmingBottomSheet();
          } else if (value == 'support') {
            _showSupportBottomSheet();
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.grey.shade800,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isSelected ? primaryColor : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class BreatheVisualizer extends StatefulWidget {
  const BreatheVisualizer({super.key});

  @override
  State<BreatheVisualizer> createState() => _BreatheVisualizerState();
}

class _BreatheVisualizerState extends State<BreatheVisualizer> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  int _secondsLeft = 4;
  String _phase = 'Inhale'; // 'Inhale', 'Hold', 'Exhale'
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startBreathing() {
    setState(() {
      _isActive = true;
      _phase = 'Inhale';
      _secondsLeft = 4;
    });
    _runCycle();
  }

  void _runCycle() {
    if (!_isActive) return;

    if (_phase == 'Inhale') {
      _animationController.duration = const Duration(seconds: 4);
      _animationController.forward(from: 0.0);
      _startTimer(4, () {
        if (mounted && _isActive) {
          setState(() {
            _phase = 'Hold';
            _secondsLeft = 7;
          });
          _runCycle();
        }
      });
    } else if (_phase == 'Hold') {
      _startTimer(7, () {
        if (mounted && _isActive) {
          setState(() {
            _phase = 'Exhale';
            _secondsLeft = 8;
          });
          _runCycle();
        }
      });
    } else if (_phase == 'Exhale') {
      _animationController.duration = const Duration(seconds: 8);
      _animationController.reverse(from: 1.0);
      _startTimer(8, () {
        if (mounted && _isActive) {
          setState(() {
            _phase = 'Inhale';
            _secondsLeft = 4;
          });
          _runCycle();
        }
      });
    }
  }

  void _startTimer(int seconds, VoidCallback onComplete) {
    _timer?.cancel();
    setState(() {
      _secondsLeft = seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isActive) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          timer.cancel();
          onComplete();
        }
      });
    });
  }

  void _stopBreathing() {
    _timer?.cancel();
    _animationController.stop();
    setState(() {
      _isActive = false;
      _phase = 'Inhale';
      _secondsLeft = 4;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color phaseColor;
    if (_phase == 'Inhale') {
      phaseColor = Colors.blueAccent;
    } else if (_phase == 'Hold') {
      phaseColor = Colors.amber;
    } else {
      phaseColor = Colors.green;
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: phaseColor.withOpacity(0.2),
                  border: Border.all(color: phaseColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: phaseColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _isActive ? '$_secondsLeft' : 'Ready',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isActive ? _phase.toUpperCase() : '4-7-8 Breathing',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: phaseColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isActive
              ? (_phase == 'Inhale'
                  ? 'Breathe in slowly through your nose...'
                  : _phase == 'Hold'
                      ? 'Hold your breath...'
                      : 'Exhale fully through your mouth...')
              : 'Calm your mind and nervous system.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          width: 200,
          child: ElevatedButton(
            onPressed: _isActive ? _stopBreathing : _startBreathing,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isActive ? Colors.grey.shade900 : const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isActive ? 'STOP' : 'START EXERCISE',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
