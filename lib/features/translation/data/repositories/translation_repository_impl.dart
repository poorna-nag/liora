import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/storage/conversation_store.dart';
import '../../../chat/data/models/chat_message.dart';
import '../../../chat/data/models/chat_role.dart';
import '../../../history/data/models/conversation.dart';
import '../models/translation_result.dart';
import 'translation_repository.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final GeminiService _gemini;
  final ConversationStore _store;

  TranslationRepositoryImpl(this._gemini, this._store);

  @override
  Future<Conversation> start() =>
      _store.createConversation(kind: ConversationKind.translation);

  @override
  List<ChatMessage> loadMessages(String conversationId) =>
      _store.loadMessages(conversationId);

  @override
  Future<TranslationResult> translate({
    required String conversationId,
    required String sourceText,
    required String sourceLanguageName,
    required String targetLanguageName,
  }) async {
    try {
      await _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.user,
        content: sourceText,
      );

      final translated = await _gemini.generateOnce(
        systemPrompt:
            'You are a precise translation engine. Output ONLY the translated '
            'text with no quotes, notes, or explanations.',
        prompt: 'Translate the following text from $sourceLanguageName to '
            '$targetLanguageName:\n\n$sourceText',
      );

      await _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.assistant,
        content: translated,
      );

      return TranslationResult(
        sourceText: sourceText,
        translatedText: translated,
        sourceLanguageName: sourceLanguageName,
        targetLanguageName: targetLanguageName,
      );
    } on AppException catch (e) {
      throw e is ServerException
          ? ServerFailure(e.message)
          : UnknownFailure(e.message);
    } catch (e) {
      throw ServerFailure('Translation failed: $e');
    }
  }
}
