import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final geminiProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  // Read key defined via --dart-define=GEMINI_API_KEY=xxx
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Read base URL defined via --dart-define=GEMINI_BASE_URL=xxx
  static const String baseUrl = String.fromEnvironment('GEMINI_BASE_URL', 
    defaultValue: 'https://generativelanguage.googleapis.com');

  bool get isKeyConfigured => _apiKey.isNotEmpty;

  Future<String> analyzeInjury(String description) async {
    if (_apiKey.isEmpty) {
      return "Gemini API key is not configured. Please build the application with "
          "--dart-define=GEMINI_API_KEY=YOUR_KEY parameter.";
    }

    final prompt = "You are an emergency first aid assistant.\n"
        "Based on this injury description: $description\n"
        "Provide:\n"
        "1) Likely injury type\n"
        "2) Immediate first aid steps\n"
        "3) Movements to AVOID\n"
        "Be calm, clear and under 5 sentences.";

    try {
      final isGoogle = baseUrl.contains('generativelanguage.googleapis.com');

      if (isGoogle) {
        // Use standard Google Gemini API structure
        final url = Uri.parse('$baseUrl/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          return text ?? "No assessment could be generated. Please try again.";
        } else {
          return "Google API error (Status ${response.statusCode}): ${response.body}";
        }
      } else {
        // Use OpenAI-compatible custom base URL (e.g. Featherless.ai)
        String targetUrl = baseUrl;
        if (!targetUrl.endsWith('/chat/completions')) {
          if (targetUrl.endsWith('/')) {
            targetUrl = '${targetUrl}chat/completions';
          } else {
            targetUrl = '$targetUrl/chat/completions';
          }
        }

        final url = Uri.parse(targetUrl);
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': 'deepseek-ai/DeepSeek-V4-Pro',
            'messages': [
              {
                'role': 'user',
                'content': prompt,
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices']?[0]?['message']?['content'] as String?;
          return text ?? "No assessment could be generated. Please try again.";
        } else {
          return "Custom API error (Status ${response.statusCode}): ${response.body}";
        }
      }
    } catch (e) {
      return "Error during AI analysis: $e\n\nPlease ensure your device is connected to the internet and the API key is valid.";
    }
  }
}
