import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'location_service.dart';
import 'emergency_launcher.dart';

class SOSService {
  static final SOSService instance = SOSService._internal();
  SOSService._internal();

  bool _isSosExecuting = false;

  /// Returns true if an SOS workflow is currently executing or debouncing.
  bool get isSosExecuting => _isSosExecuting;

  /// Coordinates the emergency alert sequence:
  /// 1. Fetches current location coordinates.
  /// 2. Performs reverse geocoding to find the area name.
  /// 3. Reads emergency contact details.
  /// 4. Sends a WhatsApp alert.
  /// 5. Automatically launches the emergency phone dialer to call 108.
  Future<void> sendEmergencySOS({
    required double defaultLat,
    required double defaultLng,
    required String defaultArea,
    required void Function(String info) onStatusUpdate,
    required void Function(String error) onError,
    required void Function() onSuccess,
  }) async {
    if (_isSosExecuting) {
      print("[SOSService] SOS trigger blocked: already executing.");
      return;
    }
    _isSosExecuting = true;
    onStatusUpdate("SOS Alert Process Initialized...");

    try {
      // 1. Fetch Location Coordinates via LocationService
      double latitude = defaultLat;
      double longitude = defaultLng;
      String areaName = defaultArea;

      onStatusUpdate("Acquiring GPS location...");
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
        onStatusUpdate("GPS Coordinates secured: $latitude, $longitude");
        
        // Reverse Geocode
        onStatusUpdate("Identifying address details...");
        areaName = await LocationService.instance.reverseGeocode(latitude, longitude);
      } else {
        print("[SOSService] Geolocator failed or permission denied, using default/cached coordinates.");
        onStatusUpdate("GPS unavailable. Relying on default locations.");
      }

      // 2. Format Timestamp
      final now = DateTime.now().toLocal();
      final timestamp = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      // 3. Build WhatsApp Alert Message Payload
      final message = "🆘 SOS ALERT from MAARG\n"
          "I need emergency medical assistance immediately.\n"
          "Last known location coordinates:\n"
          "https://maps.google.com/?q=$latitude,$longitude\n"
          "Estimated Area: $areaName\n"
          "Time of Alert: $timestamp\n"
          "- Sent via MAARG Emergency Assistant";

      // 4. Retrieve saved emergency contacts from cache
      onStatusUpdate("Fetching emergency contacts...");
      final prefs = await SharedPreferences.getInstance();
      final contactPhone = prefs.getString('profile_contact_phone') ?? '';

      if (contactPhone.isNotEmpty) {
        onStatusUpdate("Sending direct SOS SMS...");
        try {
          await sendSMS(
            message: message,
            recipients: [contactPhone],
            sendDirect: true,
          );
          onStatusUpdate("SOS SMS Sent ✅");
        } catch (e) {
          print("[SOSService] Direct SMS failed: $e. Launching standard SMS...");
          onStatusUpdate("Direct SMS failed. Trying standard SMS...");
          await EmergencyLauncher.instance.launchSms(
            phoneNumber: contactPhone,
            message: message,
          );
        }

        // Delay slightly before launching WhatsApp so they don't overlap
        await Future.delayed(const Duration(milliseconds: 1500));

        onStatusUpdate("Opening WhatsApp backup alert...");
        final whatsappOpened = await EmergencyLauncher.instance.launchWhatsApp(
          phoneNumber: contactPhone,
          message: message,
        );
        if (whatsappOpened) {
          onStatusUpdate("WhatsApp opened");
        } else {
          onStatusUpdate("WhatsApp backup failed.");
        }
      } else {
        print("[SOSService] No emergency contact phone number configured in profile settings.");
        onError("No emergency contact configured. Emergency call (108) will proceed.");
      }

      // 5. Open Dialer for emergency line 108
      onStatusUpdate("Opening emergency line 108 dialer...");
      final dialerSuccess = await EmergencyLauncher.instance.makeEmergencyCall();
      if (!dialerSuccess) {
        onError("Emergency call failed to launch dialer. Please dial 108 manually.");
      }

      onSuccess();
    } catch (e) {
      print("[SOSService] Unexpected error occurred during SOS sequence: $e");
      onError("SOS Execution Error: $e");
    } finally {
      // Keep executing status active for 5 seconds to act as debounce, then reset
      Future.delayed(const Duration(seconds: 5), () {
        _isSosExecuting = false;
        print("[SOSService] Execution lock released. Ready for next triggers.");
      });
    }
  }
}
