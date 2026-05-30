import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  final bool isVictim;
  final VoidCallback onComplete;

  const TutorialScreen({
    required this.isVictim,
    required this.onComplete,
    super.key,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getSlides() {
    if (widget.isVictim) {
      return [
        {
          'icon': '📍',
          'title': 'Your Location is Captured',
          'text': 'MAARG has detected your GPS location\nand identified nearby hospitals\nand ambulance services.',
        },
        {
          'icon': '👨👩👧',
          'title': 'Family is Being Notified',
          'text': 'Your saved emergency contact\nwill receive a WhatsApp message\nwith your location right now.',
        },
        {
          'icon': '⏱️',
          'title': 'Golden Hour Has Started',
          'text': 'You have 60 minutes for\ncritical medical intervention.\nFollow the first aid guide carefully.',
        },
      ];
    } else {
      return [
        {
          'icon': '📱',
          'title': "Scan Victim's QR Code",
          'text': 'If the victim has a MAARG QR\nsticker on their helmet or bike,\nscan it to get their emergency contact\nand notify their family instantly.',
        },
        {
          'icon': '🩹',
          'title': 'Follow First Aid Guide',
          'text': 'MAARG will guide you step by step\nthrough first aid in your language.\nYou are legally protected by the\nGood Samaritan Act 2015.',
        },
        {
          'icon': '👥',
          'title': 'Assign Roles to Bystanders',
          'text': 'Coordinate with other bystanders.\nAssign: Caller, First Aid helper,\nand Traffic Controller roles\nto manage the scene efficiently.',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides();
    const primaryColor = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            // Top App Bar/Row with Skip button
            Positioned(
              top: 10,
              right: 16,
              child: TextButton(
                onPressed: widget.onComplete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                ),
                child: const Text(
                  'SKIP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Main PageView content
            Padding(
              padding: const EdgeInsets.only(top: 60.0, bottom: 100.0),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon/Emoji Container
                        if (slide['title'] == 'Family is Being Notified')
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40.0),
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/family_avatar.png',
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withOpacity(0.08),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              slide['icon']!,
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        const SizedBox(height: 48),
                        // Title
                        Text(
                          slide['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Text Description
                        Text(
                          slide['text']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Area
            Positioned(
              left: 32,
              right: 32,
              bottom: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? primaryColor : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Done Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == slides.length - 1) {
                          widget.onComplete();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _currentPage == slides.length - 1
                            ? (widget.isVictim ? 'START' : 'GOT IT')
                            : 'NEXT',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
