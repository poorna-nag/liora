import '../../features/emotion/data/models/emotion.dart';

/// Detects the emotion a reply should be delivered with — step 6 of the
/// companion pipeline. Primary source is the structured tag the model returns
/// (see [protocol]); when absent/unrecognised it falls back to a keyword
/// heuristic so the avatar and voice always have an emotion to express.
class EmotionEngine {
  /// Instruction appended to the system prompt so the model returns a
  /// structured reply. Kept beside the parser so the protocol stays in sync.
  static const String protocol =
      'After deciding your reply, respond ONLY with a single-line JSON object, '
      'no markdown, in exactly this shape:\n'
      '{"emotion": "<one of: happy, excited, thinking, sad, concerned, '
      'laughing, confident, calm, surprised, neutral>", "message": "<your '
      'reply to the user>"}\n'
      'Pick the emotion that best matches the feeling of your message.';

  /// Resolves the final emotion from an optional model [emotionKey], falling
  /// back to keyword detection on [text], then to [fallback].
  Emotion resolve({
    String? emotionKey,
    required String text,
    Emotion fallback = Emotion.neutral,
  }) {
    if (emotionKey != null) {
      final normalized = emotionKey.trim().toLowerCase();
      for (final e in Emotion.values) {
        if (e.name == normalized) return e;
      }
    }
    return detectFromText(text, fallback: fallback);
  }

  /// Infers an emotion from [text] using simple keyword/punctuation cues.
  Emotion detectFromText(String text, {Emotion fallback = Emotion.neutral}) {
    final t = text.toLowerCase();
    bool has(List<String> words) => words.any(t.contains);

    if (has(['haha', 'lol', '😂', 'hilarious', 'so funny'])) {
      return Emotion.laughing;
    }
    if (has(['congrat', 'amazing', "let's go", 'awesome', 'fantastic', '🎉']) ||
        t.contains('!!')) {
      return Emotion.excited;
    }
    if (has(['sorry', 'unfortunately', 'sad', "that's tough", 'heartbreak'])) {
      return Emotion.sad;
    }
    if (has(['careful', 'worried', 'concern', 'be cautious', 'make sure'])) {
      return Emotion.concerned;
    }
    if (has(['let me think', 'hmm', 'interesting question', 'consider'])) {
      return Emotion.thinking;
    }
    if (has(['definitely', 'absolutely', 'trust me', "i'm sure", 'no doubt'])) {
      return Emotion.confident;
    }
    if (has(['wow', 'really?', 'no way', 'surprise', 'whoa'])) {
      return Emotion.surprised;
    }
    if (has(['happy', 'glad', 'great', 'wonderful', 'love that', '😊'])) {
      return Emotion.happy;
    }
    if (has(['relax', 'take your time', "it's okay", 'breathe', 'calm'])) {
      return Emotion.calm;
    }
    return fallback;
  }
}
