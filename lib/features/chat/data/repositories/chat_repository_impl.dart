import '../../../../core/companion/companion_manager.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/storage/conversation_store.dart';
import '../../../history/data/models/conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_role.dart';
import 'chat_repository.dart';

/// Thin chat data layer: it persists the conversation and delegates ALL AI work
/// to the [CompanionManager]. The reply carries the companion's emotion, which
/// is stored on the assistant message for the avatar/voice. Throws [Failure]s.
class ChatRepositoryImpl implements ChatRepository {
  final ConversationStore _store;
  final CompanionManager _companion;

  ChatRepositoryImpl(this._store, this._companion);

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

      final response = await _companion.respond(
        userText: text,
        history: history,
        extraInstruction: languageInstruction,
      );

      return _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.assistant,
        content: response.text,
        emotion: response.emotion,
      );
    } on AppException catch (e) {
      throw _mapFailure(e);
    } catch (e) {
      throw ServerFailure('Something went wrong: $e');
    }
  }

  Failure _mapFailure(AppException e) {
    if (e is ServerException) return ServerFailure(e.message);
    if (e is CacheException) return CacheFailure(e.message);
    return UnknownFailure(e.message);
  }
}
