import '../../../chat/data/models/chat_message.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../history/data/models/conversation.dart';
import 'voice_conversation_repository.dart';

/// Reuses [ChatRepository] for the AI + persistence flow, tagging the
/// conversation as [ConversationKind.voice].
class VoiceConversationRepositoryImpl implements VoiceConversationRepository {
  final ChatRepository _chat;

  VoiceConversationRepositoryImpl(this._chat);

  @override
  Future<Conversation> start() =>
      _chat.startConversation(kind: ConversationKind.voice);

  @override
  List<ChatMessage> loadMessages(String conversationId) =>
      _chat.loadMessages(conversationId);

  @override
  Future<ChatMessage> send({
    required String conversationId,
    required String text,
  }) =>
      _chat.sendMessage(conversationId: conversationId, text: text);
}
