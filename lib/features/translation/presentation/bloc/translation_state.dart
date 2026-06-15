part of 'translation_bloc.dart';

enum TranslationStatus { initial, idle, listening, translating, speaking, error }

class TranslationState extends Equatable {
  final TranslationStatus status;
  final String? conversationId;
  final LanguageOption sourceLanguage;
  final LanguageOption targetLanguage;
  final String partialTranscript;
  final List<TranslationResult> results;
  final String? errorMessage;

  TranslationState({
    this.status = TranslationStatus.initial,
    this.conversationId,
    LanguageOption? sourceLanguage,
    LanguageOption? targetLanguage,
    this.partialTranscript = '',
    this.results = const [],
    this.errorMessage,
  })  : sourceLanguage = sourceLanguage ?? LanguageOption.supported[0],
        targetLanguage = targetLanguage ?? LanguageOption.supported[1];

  bool get isListening => status == TranslationStatus.listening;
  bool get isBusy =>
      status == TranslationStatus.translating ||
      status == TranslationStatus.speaking;

  TranslationState copyWith({
    TranslationStatus? status,
    String? conversationId,
    LanguageOption? sourceLanguage,
    LanguageOption? targetLanguage,
    String? partialTranscript,
    List<TranslationResult>? results,
    String? errorMessage,
  }) =>
      TranslationState(
        status: status ?? this.status,
        conversationId: conversationId ?? this.conversationId,
        sourceLanguage: sourceLanguage ?? this.sourceLanguage,
        targetLanguage: targetLanguage ?? this.targetLanguage,
        partialTranscript: partialTranscript ?? this.partialTranscript,
        results: results ?? this.results,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [
        status,
        conversationId,
        sourceLanguage,
        targetLanguage,
        partialTranscript,
        results,
        errorMessage,
      ];
}
