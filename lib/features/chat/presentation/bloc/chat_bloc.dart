import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../avatar/presentation/avatar_activity.dart';
import '../../../emotion/data/models/emotion.dart';
import '../../../history/data/models/conversation.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_role.dart';
import '../../data/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;

  /// The kind of conversation this bloc drives (chat / multilingual).
  final ConversationKind kind;

  /// Optional extra system instruction (e.g. force a reply language).
  final String? languageInstruction;

  ChatBloc(
    this._repository, {
    this.kind = ConversationKind.chat,
    this.languageInstruction,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    String? conversationId = event.conversationId;
    if (conversationId == null) {
      final conversation = await _repository.startConversation(kind: kind);
      conversationId = conversation.id;
    }
    final messages = _repository.loadMessages(conversationId);
    emit(state.copyWith(
      status: ChatStatus.ready,
      conversationId: conversationId,
      messages: messages,
      emotion: _latestEmotion(messages),
      activity: AvatarActivity.idle,
    ));
  }

  /// The emotion of the most recent assistant message (the avatar's resting
  /// expression), defaulting to the current state emotion.
  Emotion _latestEmotion(List<ChatMessage> messages) {
    for (final m in messages.reversed) {
      if (!m.isUser && m.emotion != null) return m.emotion!;
    }
    return state.emotion;
  }

  Future<void> _onMessageSent(
      ChatMessageSent event, Emitter<ChatState> emit) async {
    final conversationId = state.conversationId;
    final text = event.text.trim();
    if (conversationId == null || text.isEmpty || state.isSending) return;

    // Optimistically show the user's message immediately.
    final optimistic = ChatMessage(
      id: 'pending_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(
      status: ChatStatus.sending,
      messages: [...state.messages, optimistic],
      activity: AvatarActivity.thinking,
    ));

    try {
      final reply = await _repository.sendMessage(
        conversationId: conversationId,
        text: text,
        languageInstruction: languageInstruction,
      );
      emit(state.copyWith(
        status: ChatStatus.ready,
        messages: _repository.loadMessages(conversationId),
        emotion: reply.emotion ?? state.emotion,
        // Talking is sustained by the voice layer (Phase 4); for now the avatar
        // settles back to idle once the reply lands.
        activity: AvatarActivity.idle,
      ));
    } on Failure catch (f) {
      // Drop the optimistic message and surface the error.
      emit(state.copyWith(
        status: ChatStatus.error,
        messages: _repository.loadMessages(conversationId),
        emotion: Emotion.concerned,
        activity: AvatarActivity.idle,
        errorMessage: f.message,
      ));
    }
  }
}
