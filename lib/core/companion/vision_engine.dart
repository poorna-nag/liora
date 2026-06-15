import 'dart:typed_data';

import '../services/gemini_service.dart';

/// Performs multimodal (image) understanding for the companion — the "Vision
/// Engine" step. It only handles the Gemini Vision call; the [CompanionManager]
/// supplies the persona-aware system prompt and post-processes the result, so
/// camera analysis speaks with the selected companion's personality.
class VisionEngine {
  final GeminiService _gemini;

  VisionEngine(this._gemini);

  Future<String> describe({
    required Uint8List imageBytes,
    required String instruction,
    required String systemPrompt,
    String mimeType = 'image/jpeg',
  }) {
    return _gemini.analyzeImage(
      imageBytes: imageBytes,
      prompt: instruction,
      systemPrompt: systemPrompt,
      mimeType: mimeType,
    );
  }
}
