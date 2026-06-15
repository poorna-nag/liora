import '../../../chat/data/models/chat_message.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../history/data/models/conversation.dart';
import '../models/language_option.dart';
import 'multilingual_repository.dart';

class MultilingualRepositoryImpl implements MultilingualRepository {
  final ChatRepository _chat;

  MultilingualRepositoryImpl(this._chat);

  @override
  List<LanguageOption> supportedLanguages() => LanguageOption.supported;

  @override
  Future<Conversation> start() =>
      _chat.startConversation(kind: ConversationKind.multilingual);

  @override
  List<ChatMessage> loadMessages(String conversationId) =>
      _chat.loadMessages(conversationId);

  @override
  Future<ChatMessage> send({
    required String conversationId,
    required String text,
    required String languageName,
  }) {
    return _chat.sendMessage(
      conversationId: conversationId,
      text: text,
      languageInstruction:
          'Always respond in $languageName, regardless of the input language.',
    );
  }
}
