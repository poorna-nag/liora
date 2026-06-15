part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Opens an existing conversation, or starts a new one when [conversationId]
/// is null.
class ChatStarted extends ChatEvent {
  final String? conversationId;
  const ChatStarted({this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class ChatMessageSent extends ChatEvent {
  final String text;
  const ChatMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}
