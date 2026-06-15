import 'dart:typed_data';

import '../../features/character/data/models/companion_character.dart';
import '../../features/character/data/repositories/character_repository.dart';
import '../services/gemini_service.dart';
import 'animation_engine.dart';
import 'emotion_engine.dart';
import 'language_engine.dart';
import 'models/companion_response.dart';
import 'prompt_builder.dart';
import 'relationship_engine.dart';
import 'speech_engine.dart';
import 'vision_engine.dart';

/// The central brain of the application. Every feature — chat, voice, camera,
/// translation and any future surface — sends its request here. Nothing calls
/// Gemini directly anymore.
///
/// Pipeline (per the spec):
///   request → memory + personality (PromptBuilder) → Gemini → emotion →
///   relationship → animation → (speech) → CompanionResponse
class CompanionManager {
  final GeminiService _gemini;
  final CharacterRepository _characters;
  final PromptBuilder _promptBuilder;
  final EmotionEngine _emotion;
  final RelationshipEngine _relationship;
  final AnimationEngine _animation;
  final VisionEngine _vision;
  final SpeechEngine _speech;
  final LanguageEngine _language;

  CompanionManager(
    this._gemini,
    this._characters,
    this._promptBuilder,
    this._emotion,
    this._relationship,
    this._animation,
    this._vision,
    this._speech,
    this._language,
  );

  /// The companion currently powering the app.
  CompanionCharacter get activeCompanion => _characters.getActiveOrDefault();

  /// Switch output language at runtime without restarting conversations.
  void setLanguage(String? code) => _language.setLanguage(code);

  // --- Speech passthrough (interruption / pause / resume) ------------------
  Future<void> stopSpeaking() => _speech.stop();
  Future<void> pauseSpeaking() => _speech.pause();
  Future<void> resumeSpeaking() => _speech.resume();

  /// Core text pipeline used by chat, voice and translation.
  Future<CompanionResponse> respond({
    required String userText,
    List<AiTurn> history = const [],
    String? languageCode,
    String? extraInstruction,
    bool speak = false,
  }) async {
    final companion = activeCompanion;
    final levelBefore = _relationship.levelFor(companion.id);

    final systemPrompt = _promptBuilder.build(
      companion: companion,
      level: levelBefore,
      languageCode: languageCode,
      extraInstruction: extraInstruction,
    );

    final reply = await _gemini.generateStructuredReply(
      systemPrompt: systemPrompt,
      history: history,
      userMessage: userText,
    );

    final emotion = _emotion.resolve(
      emotionKey: reply.emotionKey,
      text: reply.text,
      fallback: companion.defaultEmotion,
    );

    final state = await _relationship.registerInteraction(companion.id);

    final response = CompanionResponse(
      text: reply.text,
      emotion: emotion,
      activity: _animation.activityForReply(emotion, spoken: speak),
      companion: companion,
      relationshipLevel: state.level,
    );

    if (speak) await _speech.speak(response);
    return response;
  }

  /// Translation pipeline. Translation must be literal, so it deliberately
  /// bypasses persona/emotion — but it still runs through the manager so that
  /// nothing in the app calls Gemini directly.
  Future<String> translate({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) {
    return _gemini.generateOnce(
      systemPrompt:
          'You are a precise translation engine. Output ONLY the translated '
          'text with no quotes, notes, or explanations.',
      prompt: 'Translate the following text from $fromLanguage to '
          '$toLanguage:\n\n$text',
    );
  }

  /// Vision pipeline: describe an image through the companion's personality.
  Future<CompanionResponse> respondToImage({
    required Uint8List imageBytes,
    required String instruction,
    String mimeType = 'image/jpeg',
    String? languageCode,
    bool speak = false,
  }) async {
    final companion = activeCompanion;
    final levelBefore = _relationship.levelFor(companion.id);

    // Vision returns prose (not the structured JSON), so skip the emotion
    // protocol and infer emotion from the description instead.
    final systemPrompt = _promptBuilder.build(
      companion: companion,
      level: levelBefore,
      languageCode: languageCode,
      includeEmotionProtocol: false,
    );

    final description = await _vision.describe(
      imageBytes: imageBytes,
      instruction: instruction,
      systemPrompt: systemPrompt,
      mimeType: mimeType,
    );

    final emotion = _emotion.detectFromText(
      description,
      fallback: companion.defaultEmotion,
    );

    final state = await _relationship.registerInteraction(companion.id);

    final response = CompanionResponse(
      text: description,
      emotion: emotion,
      activity: _animation.activityForReply(emotion, spoken: speak),
      companion: companion,
      relationshipLevel: state.level,
    );

    if (speak) await _speech.speak(response);
    return response;
  }
}
