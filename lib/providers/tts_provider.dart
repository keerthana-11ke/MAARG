import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tts_stub_helper.dart'
    if (dart.library.js) 'tts_web_helper.dart' as web_helper;

class TtsMuteNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

final ttsMuteProvider = NotifierProvider<TtsMuteNotifier, bool>(TtsMuteNotifier.new);

final ttsProvider = Provider<TtsNotifier>((ref) {
  return TtsNotifier(ref);
});

class TtsNotifier {
  final Ref _ref;
  final FlutterTts _flutterTts = FlutterTts();
  String _currentLang = 'en-US';

  TtsNotifier(this._ref) {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      // Ignore initialization errors
    }
  }

  Future<void> setLanguage(String langCode) async {
    _currentLang = langCode;
    try {
      await _flutterTts.setLanguage(langCode);
      if (langCode == 'en-US') {
        await _flutterTts.setSpeechRate(0.45);
      } else {
        await _flutterTts.setSpeechRate(0.40);
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> speak(String text) async {
    final isMuted = _ref.read(ttsMuteProvider);
    if (isMuted || text.isEmpty) return;

    if (kIsWeb) {
      try {
        web_helper.webSpeak(text, _currentLang);
      } catch (e) {
        print("Web speechSynthesis failed, using fallback: $e");
        _speakFallback(text);
      }
    } else {
      _speakFallback(text);
    }
  }

  Future<void> _speakFallback(String text) async {
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      print("Fallback TTS failed: $e");
    }
  }

  Future<void> stop() async {
    if (kIsWeb) {
      try {
        web_helper.webStop();
      } catch (_) {}
    }
    try {
      await _flutterTts.stop();
    } catch (e) {
      // Ignore
    }
  }

  Future<void> toggleMute() async {
    _ref.read(ttsMuteProvider.notifier).toggle();
    final isMuted = _ref.read(ttsMuteProvider);
    if (isMuted) {
      await stop();
    }
  }
}
