import '../../../../core/companion/companion_manager.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/conversation_store.dart';
import '../../../chat/data/models/chat_message.dart';
import '../../../chat/data/models/chat_role.dart';
import '../../../history/data/models/conversation.dart';
import '../models/translation_result.dart';
import 'translation_repository.dart';

/// Translation routes through the [CompanionManager] (so nothing calls Gemini
/// directly), using its literal-translation path that bypasses persona/emotion.
class TranslationRepositoryImpl implements TranslationRepository {
  final CompanionManager _companion;
  final ConversationStore _store;

  TranslationRepositoryImpl(this._companion, this._store);

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

      final translated = await _companion.translate(
        text: sourceText,
        fromLanguage: sourceLanguageName,
        toLanguage: targetLanguageName,
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
