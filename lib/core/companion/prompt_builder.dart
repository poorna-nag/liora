import '../../features/character/data/models/companion_character.dart';
import 'emotion_engine.dart';
import 'language_engine.dart';
import 'memory_engine.dart';
import 'models/relationship_state.dart';
import 'personality_engine.dart';

/// The single place where the system prompt is assembled — "Prompt Builder" in
/// the pipeline. It layers, in order: persona (PersonalityEngine), memory
/// (MemoryEngine), output-language steering (LanguageEngine), and the emotion
/// protocol (EmotionEngine). No feature builds prompts itself anymore.
class PromptBuilder {
  final PersonalityEngine _personality;
  final MemoryEngine _memory;
  final LanguageEngine _language;

  PromptBuilder(this._personality, this._memory, this._language);

  String build({
    required CompanionCharacter companion,
    required RelationshipLevel level,
    String? languageCode,
    String? extraInstruction,
    bool includeMemory = true,
    bool includeEmotionProtocol = true,
  }) {
    final buffer = StringBuffer(_personality.buildPersona(companion, level));

    if (includeMemory) {
      final memory = _memory.buildContext();
      if (memory.isNotEmpty) buffer.write('\n\n$memory');
    }

    final languageInstruction = _language.instructionFor(languageCode);
    if (languageInstruction != null) buffer.write('\n\n$languageInstruction');

    if (extraInstruction != null && extraInstruction.isNotEmpty) {
      buffer.write('\n\n$extraInstruction');
    }

    if (includeEmotionProtocol) buffer.write('\n\n${EmotionEngine.protocol}');

    return buffer.toString();
  }
}
