import 'package:flutter_tts/flutter_tts.dart';

/// Low-level wrapper around `flutter_tts`. Adds pitch, pause/resume and voice
/// selection on top of basic speaking. The [SpeechEngine] sits above this and
/// applies companion voice profiles + emotion prosody.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  /// Remembered so [resume] can continue after a [pause] on platforms where
  /// flutter_tts pause is not natively resumable.
  String? _lastText;
  String _lastLanguage = 'en-US';
  double _lastRate = 0.5;
  double _lastPitch = 1.0;

  Future<void> _configure() async {
    if (_configured) return;
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }

  Future<void> speak(
    String text, {
    String languageCode = 'en-US',
    double rate = 0.5,
    double pitch = 1.0,
    String? voiceName,
  }) async {
    await _configure();
    _lastText = text;
    _lastLanguage = languageCode;
    _lastRate = rate;
    _lastPitch = pitch;

    await _tts.setLanguage(languageCode);
    await _tts.setSpeechRate(rate.clamp(0.1, 1.0));
    await _tts.setPitch(pitch.clamp(0.5, 2.0));
    if (voiceName != null) {
      await _tts.setVoice({'name': voiceName, 'locale': languageCode});
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Interrupts any current speech.
  Future<void> stop() => _tts.stop();

  /// Pauses speech (platform support varies; falls back to stop).
  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (_) {
      await _tts.stop();
    }
  }

  /// Resumes by re-speaking the last utterance (flutter_tts has no universal
  /// resume), which is the most reliable cross-platform behaviour.
  Future<void> resume() async {
    if (_lastText == null) return;
    await speak(
      _lastText!,
      languageCode: _lastLanguage,
      rate: _lastRate,
      pitch: _lastPitch,
    );
  }

  void onComplete(void Function() handler) =>
      _tts.setCompletionHandler(handler);

  void onStart(void Function() handler) => _tts.setStartHandler(handler);

  Future<List<String>> languages() async {
    final result = await _tts.getLanguages;
    return (result as List).map((e) => e.toString()).toList();
  }

  Future<List<dynamic>> voices() async {
    final result = await _tts.getVoices;
    return (result as List?) ?? const [];
  }
}
