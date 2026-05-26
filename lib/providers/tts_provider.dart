import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsProvider = Provider<TtsNotifier>((ref) {
  return TtsNotifier();
});

class TtsNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  TtsNotifier() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.45); // Calm and deliberate speech for emergency situations
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      // Ignore initialization errors on platforms without TTS engine support
    }
  }

  Future<void> setLanguage(String langCode) async {
    try {
      await _flutterTts.setLanguage(langCode);
      if (langCode == 'en-US') {
        await _flutterTts.setSpeechRate(0.45);
      } else {
        await _flutterTts.setSpeechRate(0.40); // Slightly slower for local languages to be clear
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      // Ignore speech errors
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      // Ignore stop errors
    }
  }
}
