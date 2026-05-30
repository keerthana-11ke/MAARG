import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../providers/shake_sos_provider.dart';

class EmergencyProfileScreen extends ConsumerStatefulWidget {
  const EmergencyProfileScreen({super.key});

  @override
  ConsumerState<EmergencyProfileScreen> createState() => _EmergencyProfileScreenState();
}

class _EmergencyProfileScreenState extends ConsumerState<EmergencyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _allergiesController = TextEditingController();

  String _selectedBloodGroup = 'A+';
  bool _isSaved = false;
  String _qrData = '';
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _downloadQrCode() async {
    bool hasPermission = false;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // On Android 13+ (SDK 33+), saves directly to gallery WITHOUT needing storage permission.
        hasPermission = true;
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        hasPermission = status.isGranted;
      }
    } else {
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
      hasPermission = status.isGranted;
    }

    if (!hasPermission) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Permission Required"),
            content: const Text(
              "Storage permission is required to save the QR code image to your gallery.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text("Settings"),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: "emergency_qr",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("QR saved to your gallery!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save QR code: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? '';
      _selectedBloodGroup = prefs.getString('profile_blood') ?? 'A+';
      _contactNameController.text = prefs.getString('profile_contact_name') ?? '';
      _contactPhoneController.text = prefs.getString('profile_contact_phone') ?? '';
      _conditionsController.text = prefs.getString('profile_conditions') ?? '';
      _allergiesController.text = prefs.getString('profile_allergies') ?? '';
      
      if (_nameController.text.isNotEmpty && _contactPhoneController.text.isNotEmpty) {
        _isSaved = true;
        _generateQrData();
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text.trim());
    await prefs.setString('profile_blood', _selectedBloodGroup);
    await prefs.setString('profile_contact_name', _contactNameController.text.trim());
    await prefs.setString('profile_contact_phone', _contactPhoneController.text.trim());
    await prefs.setString('profile_conditions', _conditionsController.text.trim());
    await prefs.setString('profile_allergies', _allergiesController.text.trim());

    setState(() {
      _isSaved = true;
      _generateQrData();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency Profile Saved Successfully ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _generateQrData() {
    final name = _nameController.text.trim();
    final blood = _selectedBloodGroup;
    final phone = _contactPhoneController.text.trim();
    final conditions = _conditionsController.text.trim();
    
    // Construct QR payload with details and deep link
    _qrData = "Victim Name: $name\n"
        "Blood Group: $blood\n"
        "Emergency Contact: $phone\n"
        "Conditions: ${conditions.isEmpty ? 'None' : conditions}\n"
        "Deep Link: https://maarg.app/emergency?name=${Uri.encodeComponent(name)}&contact=${Uri.encodeComponent(phone)}&blood=${Uri.encodeComponent(blood)}";
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
        title: const Text(
          'Emergency Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'PERSONAL & EMERGENCY DETAILS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Full Name', Icons.person_rounded),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Blood Group Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedBloodGroup,
                        dropdownColor: darkCard,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: _inputDecoration('Blood Group', Icons.opacity_rounded),
                        items: _bloodGroups.map((group) {
                          return DropdownMenuItem(
                            value: group,
                            child: Text(group, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedBloodGroup = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contact Name
                      TextFormField(
                        controller: _contactNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Emergency Contact Name', Icons.contacts_rounded),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Contact name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Contact Phone Number
                      TextFormField(
                        controller: _contactPhoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Emergency Contact Phone', Icons.phone_rounded),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Contact phone is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Medical Conditions
                      TextFormField(
                        controller: _conditionsController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Medical Conditions (Optional)', Icons.healing_rounded),
                      ),
                      const SizedBox(height: 16),

                      // Allergies
                      TextFormField(
                        controller: _allergiesController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Allergies (Optional)', Icons.warning_amber_rounded),
                      ),
                      const SizedBox(height: 16),



                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'SAVE & GENERATE QR',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isSaved && _qrData.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR EMERGENCY QR CODE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // QR Code image
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Print and stick on your helmet, bike and wallet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This QR helps bystanders notify your family instantly',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _downloadQrCode,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download QR'),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.white30),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}

// Helper wrapper to support ImageGallerySaver class calls dynamically and safely using image_gallery_saver_plus.
class ImageGallerySaver {
  static Future<dynamic> saveImage(Uint8List imageBytes, {int quality = 80, String? name}) async {
    return ImageGallerySaverPlus.saveImage(imageBytes, quality: quality, name: name);
  }
}
