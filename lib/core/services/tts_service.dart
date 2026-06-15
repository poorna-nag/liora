import 'package:flutter_tts/flutter_tts.dart';

/// Wraps `flutter_tts` for speaking AI responses aloud.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }

  Future<void> speak(
    String text, {
    String languageCode = 'en-US',
    double rate = 0.5,
  }) async {
    await _configure();
    await _tts.setLanguage(languageCode);
    await _tts.setSpeechRate(rate);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  Future<List<String>> languages() async {
    final result = await _tts.getLanguages;
    return (result as List).map((e) => e.toString()).toList();
  }
}
