import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart' as qr_decoder;
import 'package:url_launcher/url_launcher.dart';
import '../providers/incident_provider.dart';
import '../providers/location_provider.dart';
import '../providers/tts_provider.dart';
import '../providers/timer_provider.dart';

class VictimProfile {
  final String name;
  final String bloodGroup;
  final String emergencyContactPhone;
  final String medicalConditions;

  VictimProfile({
    required this.name,
    required this.bloodGroup,
    required this.emergencyContactPhone,
    required this.medicalConditions,
  });

  factory VictimProfile.parse(String text) {
    String name = "Karthik";
    String blood = "B+";
    String phone = "9876543210";
    String medical = "None";

    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('victim name:')) {
        name = line.substring(line.indexOf(':') + 1).trim();
      } else if (lower.startsWith('blood group:')) {
        blood = line.substring(line.indexOf(':') + 1).trim();
      } else if (lower.startsWith('emergency contact:')) {
        phone = line.substring(line.indexOf(':') + 1).trim();
      } else if (lower.startsWith('conditions:')) {
        medical = line.substring(line.indexOf(':') + 1).trim();
      }
    }

    if (text.contains('?')) {
      try {
        final uri = Uri.parse(text.trim());
        name = uri.queryParameters['name'] ?? name;
        phone = uri.queryParameters['contact'] ?? phone;
        blood = uri.queryParameters['blood'] ?? blood;
        medical = uri.queryParameters['conditions'] ?? medical;
      } catch (_) {}
    }

    return VictimProfile(
      name: name,
      bloodGroup: blood,
      emergencyContactPhone: phone,
      medicalConditions: medical,
    );
  }
}

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  MobileScannerController? _mobileController;
  VictimProfile? _profile;
  bool _isProcessing = false;
  bool _familyNotified = false;
  String? _generatedIncidentId;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _mobileController = MobileScannerController();
    }
    // Generate Incident ID
    final year = DateTime.now().year;
    final randomNum = (1000 + (DateTime.now().millisecond * 9) % 9000);
    _generatedIncidentId = 'MAARG-$year-CHN-$randomNum';
  }

  @override
  void dispose() {
    _mobileController?.dispose();
    super.dispose();
  }

  Future<void> _uploadAndDecode() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final decoder = qr_decoder.QrCodeDartDecoder(formats: [qr_decoder.BarcodeFormat.qrCode]);
        final result = await decoder.decodeFile(bytes);
        if (result != null && result.text != null && result.text!.isNotEmpty) {
          setState(() {
            _profile = VictimProfile.parse(result.text!);
          });
        } else {
          _showError("No QR Code detected in image. Please choose another photo.");
        }
      }
    } catch (e) {
      _showError("Failed to read image: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _triggerBystanderWhatsApp() async {
    if (_profile == null) return;
    final locState = ref.read(locationProvider);
    final incidentState = ref.read(incidentStateProvider);
    
    final lat = locState.latitude;
    final lon = locState.longitude;
    final areaName = locState.areaName;
    final mapsLink = "https://www.google.com/maps/search/?api=1&query=$lat,$lon";
    final incId = _generatedIncidentId ?? "MAARG-2026-CHN-1001";
    final hospName = incidentState.nearestHospitalName ?? "Apollo Hospital";
    final hospDist = incidentState.nearestHospitalDistance ?? "1.2km";

    final message = "Hi, I am a bystander. I found ${_profile!.name} injured near $areaName.\n"
        "I am helping them using the MAARG Emergency Response app.\n"
        "Please don't panic - I have already called the ambulance and trained bystanders are helping right now.\n\n"
        "🩸 Victim Details:\n"
        "Name: ${_profile!.name}\n"
        "Blood Group: ${_profile!.bloodGroup}\n"
        "Location: $mapsLink\n"
        "Incident ID: $incId\n\n"
        "🏥 Nearest Hospital:\n"
        "$hospName - $hospDist\n\n"
        "Help is on the way. Please stay calm.\n"
        "- Sent via MAARG Emergency App";

    final phoneClean = _profile!.emergencyContactPhone.replaceAll(RegExp(r'\D'), '');
    final url = "https://wa.me/$phoneClean?text=${Uri.encodeComponent(message)}";

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() {
          _familyNotified = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp family alert triggered ✓'), backgroundColor: Colors.green),
          );
        }
      } else {
        _showError("Could not launch WhatsApp application.");
      }
    } catch (e) {
      _showError("Error triggering WhatsApp: $e");
    }
  }

  Future<void> _startEmergencyFlow() async {
    if (_profile == null) return;
    setState(() {
      _isProcessing = true;
    });

    // 1. Play TTS
    ref.read(ttsProvider).speak("Stay calm. Help is being arranged.");
    
    // 2. Start golden hour timer
    ref.read(timerProvider.notifier).startTimer();

    // 3. Make sure location is acquired
    await ref.read(locationProvider.notifier).updateLocation();
    final locState = ref.read(locationProvider);

    // 4. Trigger SOS in state
    await ref.read(incidentStateProvider.notifier).triggerSOS(
      latitude: locState.latitude,
      longitude: locState.longitude,
      incidentId: _generatedIncidentId ?? "MAARG-2026-CHN-1001",
      familyMemberName: _profile!.name,
      familyNotified: _familyNotified,
      victimName: _profile!.name,
      victimBloodGroup: _profile!.bloodGroup,
      victimMedical: _profile!.medicalConditions,
      victimEmergencyContactPhone: _profile!.emergencyContactPhone,
      isVictimFlow: false,
      noQrAvailable: false,
      areaName: locState.areaName,
    );

    // 5. Route to Emergency Control Center
    if (mounted) {
      context.go('/activation');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE53935);
    const darkCard = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "SCAN VICTIM'S QR",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_profile == null) ...[
                // Instruction banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kIsWeb
                              ? "Please upload a photo of the victim's emergency QR code. We will decode it automatically."
                              : "Align the victim's emergency QR code within the camera frame to scan and pull their profile.",
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Scanner display
                if (kIsWeb)
                  // Web layout file picker
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: darkCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_rounded, color: Colors.green, size: 48),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _uploadAndDecode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.06),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                  )
                                : const Text("Upload Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "PNG or JPEG files containing a valid QR",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Native Mobile camera scanner
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _mobileController,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty) {
                              final text = barcodes.first.rawValue;
                              if (text != null && text.isNotEmpty) {
                                _mobileController?.stop();
                                setState(() {
                                  _profile = VictimProfile.parse(text);
                                });
                              }
                            }
                          },
                        ),
                        // Scanner overlay grid
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryColor, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                // Profile found card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.account_circle_rounded, color: Colors.green, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "👤 VICTIM PROFILE FOUND",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _profileRow("Name", _profile!.name),
                      const Divider(color: Colors.white10, height: 24),
                      _profileRow("Blood Group", _profile!.bloodGroup),
                      const Divider(color: Colors.white10, height: 24),
                      _profileRow("Medical", _profile!.medicalConditions),
                      const Divider(color: Colors.white10, height: 24),
                      
                      const Text(
                        "Emergency Contact:",
                        style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Mom - ${_profile!.emergencyContactPhone}",
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),

                      // Notify family button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _triggerBystanderWhatsApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                          label: Text(
                            _familyNotified ? "FAMILY NOTIFIED ✓" : "NOTIFY FAMILY NOW",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Start flow button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startEmergencyFlow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            "START EMERGENCY FLOW",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
