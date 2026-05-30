import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/gemini_provider.dart';

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

  String _selectedLang = 'EN'; // 'EN', 'TA', 'HI'
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  String? _aiResponse;

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
    try {
      ref.read(ttsProvider).stop();
    } catch (_) {}
    super.dispose();
  }

  String _getLangCode(String lang) {
    switch (lang) {
      case 'TA': return 'ta-IN';
      case 'HI': return 'hi-IN';
      default: return 'en-US';
    }
  }

  Future<void> _speakText(String text) async {
    final tts = ref.read(ttsProvider);
    await tts.setLanguage(_getLangCode(_selectedLang));
    await tts.speak(text);
  }

  Future<void> _speakInstructions(List<String> instructions) async {
    final tts = ref.read(ttsProvider);
    await tts.setLanguage(_getLangCode(_selectedLang));
    final text = instructions.join(". ");
    await tts.speak(text);
  }

  void _speakCurrentStep() {
    if (_currentStep == 1) {
      _speakText(_getLocalizedQuestion('conscious'));
    } else if (_currentStep == 2) {
      _speakText(_getLocalizedQuestion('breathing'));
    } else if (_currentStep == 3) {
      _speakText(_getLocalizedQuestion('bleeding'));
    } else if (_currentStep == 4) {
      final data = _getLocalizedData();
      _speakInstructions(List<String>.from(data['items']));
    }
  }

  void _triggerAutoRead() {
    _speakCurrentStep();
  }

  Future<void> _scanInjury() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return;

      if (!mounted) return;
      final controller = TextEditingController();
      final description = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white10),
            ),
            title: const Text(
              'Describe what you see',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'e.g. bleeding, swelling, burn',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter injury details...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, controller.text.trim());
                },
                child: const Text('Analyze', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );

      if (description == null || description.isEmpty) return;

      setState(() {
        _selectedImage = image;
        _isAnalyzing = true;
        _aiResponse = null;
      });

      final gemini = ref.read(geminiProvider);
      final response = await gemini.analyzeInjury(description);

      setState(() {
        _aiResponse = response;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _aiResponse = "Failed to run AI assessment: $e";
        _isAnalyzing = false;
      });
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
    const primaryColor = Color(0xFFE53935);

    // Determine what to display in the interactive center panel
    Widget centerPanel;
    if (_currentStep == 1) {
      centerPanel = _buildQuestionCard(
        question: _getLocalizedQuestion('conscious'),
        onYes: () {
          setState(() {
            _isConscious = true;
            _currentStep = 2;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakCurrentStep();
          });
        },
        onNo: () {
          setState(() {
            _isConscious = false;
            _currentStep = 4; // Skip to unconscious instructions
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakCurrentStep();
          });
        },
      );
    } else if (_currentStep == 2) {
      centerPanel = _buildQuestionCard(
        question: _getLocalizedQuestion('breathing'),
        onYes: () {
          setState(() {
            _isBreathing = true;
            _currentStep = 3;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakCurrentStep();
          });
        },
        onNo: () {
          setState(() {
            _isBreathing = false;
            _currentStep = 4; // Skip to CPR instructions
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakCurrentStep();
          });
        },
      );
    } else if (_currentStep == 3) {
      centerPanel = _buildQuestionCard(
        question: _getLocalizedQuestion('bleeding'),
        onYes: () {
          setState(() {
            _isBleeding = true;
            _currentStep = 4;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakCurrentStep();
          });
        },
        onNo: () {
          setState(() {
            _isBleeding = false;
            _currentStep = 4;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakCurrentStep();
          });
        },
      );
    } else {
      // Step 4: Show Instructions based on responses
      centerPanel = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInstructionCard(),
          const SizedBox(height: 20),
          _buildAiAssessmentCard(),
        ],
      );
    }

    final isMuted = ref.watch(ttsMuteProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'First Aid',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.grey),
            onPressed: () {
              ref.read(ttsProvider).toggleMute();
            },
          ),
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: timerColor.withOpacity(0.1),
              border: Border.all(color: timerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDuration(secondsRemaining),
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: timerColor,
              ),
            ),
          ),
        ],
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
                    margin: const EdgeInsets.only(bottom: 16),
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

              // 1b. Language Selector Row
              _buildLanguageSelector(),

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
                width: double.infinity,
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

  Widget _buildLanguageSelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLangButton('EN', 'EN'),
              Container(height: 16, width: 1, color: Colors.white24),
              _buildLangButton('தமிழ்', 'TA'),
              Container(height: 16, width: 1, color: Colors.white24),
              _buildLangButton('हिंदी', 'HI'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            _speakCurrentStep();
          },
          icon: const Text('🔊', style: TextStyle(fontSize: 16)),
          label: const Text(
            'Tap to hear instructions',
            style: TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLangButton(String label, String langCode) {
    final isSelected = _selectedLang == langCode;
    return TextButton(
      onPressed: () async {
        setState(() {
          _selectedLang = langCode;
        });
        _triggerAutoRead();
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFFE53935) : Colors.grey,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  String _getLocalizedQuestion(String key) {
    final lang = _selectedLang;
    if (key == 'conscious') {
      return lang == 'TA'
          ? 'பாதிக்கப்பட்டவர் உணர்வுடன் இருக்கிறாரா?'
          : lang == 'HI'
              ? 'क्या पीड़ित होश में है?'
              : 'Is the victim conscious?';
    } else if (key == 'breathing') {
      return lang == 'TA'
          ? 'பாதிக்கப்பட்டவர் சாதாரணமாக சுவாசிக்கிறாரா?'
          : lang == 'HI'
              ? 'क्या पीड़ित सामान्य रूप से सांस ले रहा है?'
              : 'Is the victim breathing normally?';
    } else if (key == 'bleeding') {
      return lang == 'TA'
          ? 'கடுமையான இரத்தப்போக்கு உள்ளதா?'
          : lang == 'HI'
              ? 'क्या गंभीर रक्तस्राव हो रहा है?'
              : 'Is there severe bleeding?';
    }
    return '';
  }

  String _getLocalizedButtonText(bool isYes) {
    final lang = _selectedLang;
    if (isYes) {
      return lang == 'TA' ? 'ஆம்' : lang == 'HI' ? 'हाँ' : 'YES';
    } else {
      return lang == 'TA' ? 'இல்லை' : lang == 'HI' ? 'नहीं' : 'NO';
    }
  }

  Map<String, dynamic> _getLocalizedData() {
    final lang = _selectedLang;
    if (_isConscious == false) {
      return {
        'title': lang == 'TA'
            ? "மயக்கமடைந்த நோயாளி பராமரிப்பு"
            : lang == 'HI'
                ? "बेहोश मरीज की देखभाल"
                : "UNCONSCIOUS PATIENT CARE",
        'cardIcon': Icons.hotel_rounded,
        'iconColor': Colors.orange,
        'items': lang == 'TA'
            ? [
                "உடனடியாக சுவாசத்தை சரிபார்க்கவும்.",
                "சுவாசம் இருந்தால், படுக்க வைக்கவும் (Recovery Position).",
                "சுவாசம் இல்லை என்றால், உடனடியாக சிபிஆர் (CPR) தொடங்கவும்.",
                "பாதிக்கப்பட்டவரை தேவையின்றி நகர்த்த வேண்டாம்."
              ]
            : lang == 'HI'
                ? [
                    "तुरंत सांस की जांच करें।",
                    "यदि सांस चल रही है, तो रिकवरी स्थिति में लिटाएं।",
                    "यदि सांस नहीं चल रही है, तो तुरंत सीपीआर शुरू करें।",
                    "पीड़ित को अनावश्यक रूप से न हिलाएं।"
                  ]
                : [
                    "Check breathing immediately.",
                    "If breathing, roll to Recovery Position.",
                    "If NOT breathing, begin chest compressions immediately.",
                    "Do NOT move the victim unnecessarily."
                  ]
      };
    } else if (_isBreathing == false) {
      return {
        'title': lang == 'TA'
            ? "சிபிஆர் சிகிச்சை தேவைப்படுகிறது"
            : lang == 'HI'
                ? "सीपीआर हस्तक्षेप की आवश्यकता है"
                : "CPR INTERVENTION REQUIRED",
        'cardIcon': Icons.favorite_rounded,
        'iconColor': const Color(0xFFE53935),
        'items': lang == 'TA'
            ? [
                "உடனடியாக சிபிஆர் (CPR) செய்யவும்.",
                "நெஞ்சின் மையப்பகுதியில் வேகமாக அழுத்தவும்.",
                "நிமிடத்திற்கு 100-120 முறை அழுத்தவும்.",
                "மருத்துவ உதவி வரும் வரை அழுத்தத்தை நிறுத்த வேண்டாம்."
              ]
            : lang == 'HI'
                ? [
                    "तुरंत सीपीआर करें।",
                    "छाती के केंद्र में तेजी से और जोर से दबाएं।",
                    "प्रति मिनट १०० से १२० बार दबाएं।",
                    "चिकित्सीय सहायता आने तक छाती दबाना बंद न करें।"
                  ]
                : [
                    "Perform CPR immediately.",
                    "Push hard and fast in the center of the chest.",
                    "Keep 100-120 compressions per minute.",
                    "Do NOT stop compressions until medical help arrives."
                  ]
      };
    } else if (_isBleeding == true) {
      return {
        'title': lang == 'TA'
            ? "இரத்தப்போக்கு கட்டுப்பாட்டு வழிகாட்டி"
            : lang == 'HI'
                ? "रक्तस्राव नियंत्रण गाइड"
                : "BLEEDING CONTROL GUIDE",
        'cardIcon': Icons.opacity_rounded,
        'iconColor': const Color(0xFFE53935),
        'items': lang == 'TA'
            ? [
                "சுத்தமான துணியால் பலமாக அழுத்தவும்.",
                "பாதிக்கப்பட்டவரை தேவையின்றி நகர்த்த வேண்டாம்.",
                "பாதிக்கப்பட்டவரை சூடாகவும் அமைதியாகவும் வைத்திருக்கவும்.",
                "அவர்களிடம் பேசுங்கள். 'உதவி வருகிறது' என்று சொல்லுங்கள்."
              ]
            : lang == 'HI'
                ? [
                    "साफ कपड़े से जोर से दबाव डालें।",
                    "पीड़ित को अनावश्यक रूप से न हिलाएं।",
                    "पीड़ित को गर्म और शांत रखें।",
                    "उनसे बात करें। कहें: 'मदद आ रही है।'"
                  ]
                : [
                    "Apply firm pressure using a clean cloth.",
                    "Do NOT move the victim unnecessarily.",
                    "Keep the victim warm and calm.",
                    "Talk to them. Say: \"Help is coming.\""
                  ]
      };
    } else {
      return {
        'title': lang == 'TA'
            ? "நோயாளி சீராக உள்ளார்"
            : lang == 'HI'
                ? "मरीज की स्थिति स्थिर है"
                : "PATIENT STABILIZED",
        'cardIcon': Icons.check_circle_rounded,
        'iconColor': Colors.green,
        'items': lang == 'TA'
            ? [
                "பாதிக்கப்பட்டவரை சூடாகவும் அமைதியாகவும் வைத்திருக்கவும்.",
                "அவர்களிடம் பேசுங்கள். 'உதவி வருகிறது' என்று சொல்லுங்கள்.",
                "சுவாசம் மற்றும் நாடித் துடிப்பைக் கண்காணிக்கவும்.",
                "அவர்களை நகர விட வேண்டாம்."
              ]
            : lang == 'HI'
                ? [
                    "पीड़ित को गर्म और शांत रखें।",
                    "उनसे बात करें। कहें: 'मदद आ रही है।'",
                    "सांस और नाड़ी की बारीकी से निगरानी करें।",
                    "उन्हें हिलने न दें।"
                  ]
                : [
                    "Keep the victim warm and calm.",
                    "Talk to them. Say: \"Help is coming.\"",
                    "Monitor breathing and pulse closely.",
                    "Do NOT let them move."
                  ]
      };
    }
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
                    child: Text(
                      _getLocalizedButtonText(true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    child: Text(
                      _getLocalizedButtonText(false),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    final data = _getLocalizedData();
    final String title = data['title'] as String;
    final IconData cardIcon = data['cardIcon'] as IconData;
    final Color iconColor = data['iconColor'] as Color;
    final List<String> items = List<String>.from(data['items']);

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
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
                onPressed: () => _speakInstructions(items),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _scanInjury,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935).withOpacity(0.2),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE53935)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text(
                    'SCAN INJURY',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 1;
                      _isConscious = null;
                      _isBreathing = null;
                      _isBleeding = null;
                      _selectedImage = null;
                      _aiResponse = null;
                    });
                    try {
                      ref.read(ttsProvider).stop();
                    } catch (_) {}
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
        ],
      ),
    );
  }

  Widget _buildAiAssessmentCard() {
    if (_selectedImage == null && !_isAnalyzing && _aiResponse == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE53935).withOpacity(0.08),
            Colors.deepPurple.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'GEMINI AI ASSESSMENT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(_selectedImage!.path, width: 40, height: 40, fit: BoxFit.cover)
                      : Image.file(io.File(_selectedImage!.path), width: 40, height: 40, fit: BoxFit.cover),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isAnalyzing)
            Center(
              child: Column(
                children: const [
                  CircularProgressIndicator(color: Color(0xFFE53935)),
                  SizedBox(height: 12),
                  Text(
                    'Analyzing injury image with Gemini Vision AI...',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else if (_aiResponse != null) ...[
            Text(
              _aiResponse!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI assessment — not a substitute for medical advice',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
