import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/memory_service.dart';
import '../../../../core/storage/conversation_store.dart';
import '../../../character/data/repositories/character_repository.dart';
import '../../../emotion/data/services/emotion_engine.dart';
import '../../../history/data/models/conversation.dart';
import '../../../personality/data/repositories/personality_repository.dart';
import '../../../settings/data/repositories/settings_repository.dart';
import '../models/chat_message.dart';
import '../models/chat_role.dart';
import 'chat_repository.dart';

/// Composes the AI service, conversation storage, memory and the active
/// companion character into a living chat flow: the reply carries an emotion
/// the avatar and voice can express. Throws [Failure]s for the BLoC.
class ChatRepositoryImpl implements ChatRepository {
  final GeminiService _gemini;
  final ConversationStore _store;
  final MemoryService _memory;
  final PersonalityRepository _personality;
  final SettingsRepository _settings;
  final CharacterRepository _character;
  final EmotionEngine _emotionEngine;

  ChatRepositoryImpl(
    this._gemini,
    this._store,
    this._memory,
    this._personality,
    this._settings,
    this._character,
    this._emotionEngine,
  );

  @override
  Future<Conversation> startConversation({
    ConversationKind kind = ConversationKind.chat,
    String? title,
  }) {
    return _store.createConversation(kind: kind, title: title);
  }

  @override
  List<ChatMessage> loadMessages(String conversationId) =>
      _store.loadMessages(conversationId);

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
    String? languageInstruction,
  }) async {
    try {
      // Prior turns become model context (before persisting the new message).
      final history = _store
          .loadMessages(conversationId)
          .where((m) => m.role != ChatRole.system)
          .map((m) => AiTurn(isUser: m.isUser, text: m.content))
          .toList();

      await _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.user,
        content: text,
      );

      final character = _character.getActiveOrDefault();
      final reply = await _gemini.generateStructuredReply(
        systemPrompt: _buildSystemPrompt(character.personaPrompt,
            languageInstruction: languageInstruction),
        history: history,
        userMessage: text,
      );

      final emotion = _emotionEngine.resolve(
        emotionKey: reply.emotionKey,
        text: reply.text,
        fallback: character.defaultEmotion,
      );

      return _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.assistant,
        content: reply.text,
        emotion: emotion,
      );
    } on AppException catch (e) {
      throw _mapFailure(e);
    } catch (e) {
      throw ServerFailure('Something went wrong: $e');
    }
  }

  /// Builds the system prompt: the active companion's persona drives behaviour,
  /// followed by memory, the optional language instruction, and the emotion
  /// protocol that makes the model return a structured emotional reply.
  String _buildSystemPrompt(
    String personaPrompt, {
    String? languageInstruction,
  }) {
    final settings = _settings.load();
    final buffer = StringBuffer(personaPrompt);

    // Personality preset layered in as an extra style cue (kept from V1).
    final personality =
        _personality.getActiveOrDefault(settings.activePersonalityId);
    if (!personality.isBuiltIn) {
      buffer.write('\n\n${personality.systemPrompt}');
    }

    if (settings.memoryEnabled) {
      final memory = _memory.buildMemoryContext();
      if (memory.isNotEmpty) buffer.write('\n\n$memory');
    }
    if (languageInstruction != null) {
      buffer.write('\n\n$languageInstruction');
    }
    buffer.write('\n\n${EmotionEngine.protocol}');
    return buffer.toString();
  }

  Failure _mapFailure(AppException e) {
    if (e is ServerException) return ServerFailure(e.message);
    if (e is CacheException) return CacheFailure(e.message);
    return UnknownFailure(e.message);
  }
}
