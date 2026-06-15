part of 'vision_bloc.dart';

enum VisionStatus { initial, ready, analyzing, error }

class VisionState extends Equatable {
  final VisionStatus status;
  final String? conversationId;
  final List<ChatMessage> messages;
  final String? errorMessage;

  const VisionState({
    this.status = VisionStatus.initial,
    this.conversationId,
    this.messages = const [],
    this.errorMessage,
  });

  bool get isAnalyzing => status == VisionStatus.analyzing;

  VisionState copyWith({
    VisionStatus? status,
    String? conversationId,
    List<ChatMessage>? messages,
    String? errorMessage,
  }) =>
      VisionState(
        status: status ?? this.status,
        conversationId: conversationId ?? this.conversationId,
        messages: messages ?? this.messages,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, conversationId, messages, errorMessage];
}
