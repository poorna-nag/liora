import '../../features/emotion/data/models/emotion.dart';
import '../services/tts_service.dart';
import 'models/companion_response.dart';

/// Speaks the companion's responses — the "Speech Engine" step. It maps the
/// active companion's voice profile + the reply's emotion onto the low-level
/// [TtsService], and supports interruption, pause and resume.
class SpeechEngine {
  final TtsService _tts;

  SpeechEngine(this._tts);

  /// Speaks a [CompanionResponse] in the companion's voice, nudged by the
  /// emotion's prosody. [intensity] (0..1, from settings) scales how strongly
  /// emotion bends pitch/rate.
  Future<void> speak(CompanionResponse response, {double intensity = 1.0}) {
    final c = response.companion;
    final e = response.emotion;
    final pitch = (c.voicePitch + e.pitchDelta * intensity).clamp(0.5, 2.0);
    final rate = (c.voiceRate + e.rateDelta * intensity).clamp(0.1, 1.0);
    return _tts.speak(
      response.text,
      languageCode: c.voiceLocale,
      rate: rate,
      pitch: pitch,
    );
  }

  /// Speaks arbitrary [text] (e.g. a greeting) in the given voice profile.
  Future<void> speakText(
    String text, {
    String languageCode = 'en-US',
    double rate = 0.5,
    double pitch = 1.0,
  }) =>
      _tts.speak(text, languageCode: languageCode, rate: rate, pitch: pitch);

  Future<void> stop() => _tts.stop();
  Future<void> pause() => _tts.pause();
  Future<void> resume() => _tts.resume();

  void onComplete(void Function() handler) => _tts.onComplete(handler);
}
