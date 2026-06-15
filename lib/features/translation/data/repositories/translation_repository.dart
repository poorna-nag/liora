import '../../../chat/data/models/chat_message.dart';
import '../../../history/data/models/conversation.dart';
import '../models/translation_result.dart';

/// Translates text between languages and records each exchange.
abstract class TranslationRepository {
  Future<Conversation> start();
  List<ChatMessage> loadMessages(String conversationId);

  Future<TranslationResult> translate({
    required String conversationId,
    required String sourceText,
    required String sourceLanguageName,
    required String targetLanguageName,
  });
}
