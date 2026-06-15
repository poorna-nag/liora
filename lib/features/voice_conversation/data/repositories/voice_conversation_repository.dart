import '../../../chat/data/models/chat_message.dart';
import '../../../history/data/models/conversation.dart';

/// Drives a spoken conversation: persists turns and gets AI replies. The
/// speech-to-text and text-to-speech orchestration lives in the bloc; this
/// repository owns the AI + persistence concern (reusing the chat pipeline).
abstract class VoiceConversationRepository {
  Future<Conversation> start();
  List<ChatMessage> loadMessages(String conversationId);
  Future<ChatMessage> send({
    required String conversationId,
    required String text,
  });
}
