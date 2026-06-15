part of 'multilingual_bloc.dart';

enum MultilingualStatus { initial, ready, sending, error }

class MultilingualState extends Equatable {
  final MultilingualStatus status;
  final String? conversationId;
  final List<ChatMessage> messages;
  final LanguageOption language;
  final String? errorMessage;

  MultilingualState({
    this.status = MultilingualStatus.initial,
    this.conversationId,
    this.messages = const [],
    LanguageOption? language,
    this.errorMessage,
  }) : language = language ?? LanguageOption.supported.first;

  bool get isSending => status == MultilingualStatus.sending;

  MultilingualState copyWith({
    MultilingualStatus? status,
    String? conversationId,
    List<ChatMessage>? messages,
    LanguageOption? language,
    String? errorMessage,
  }) =>
      MultilingualState(
        status: status ?? this.status,
        conversationId: conversationId ?? this.conversationId,
        messages: messages ?? this.messages,
        language: language ?? this.language,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, conversationId, messages, language, errorMessage];
}
