part of 'voice_conversation_bloc.dart';

enum VoiceStatus { initial, idle, listening, processing, speaking, error }

class VoiceConversationState extends Equatable {
  final VoiceStatus status;
  final String? conversationId;
  final List<ChatMessage> messages;
  final String partialTranscript;
  final String? errorMessage;

  const VoiceConversationState({
    this.status = VoiceStatus.initial,
    this.conversationId,
    this.messages = const [],
    this.partialTranscript = '',
    this.errorMessage,
  });

  bool get isListening => status == VoiceStatus.listening;
  bool get isBusy =>
      status == VoiceStatus.processing || status == VoiceStatus.speaking;

  VoiceConversationState copyWith({
    VoiceStatus? status,
    String? conversationId,
    List<ChatMessage>? messages,
    String? partialTranscript,
    String? errorMessage,
  }) =>
      VoiceConversationState(
        status: status ?? this.status,
        conversationId: conversationId ?? this.conversationId,
        messages: messages ?? this.messages,
        partialTranscript: partialTranscript ?? this.partialTranscript,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, conversationId, messages, partialTranscript, errorMessage];
}
