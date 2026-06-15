part of 'chat_bloc.dart';

enum ChatStatus { initial, ready, sending, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final String? conversationId;
  final List<ChatMessage> messages;
  final String? errorMessage;

  /// The emotion the companion avatar should currently express.
  final Emotion emotion;

  /// What the companion avatar should currently be doing.
  final AvatarActivity activity;

  const ChatState({
    this.status = ChatStatus.initial,
    this.conversationId,
    this.messages = const [],
    this.errorMessage,
    this.emotion = Emotion.calm,
    this.activity = AvatarActivity.idle,
  });

  bool get isSending => status == ChatStatus.sending;

  ChatState copyWith({
    ChatStatus? status,
    String? conversationId,
    List<ChatMessage>? messages,
    String? errorMessage,
    Emotion? emotion,
    AvatarActivity? activity,
  }) =>
      ChatState(
        status: status ?? this.status,
        conversationId: conversationId ?? this.conversationId,
        messages: messages ?? this.messages,
        errorMessage: errorMessage,
        emotion: emotion ?? this.emotion,
        activity: activity ?? this.activity,
      );

  @override
  List<Object?> get props =>
      [status, conversationId, messages, errorMessage, emotion, activity];
}
