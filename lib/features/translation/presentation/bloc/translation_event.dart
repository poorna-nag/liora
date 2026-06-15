part of 'translation_bloc.dart';

sealed class TranslationEvent extends Equatable {
  const TranslationEvent();

  @override
  List<Object?> get props => [];
}

class TranslationStarted extends TranslationEvent {
  const TranslationStarted();
}

class TranslationSourceLanguageChanged extends TranslationEvent {
  final LanguageOption language;
  const TranslationSourceLanguageChanged(this.language);

  @override
  List<Object?> get props => [language];
}

class TranslationTargetLanguageChanged extends TranslationEvent {
  final LanguageOption language;
  const TranslationTargetLanguageChanged(this.language);

  @override
  List<Object?> get props => [language];
}

class TranslationLanguagesSwapped extends TranslationEvent {
  const TranslationLanguagesSwapped();
}

/// User tapped the mic to speak the source text.
class TranslationListenRequested extends TranslationEvent {
  const TranslationListenRequested();
}

class TranslationListenStopped extends TranslationEvent {
  const TranslationListenStopped();
}

/// Internal: recognizer produced a (partial/final) transcript.
class TranslationTranscriptUpdated extends TranslationEvent {
  final String transcript;
  final bool isFinal;
  const TranslationTranscriptUpdated(this.transcript, this.isFinal);

  @override
  List<Object?> get props => [transcript, isFinal];
}

/// Translate typed text directly.
class TranslationTextSubmitted extends TranslationEvent {
  final String text;
  const TranslationTextSubmitted(this.text);

  @override
  List<Object?> get props => [text];
}

/// Speak a translated result aloud.
class TranslationSpeakRequested extends TranslationEvent {
  final String text;
  const TranslationSpeakRequested(this.text);

  @override
  List<Object?> get props => [text];
}
