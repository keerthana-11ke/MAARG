import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding(bool setUpProfile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    if (setUpProfile) {
      context.go('/emergency-profile');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            // PageView content
            PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildSlide(
                  icon: "⏱️",
                  iconColor: Colors.amber,
                  title: "Every Second Counts",
                  subtitle: "MAARG guides you through the critical Golden Hour after any road accident.",
                  progressDots: "● ○ ○ ○ ○",
                ),
                _buildSlide(
                  icon: "📍",
                  iconColor: Colors.redAccent,
                  title: "One Tap Emergency Response",
                  subtitle: "Tap REPORT ACCIDENT and MAARG instantly alerts ambulance, notifies your family, and guides nearby bystanders to help.",
                  progressDots: "● ● ○ ○ ○",
                ),
                _buildSlide(
                  icon: "🩺",
                  iconColor: Colors.white,
                  title: "First Aid in Your Language",
                  subtitle: "Step-by-step first aid instructions in Tamil, Hindi or English. Works even without internet.",
                  progressDots: "● ● ● ○ ○",
                ),
                _buildSlide(
                  icon: "🏥",
                  iconColor: Colors.redAccent,
                  title: "Hospital Ready Before You Arrive",
                  subtitle: "When ambulance is called, MAARG connects to the nearest ER so doctors prepare in advance. Zero wasted time on arrival.",
                  progressDots: "● ● ● ● ○",
                ),
                _buildVolumeSosSlide(
                  progressDots: "● ● ● ● ●",
                ),
              ],
            ),

            // Skip Button (Top Right)
            Positioned(
              top: 16,
              right: 24,
              child: TextButton(
                onPressed: () => _completeOnboarding(false),
                child: const Text(
                  "SKIP",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Bottom Navigation & Indicators
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action Buttons
                  if (_currentPage < 4)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "NEXT",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _completeOnboarding(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Set Up My Profile →",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => _completeOnboarding(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Get Started",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required String icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String progressDots,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              icon,
              style: const TextStyle(fontSize: 54),
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Progress indicator text representation (e.g. "● ○ ○ ○")
          Text(
            progressDots,
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontSize: 18,
              letterSpacing: 4.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Bottom spacer to clear the page view buttons
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildVolumeSosSlide({
    required String progressDots,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const VolumeSosDemoAnimation(),
          const SizedBox(height: 24),

          // Title
          const Text(
            "Press Volume Down 3 Times for SOS",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          const Text(
            "In any emergency — forest, accident, danger — press your volume down button 3 times rapidly.\nMAARG instantly sends your GPS location to your emergency contact.\nWorks even with screen off.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Progress indicator text representation (e.g. "● ○ ○ ○")
          Text(
            progressDots,
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontSize: 18,
              letterSpacing: 4.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Bottom spacer to clear the page view buttons
          const SizedBox(height: 140),
        ],
      ),
    );
  }
}

class VolumeSosDemoAnimation extends StatefulWidget {
  const VolumeSosDemoAnimation({super.key});

  @override
  State<VolumeSosDemoAnimation> createState() => _VolumeSosDemoAnimationState();
}

class _VolumeSosDemoAnimationState extends State<VolumeSosDemoAnimation>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _step = 0; // 0: idle, 1: click 1, 2: click 2, 3: click 3, 4: SOS!

  @override
  void initState() {
    super.initState();
    _startAnimationCycle();
  }

  void _startAnimationCycle() {
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) return;
      setState(() {
        _step = (_step + 1) % 5;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryRed = const Color(0xFFE53935);
    final isPressed = _step >= 1 && _step <= 3;
    final isSos = _step == 4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer Phone Shell
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              height: 220,
              decoration: BoxDecoration(
                color: isSos ? primaryRed.withOpacity(0.15) : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSos ? primaryRed : Colors.white24,
                  width: 3,
                ),
                boxShadow: isSos
                    ? [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  // Dynamic Notch
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Phone Screen Content
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildScreenContent(isSos, _step),
                    ),
                  ),
                ],
              ),
            ),
            
            // Highlighted Volume Down Button on Left Side
            Positioned(
              left: -6,
              top: 85,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 6,
                height: 30,
                decoration: BoxDecoration(
                  color: isPressed ? primaryRed : Colors.grey.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    bottomLeft: Radius.circular(3),
                  ),
                  boxShadow: isPressed
                      ? [
                          BoxShadow(
                            color: primaryRed,
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Text display below phone graphic
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSos ? primaryRed.withOpacity(0.2) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSos ? primaryRed.withOpacity(0.4) : Colors.white10,
            ),
          ),
          child: Text(
            _getStatusText(_step),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSos ? Colors.white : Colors.amber,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenContent(bool isSos, int step) {
    if (isSos) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        key: ValueKey('sos_screen'),
        children: [
          Text("🆘", style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(
            "SOS!",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      );
    }
    
    switch (step) {
      case 1:
        return const Text("1", key: ValueKey('1'), style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900));
      case 2:
        return const Text("2", key: ValueKey('2'), style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900));
      case 3:
        return const Text("3", key: ValueKey('3'), style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900));
      default:
        return const Text("🔊", key: ValueKey('idle'), style: TextStyle(color: Colors.white30, fontSize: 32));
    }
  }

  String _getStatusText(int step) {
    switch (step) {
      case 1:
        return "1...";
      case 2:
        return "1... 2...";
      case 3:
        return "1... 2... 3...";
      case 4:
        return "SOS! 🆘";
      default:
        return "Waiting...";
    }
  }
}
