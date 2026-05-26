import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';

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
    // 3. Go back to Home
    context.go('/');
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

          const SizedBox(height: 36),

          // Support Hotline Card (visible when 'support' is tapped)
          if (_feeling == 'support')
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'iCall Counseling Helpline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Phone: 9152987821',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'You helped someone today. Now let us help you. Safe, free, confidential counseling for post-incident trauma.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );

      bottomButton = SizedBox(
        height: 64,
        child: ElevatedButton(
          onPressed: _finishDebrief,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
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
        title: Text(
          'POST-INCIDENT DEBRIEF (${_currentPage}/3)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.grey,
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
