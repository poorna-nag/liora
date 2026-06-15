import '../../../chat/data/models/chat_message.dart';
import '../../../history/data/models/conversation.dart';
import '../models/language_option.dart';

/// Multilingual chat: the assistant replies in the user's chosen language.
abstract class MultilingualRepository {
  List<LanguageOption> supportedLanguages();
  Future<Conversation> start();
  List<ChatMessage> loadMessages(String conversationId);
  Future<ChatMessage> send({
    required String conversationId,
    required String text,
    required String languageName,
  });
}
