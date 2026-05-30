import 'package:flutter/services.dart';

Future<String> sendSMS({
  required String message,
  required List<String> recipients,
  bool sendDirect = false,
}) async {
  const channel = MethodChannel('com.maarg.maarg/sms');
  try {
    final String result = await channel.invokeMethod('sendSMS', {
      'message': message,
      'recipients': recipients,
      'sendDirect': sendDirect,
    });
    return result;
  } catch (e) {
    throw 'Failed to send SMS: $e';
  }
}
