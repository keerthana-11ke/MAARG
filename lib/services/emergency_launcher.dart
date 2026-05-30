import 'package:url_launcher/url_launcher.dart';

class EmergencyLauncher {
  static final EmergencyLauncher instance = EmergencyLauncher._internal();
  EmergencyLauncher._internal();

  /// Launches WhatsApp with an encoded message.
  /// Returns true if successful, false otherwise.
  Future<bool> launchWhatsApp({required String phoneNumber, required String message}) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.isEmpty) {
        print("[EmergencyLauncher] WhatsApp target phone number is empty.");
        return false;
      }
      
      // Proper URL encoding of the message
      final encodedMessage = Uri.encodeComponent(message);
      
      // Standard WhatsApp deep link format
      final urlString = "https://wa.me/$cleanPhone?text=$encodedMessage";
      final uri = Uri.parse(urlString);

      print("[EmergencyLauncher] Attempting WhatsApp deep-link: $urlString");

      // On Android, we should launch in external application mode
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (success) {
          print("[EmergencyLauncher] WhatsApp launched successfully.");
          return true;
        }
      }
      
      // Fallback: try launching with the universal web API link
      print("[EmergencyLauncher] Deep-link failed, trying WhatsApp API web fallback...");
      final webUrlString = "https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMessage";
      final webUri = Uri.parse(webUrlString);
      if (await canLaunchUrl(webUri)) {
        final success = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (success) {
          print("[EmergencyLauncher] WhatsApp web fallback launched successfully.");
          return true;
        }
      }
      
      print("[EmergencyLauncher] WhatsApp could not be launched on this device.");
      return false;
    } catch (e) {
      print("[EmergencyLauncher] Exception during WhatsApp launch: $e");
      return false;
    }
  }

  /// Launches SMS with an encoded body.
  /// Returns true if successful, false otherwise.
  Future<bool> launchSms({required String phoneNumber, required String message}) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.isEmpty) {
        print("[EmergencyLauncher] SMS target phone number is empty.");
        return false;
      }
      
      final encodedMessage = Uri.encodeComponent(message);
      final urlString = "sms:$cleanPhone?body=$encodedMessage";
      final uri = Uri.parse(urlString);

      print("[EmergencyLauncher] Attempting SMS: $urlString");

      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(uri);
        if (success) {
          print("[EmergencyLauncher] SMS opened successfully.");
          return true;
        }
      }
      print("[EmergencyLauncher] SMS could not be launched on this device.");
      return false;
    } catch (e) {
      print("[EmergencyLauncher] Exception during SMS launch: $e");
      return false;
    }
  }

  /// Opens the system dialer with "tel:108"
  /// Returns true if successful, false otherwise.
  Future<bool> makeEmergencyCall() async {
    try {
      final dialerUri = Uri.parse('tel:108');
      print("[EmergencyLauncher] Attempting to open dialer with: tel:108");
      
      if (await canLaunchUrl(dialerUri)) {
        final success = await launchUrl(dialerUri);
        if (success) {
          print("[EmergencyLauncher] Dialer opened successfully.");
          return true;
        }
      }
      print("[EmergencyLauncher] Could not launch dialer.");
      return false;
    } catch (e) {
      print("[EmergencyLauncher] Exception during dialer launch: $e");
      return false;
    }
  }
}
