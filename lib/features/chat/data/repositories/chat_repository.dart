import '../../../history/data/models/conversation.dart';
import '../models/chat_message.dart';

/// Drives a text conversation with the assistant and persists it locally.
abstract class ChatRepository {
  /// Creates a new conversation of the given [kind].
  Future<Conversation> startConversation({
    ConversationKind kind = ConversationKind.chat,
    String? title,
  });

  /// Loads the persisted messages for [conversationId].
  List<ChatMessage> loadMessages(String conversationId);

  /// Sends [text] in [conversationId], persisting both the user message and the
  /// AI reply, and returns the assistant's reply message.
  ///
  /// [languageInstruction] optionally forces the reply language (used by the
  /// multilingual feature).
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
    String? languageInstruction,
  });
}
