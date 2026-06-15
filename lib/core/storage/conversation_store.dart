import 'package:uuid/uuid.dart';

import '../../features/chat/data/models/chat_message.dart';
import '../../features/chat/data/models/chat_role.dart';
import '../../features/emotion/data/models/emotion.dart';
import '../../features/history/data/models/conversation.dart';
import '../constants/app_constants.dart';
import '../session/session_manager.dart';
import 'local_storage_service.dart';

/// Shared persistence for conversations and their messages, scoped by the
/// current user. Used by every conversational feature (chat, voice, vision,
/// multilingual, translation) and read by the history feature, so the key
/// conventions and migration scoping live in exactly one place.
class ConversationStore {
  final LocalStorageService _storage;
  final SessionManager _session;
  final _uuid = const Uuid();

  ConversationStore(this._storage, this._session);

  String get _userPrefix =>
      '${_session.current.userId}${AppConstants.keySeparator}';

  String _convKey(String conversationId) => '$_userPrefix$conversationId';

  String _msgPrefix(String conversationId) =>
      '$_userPrefix$conversationId${AppConstants.keySeparator}';

  String _msgKey(String conversationId, String messageId) =>
      '${_msgPrefix(conversationId)}$messageId';

  // --- Conversations -------------------------------------------------------

  Future<Conversation> createConversation({
    required ConversationKind kind,
    String? title,
  }) async {
    final now = DateTime.now();
    final conversation = Conversation(
      id: _uuid.v4(),
      title: title ?? _defaultTitle(kind),
      kind: kind,
      createdAt: now,
      updatedAt: now,
    );
    await _storage.put(
        AppConstants.conversationsBox, _convKey(conversation.id), conversation);
    return conversation;
  }

  Conversation? getConversation(String id) =>
      _storage.get<Conversation>(AppConstants.conversationsBox, _convKey(id));

  List<Conversation> listConversations({ConversationKind? kind}) {
    final all = _storage.getAll<Conversation>(
      AppConstants.conversationsBox,
      keyPrefix: _userPrefix,
    );
    final filtered =
        kind == null ? all : all.where((c) => c.kind == kind).toList();
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  Future<void> deleteConversation(String id) async {
    await _storage.clear(AppConstants.messagesBox,
        keyPrefix: _msgPrefix(id));
    await _storage.delete(AppConstants.conversationsBox, _convKey(id));
  }

  // --- Messages ------------------------------------------------------------

  /// Builds and persists a message in [conversationId]. Returns the message.
  Future<ChatMessage> addMessage({
    required String conversationId,
    required ChatRole role,
    required String content,
    String? imagePath,
    Emotion? emotion,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: DateTime.now(),
      imagePath: imagePath,
      emotion: emotion,
    );
    await _storage.put(
        AppConstants.messagesBox, _msgKey(conversationId, message.id), message);

    final conv = getConversation(conversationId);
    if (conv != null) {
      await _storage.put(
        AppConstants.conversationsBox,
        _convKey(conversationId),
        conv.copyWith(
          updatedAt: message.createdAt,
          lastMessagePreview:
              content.length > 80 ? '${content.substring(0, 80)}…' : content,
        ),
      );
    }
    return message;
  }

  List<ChatMessage> loadMessages(String conversationId) {
    final messages = _storage.getAll<ChatMessage>(
      AppConstants.messagesBox,
      keyPrefix: _msgPrefix(conversationId),
    );
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  String _defaultTitle(ConversationKind kind) {
    switch (kind) {
      case ConversationKind.chat:
        return 'New chat';
      case ConversationKind.voice:
        return 'Voice conversation';
      case ConversationKind.vision:
        return 'Vision analysis';
      case ConversationKind.multilingual:
        return 'Multilingual chat';
      case ConversationKind.translation:
        return 'Translation';
    }
  }
}
