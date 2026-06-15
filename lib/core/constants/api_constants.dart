/// Gemini model identifiers used via Firebase AI Logic.
class ApiConstants {
  ApiConstants._();

  /// General text + multimodal chat model.
  static const String chatModel = 'gemini-2.5-flash';

  /// Vision-capable model (multimodal). Same family handles images.
  static const String visionModel = 'gemini-2.5-flash';

  /// Default generation parameters.
  static const double defaultTemperature = 0.8;
  static const int defaultMaxOutputTokens = 2048;
}
