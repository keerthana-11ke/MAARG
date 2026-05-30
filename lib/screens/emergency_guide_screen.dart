import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmergencyGuideScreen extends StatefulWidget {
  const EmergencyGuideScreen({super.key});

  @override
  State<EmergencyGuideScreen> createState() => _EmergencyGuideScreenState();
}

class _EmergencyGuideScreenState extends State<EmergencyGuideScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _metronomeController;
  late Animation<double> _scaleAnimation;
  bool _isMetronomePlaying = false;
  int _tabIndex = 0; // 0: CPR, 1: Bleeding, 2: Fracture, 3: Burns, 4: Choking

  @override
  void initState() {
    super.initState();
    _metronomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545), // 110 beats per minute (60,000 ms / 110 = 545 ms)
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _metronomeController, curve: Curves.easeInOut),
    );

    _metronomeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _metronomeController.reverse();
        if (_isMetronomePlaying) {
          HapticFeedback.lightImpact();
        }
      } else if (status == AnimationStatus.dismissed) {
        _metronomeController.forward();
        if (_isMetronomePlaying) {
          HapticFeedback.lightImpact();
        }
      }
    });
  }

  @override
  void dispose() {
    _metronomeController.dispose();
    super.dispose();
  }

  void _toggleMetronome() {
    setState(() {
      _isMetronomePlaying = !_isMetronomePlaying;
      if (_isMetronomePlaying) {
        _metronomeController.forward();
      } else {
        _metronomeController.stop();
        _metronomeController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF0A0A0A);
    const primaryRed = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Emergency Manual',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category scroll list
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildTabChip(0, '❤️ CPR', Colors.red),
                  _buildTabChip(1, '🩸 Bleeding', Colors.redAccent),
                  _buildTabChip(2, '🦴 Fracture', Colors.amber),
                  _buildTabChip(3, '🔥 Burns', Colors.orange),
                  _buildTabChip(4, '💨 Choking', Colors.blue),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            
            // Guide content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: _buildGuideContent(primaryRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(int index, String label, Color color) {
    final isSelected = _tabIndex == index;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        selected: isSelected,
        selectedColor: color.withOpacity(0.3),
        backgroundColor: Colors.white.withOpacity(0.03),
        side: BorderSide(
          color: isSelected ? color : Colors.white10,
          width: 1,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _tabIndex = index;
              // Stop metronome if switching away from CPR
              if (index != 0 && _isMetronomePlaying) {
                _toggleMetronome();
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildGuideContent(Color primaryRed) {
    switch (_tabIndex) {
      case 0:
        return _buildCprGuide(primaryRed);
      case 1:
        return _buildBleedingGuide();
      case 2:
        return _buildFractureGuide();
      case 3:
        return _buildBurnsGuide();
      case 4:
        return _buildChokingGuide();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCprGuide(Color primaryRed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'CPR (Cardiopulmonary Resuscitation)',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'For victims who are unresponsive and not breathing normally.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 24),

        // Metronome Interactive Card
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
                'CPR COMPRESSION METRONOME',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isMetronomePlaying
                          ? primaryRed.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.05),
                      border: Border.all(
                        color: _isMetronomePlaying ? primaryRed : Colors.grey,
                        width: 4 * _scaleAnimation.value,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        color: _isMetronomePlaying ? primaryRed : Colors.grey,
                        size: 40 * _scaleAnimation.value,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                _isMetronomePlaying ? '110 Beats Per Minute' : 'Metronome Stopped',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isMetronomePlaying ? primaryRed : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _toggleMetronome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMetronomePlaying ? Colors.grey.shade900 : primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(_isMetronomePlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(
                    _isMetronomePlaying ? 'STOP METRONOME' : 'START METRONOME',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildStepItem('1', 'Confirm the scene is safe, then check responsiveness (shake shoulders and shout).'),
        _buildStepItem('2', 'Place the heel of one hand in the center of the chest. Interlace your other hand on top.'),
        _buildStepItem('3', 'Push straight down, hard and fast: 2 to 2.4 inches deep, keeping your elbows locked.'),
        _buildStepItem('4', 'Maintain a rate of 100 to 120 compressions per minute (match the metronome pulses).'),
        _buildStepItem('5', 'Allow complete chest recoil between compressions. Minimize interruptions.'),
      ],
    );
  }

  Widget _buildBleedingGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Severe Bleeding Control',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Act quickly to prevent circulatory shock from blood loss.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 24),
        _buildStepItem('1', 'Apply direct pressure immediately on the wound with a clean cloth or sterile dressing.'),
        _buildStepItem('2', 'If bleeding is severe and does not stop, keep pressure applied. Do NOT peel off saturated dressing; pile new pads on top.'),
        _buildStepItem('3', 'Elevate the injured limb above heart level, if possible, while maintaining direct pressure.'),
        _buildStepItem('4', 'Keep the victim warm and calm to reduce cardiac demand.'),
        _buildStepItem('5', 'If bleeding is from a limb and pressure fails, a tourniquet may be applied tight enough to halt arterial flow.'),
      ],
    );
  }

  Widget _buildFractureGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Fracture Handling',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Immobilize the suspected fracture to prevent further soft tissue damage.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 24),
        _buildStepItem('1', 'Do NOT try to push protruding bones back in, and do NOT attempt to realign the limb.'),
        _buildStepItem('2', 'Immobilize the joint above and below the fracture using whatever splint materials are handy (cardboard, wood, folded journals).'),
        _buildStepItem('3', 'Pad the splint to prevent pressure points and secure gently with cloth ties or tape. Verify that it is not too tight.'),
        _buildStepItem('4', 'Apply a cold pack wrapped in a cloth to reduce pain and swelling, if available.'),
        _buildStepItem('5', 'Check circulation (color, temperature) distal to the splinted area frequently.'),
      ],
    );
  }

  Widget _buildBurnsGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Burns Treatment',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cool the burn immediately to stop the thermal damage cascade.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 24),
        _buildStepItem('1', 'Cool the burn under cool, clean, running tap water for 10 to 20 minutes. Do NOT use ice or freezing water.'),
        _buildStepItem('2', 'Remove jewelry, watch, or restrictive clothing from the burned area before it starts to swell.'),
        _buildStepItem('3', 'Do NOT pop any blisters. Popping blisters increases risk of severe infection.'),
        _buildStepItem('4', 'Cover the burn loosely with clean cling wrap, or a sterile, non-adherent pad.'),
        _buildStepItem('5', 'Do NOT apply butter, toothpaste, oils, or home remedies, as they trap heat and contaminate the wound.'),
      ],
    );
  }

  Widget _buildChokingGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choking Response (Heimlich)',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Relieve air obstruction immediately in responsive choking victims.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 24),
        _buildStepItem('1', 'Ask: "Are you choking?" If they can speak or cough strongly, encourage coughing.'),
        _buildStepItem('2', 'If they cannot speak or breathe, stand behind them. Lean the victim slightly forward.'),
        _buildStepItem('3', 'Deliver 5 sharp blows between the shoulder blades with the heel of your hand.'),
        _buildStepItem('4', 'If object is not dislodged, make a fist, place it just above the navel, grab it with your other hand, and give 5 quick, upward abdominal thrusts.'),
        _buildStepItem('5', 'Alternate 5 back blows and 5 abdominal thrusts until the object is expelled, or the victim becomes unresponsive (then begin CPR).'),
      ],
    );
  }

  Widget _buildStepItem(String numStr, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white.withOpacity(0.08),
            child: Text(
              numStr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
