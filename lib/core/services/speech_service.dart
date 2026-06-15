import 'package:speech_to_text/speech_to_text.dart';

import '../error/exceptions.dart';

/// Wraps `speech_to_text` for one-shot speech recognition.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _initialized;
  }

  /// Starts listening; [onResult] is called with interim + final transcripts.
  /// [onFinal] fires once with the final transcript when recognition stops.
  Future<void> listen({
    required String localeId,
    required void Function(String transcript, bool isFinal) onResult,
  }) async {
    if (!await init()) {
      throw const DeviceException('Speech recognition is unavailable.');
    }
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();

  Future<List<LocaleName>> locales() => _speech.locales();
}
