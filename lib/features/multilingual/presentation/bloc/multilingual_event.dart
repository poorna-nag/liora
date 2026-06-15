part of 'multilingual_bloc.dart';

sealed class MultilingualEvent extends Equatable {
  const MultilingualEvent();

  @override
  List<Object?> get props => [];
}

class MultilingualStarted extends MultilingualEvent {
  const MultilingualStarted();
}

class MultilingualLanguageChanged extends MultilingualEvent {
  final LanguageOption language;
  const MultilingualLanguageChanged(this.language);

  @override
  List<Object?> get props => [language];
}

class MultilingualMessageSent extends MultilingualEvent {
  final String text;
  const MultilingualMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}
