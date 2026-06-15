part of 'personality_bloc.dart';

sealed class PersonalityEvent extends Equatable {
  const PersonalityEvent();

  @override
  List<Object?> get props => [];
}

class PersonalityStarted extends PersonalityEvent {
  const PersonalityStarted();
}

class PersonalitySaved extends PersonalityEvent {
  final AIPersonality personality;
  const PersonalitySaved(this.personality);

  @override
  List<Object?> get props => [personality];
}

class PersonalityDeleted extends PersonalityEvent {
  final String id;
  const PersonalityDeleted(this.id);

  @override
  List<Object?> get props => [id];
}
