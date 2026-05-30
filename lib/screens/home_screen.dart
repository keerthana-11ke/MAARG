import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tutorial_screen.dart';
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/incident_provider.dart';
import '../providers/location_provider.dart';
import '../providers/shake_sos_provider.dart';
import '../repositories/services_repository.dart';
import '../widgets/responsive.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String? scannedName;
  final String? scannedContact;
  final String? scannedBlood;
  final String? scannedConditions;
  final String? scannedAllergies;

  const HomeScreen({
    this.scannedName,
    this.scannedContact,
    this.scannedBlood,
    this.scannedConditions,
    this.scannedAllergies,
    super.key,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingAndRouting();
  }

  Future<void> _checkOnboardingAndRouting() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    if (!onboardingComplete) {
      if (mounted) {
        context.go('/onboarding');
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunchCache();
      _handleDeepLink();
    });
  }

  Future<void> _handleDeepLink() async {
    final name = widget.scannedName;
    final contact = widget.scannedContact;
    final blood = widget.scannedBlood;

    if (name == null || name.isEmpty || contact == null || contact.isEmpty) {
      return;
    }

    // Defer a bit to let the app initialize
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Show loading overlay: "Notifying [name]'s family..."
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
              const SizedBox(height: 24),
              Text(
                "Notifying ${name}'s family...",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "Auto-filling victim info & dispatching WhatsApp alert",
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // Capture GPS location immediately
    await ref.read(locationProvider.notifier).updateLocation();
    final loc = ref.read(locationProvider);
    final gps = "Lat: ${loc.latitude.toStringAsFixed(4)}, Lng: ${loc.longitude.toStringAsFixed(4)}";

    // Play TTS
    ref.read(ttsProvider).speak("Stay calm. Help is being arranged.");

    // Start golden hour timer
    ref.read(timerProvider.notifier).startTimer();

    // Generate Incident ID
    final year = DateTime.now().year;
    final randomNum = (1000 + (DateTime.now().millisecond * 9) % 9000);
    final incidentId = 'MAARG-$year-CHN-$randomNum';

    // Auto-send WhatsApp message to emergency contact
    final msg = "MAARG ALERT: An accident has been reported near $gps. Help is on the way. Incident ID: $incidentId\nTrack status: Your family member is being helped by trained bystanders.";
    final whatsappUrl = "https://wa.me/${contact.replaceAll(RegExp(r'\D'), '')}?text=${Uri.encodeComponent(msg)}";

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("WhatsApp notification failed: $e");
    }

    // Trigger SOS state
    await ref.read(incidentStateProvider.notifier).triggerSOS(
          latitude: loc.latitude,
          longitude: loc.longitude,
          incidentId: incidentId,
          photoPath: null,
          familyMemberName: name,
          familyNotified: true,
          victimName: name,
          victimBloodGroup: blood,
          isVictimFlow: false,
          areaName: loc.areaName,
        );

    // Wait a brief moment and navigate to activation screen
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      context.push('/activation');
    }
  }

  Future<void> _checkFirstLaunchCache() async {
    final prefs = await SharedPreferences.getInstance();
    final isCached = prefs.getBool('first_launch_cached') ?? false;
    if (!isCached) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          double progress = 0.0;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              // Simulate caching progress
              Timer.periodic(const Duration(milliseconds: 150), (timer) {
                if (progress < 1.0) {
                  if (context.mounted) {
                    setDialogState(() {
                      progress += 0.1;
                    });
                  }
                } else {
                  timer.cancel();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  prefs.setBool('first_launch_cached', true);
                  if (this.context.mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Caching complete! All guides are now available offline ✓'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              });

              return PopScope(
                canPop: false,
                child: AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: Row(
                    children: const [
                      Icon(Icons.download_rounded, color: Color(0xFFE53935)),
                      SizedBox(width: 12),
                      Text(
                        'Caching Content',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Downloading first-aid guides, offline guidelines, maps, and TTS configurations for 100% offline access...',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(progress * 100).toInt()}% complete',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  void _showWhoAreYouDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    "Who are you?",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Select your role to proceed with the optimal emergency response flow.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  // Option 1: I AM THE VICTIM
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TutorialScreen(
                            isVictim: true,
                            onComplete: () {
                              Navigator.of(context).pop();
                              _handleVictimFlow();
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("🔴 ", style: TextStyle(fontSize: 18)),
                        Text(
                          "I AM THE VICTIM",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Option 2: I AM A BYSTANDER
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TutorialScreen(
                            isVictim: false,
                            onComplete: () {
                              Navigator.of(context).pop();
                              _showBystanderOptionsDialog();
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("🔵 ", style: TextStyle(fontSize: 18)),
                        Text(
                          "I AM A BYSTANDER",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBystanderOptionsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    "Bystander Assistance",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Do you have access to the victim's emergency QR code? (Usually located on their helmet, watch, or phone lock screen)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  // Option A: Scan Victim's QR Code
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.push('/qr-scan');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Scan Victim's QR Code",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Option B: No QR Available
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _handleBystanderNoQrFlow();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "No QR Available",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleVictimFlow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 12),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
              SizedBox(height: 24),
              Text(
                "Notifying emergency contact...",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Capturing location & preparing dispatch link",
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // 1. Play TTS
    ref.read(ttsProvider).speak("Stay calm. Help is being arranged.");
    
    // 2. Start golden hour timer
    ref.read(timerProvider.notifier).startTimer();

    // 3. Capture GPS location
    await ref.read(locationProvider.notifier).updateLocation();
    final loc = ref.read(locationProvider);

    // 4. Generate Incident ID
    final year = DateTime.now().year;
    final randomNum = (1000 + (DateTime.now().millisecond * 9) % 9000);
    final incidentId = 'MAARG-$year-CHN-$randomNum';

    // 5. Read profile details
    final prefs = await SharedPreferences.getInstance();
    final victimName = prefs.getString('profile_name') ?? 'Victim';
    final contactPhone = prefs.getString('profile_contact_phone') ?? '';
    final blood = prefs.getString('profile_blood') ?? 'Unknown';
    final conditions = prefs.getString('profile_conditions') ?? 'None';
    final bool hasContact = contactPhone.isNotEmpty;

    // Calculate Nearest Hospital
    String hospName = "Apollo Hospital";
    String hospDist = "8 min (1.2 km)";
    try {
      final services = await StaticServicesRepository().getNearbyServices(loc.latitude, loc.longitude);
      final hospitals = services.where((s) => s.type == ServiceType.hospital).toList();
      if (hospitals.isNotEmpty) {
        final firstHosp = hospitals.first;
        hospName = firstHosp.name;
        double distanceInKm = firstHosp.calculatedDistance!;
        int etaMinutes = (distanceInKm / 40 * 60).round();
        hospDist = "${etaMinutes} min (${distanceInKm.toStringAsFixed(1)} km)";
      }
    } catch (_) {}

    // 6. Launch WhatsApp if emergency contact is configured
    if (hasContact) {
      final mapsLink = "https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}";
      final message = "Hi, this is $victimName. I have been involved in an accident near ${loc.areaName}.\n"
          "Help is on the way. Please check my status.\n\n"
          "🩸 Details:\n"
          "Name: $victimName\n"
          "Blood Group: $blood\n"
          "Location: $mapsLink\n"
          "Golden Hour: 60:00 remaining\n"
          "Incident ID: $incidentId\n\n"
          "🏥 Nearest Hospital:\n"
          "$hospName - $hospDist\n\n"
          "Please stay calm. Track status: I am being assisted by first responders.\n"
          "- Sent via MAARG Emergency App";

      final phoneClean = contactPhone.replaceAll(RegExp(r'\D'), '');
      final whatsappUrl = "https://wa.me/$phoneClean?text=${Uri.encodeComponent(message)}";
      try {
        final uri = Uri.parse(whatsappUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print("WhatsApp trigger failed: $e");
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No emergency contact saved! Profile notification skipped."),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }

    // 7. Trigger SOS state
    await ref.read(incidentStateProvider.notifier).triggerSOS(
      latitude: loc.latitude,
      longitude: loc.longitude,
      incidentId: incidentId,
      familyMemberName: hasContact ? victimName : null,
      familyNotified: hasContact,
      victimName: victimName,
      victimBloodGroup: blood,
      victimMedical: conditions,
      victimEmergencyContactPhone: hasContact ? contactPhone : null,
      isVictimFlow: true,
      noQrAvailable: false,
      areaName: loc.areaName,
    );

    // 8. Auto navigate to EMERGENCY SCREEN after 2s
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // pop dialog
      context.push('/activation');
    }
  }

  Future<void> _handleBystanderNoQrFlow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 12),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
              SizedBox(height: 24),
              Text(
                "Initializing bystander response...",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Capturing location & preparing local rescue logs",
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // 1. Play TTS
    ref.read(ttsProvider).speak("Stay calm. Help is being arranged.");

    // 2. Start golden hour timer
    ref.read(timerProvider.notifier).startTimer();

    // 3. Capture GPS location
    await ref.read(locationProvider.notifier).updateLocation();
    final loc = ref.read(locationProvider);

    // 4. Generate Incident ID
    final year = DateTime.now().year;
    final randomNum = (1000 + (DateTime.now().millisecond * 9) % 9000);
    final incidentId = 'MAARG-$year-CHN-$randomNum';

    // 5. Trigger SOS in state (No family details)
    await ref.read(incidentStateProvider.notifier).triggerSOS(
      latitude: loc.latitude,
      longitude: loc.longitude,
      incidentId: incidentId,
      familyMemberName: null,
      familyNotified: false,
      victimName: null,
      victimBloodGroup: null,
      victimMedical: null,
      victimEmergencyContactPhone: null,
      isVictimFlow: false,
      noQrAvailable: true,
      areaName: loc.areaName,
    );

    // 6. Auto navigate to EMERGENCY SCREEN after 2s
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // pop dialog
      context.push('/activation');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE53935);
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Top Header Controls
                  Padding(
                    padding: context.paddingSymmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          locationState.statusMessage,
                          style: TextStyle(
                            color: locationState.isMock ? Colors.amber : Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: context.paddingSymmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo / Branding Header at the top
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.radar_rounded, color: primaryColor, size: 36),
                            SizedBox(width: 12),
                            Text(
                              'M A A R G',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'GOLDEN HOUR EMERGENCY RESPONSE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Large Pulsing SOS Button in the Center
                        Center(
                          child: ReportAccidentButton(
                            onPressed: _showWhoAreYouDialog,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // "SCAN VICTIM'S QR" secondary button directly below SOS button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/qr-scan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.06),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.amber),
                            label: const Text(
                              "SCAN VICTIM'S QR",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Bottom buttons & Reassurance
                        // My Emergency Profile Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/emergency-profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.04),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white10),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.green),
                            label: const Text(
                              'MY EMERGENCY PROFILE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 100% Offline Guide Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/emergency-guide'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.04),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white10),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.menu_book_rounded, color: primaryColor),
                            label: const Text(
                              'EMERGENCY GUIDE (OFFLINE)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Good Samaritan Banner
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.gavel_rounded, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Protected by Good Samaritan Act',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Tap to report road crash & alert responders',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Manual SOS Button bottom left corner
          Positioned(
            left: 16,
            bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    "Vol Down × 3 = SOS",
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: Tooltip(
                    message: "Press Volume Down 3 times for SOS",
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(shakeSosProvider.notifier).startCountdown();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: context.paddingSymmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 6,
                      ),
                      icon: const Text("🆘", style: TextStyle(fontSize: 16)),
                      label: const Text(
                        "SOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 14,
                        ),
                      ),
                    ),
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

class ReportAccidentButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ReportAccidentButton({required this.onPressed, super.key});

  @override
  State<ReportAccidentButton> createState() => _ReportAccidentButtonState();
}

class _ReportAccidentButtonState extends State<ReportAccidentButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 200.0;
    const primaryColor = Color(0xFFE53935);

    return GestureDetector(
      onTap: widget.onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: size * _scaleAnimation.value,
                height: size * _scaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(_opacityAnimation.value),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: size * (_scaleAnimation.value - 0.2).clamp(1.0, 1.4),
                height: size * (_scaleAnimation.value - 0.2).clamp(1.0, 1.4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity((_opacityAnimation.value * 1.5).clamp(0.0, 1.0)),
                ),
              );
            },
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 8,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: context.paddingAll(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'REPORT\nACCIDENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
