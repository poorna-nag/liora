part of 'character_bloc.dart';

sealed class CharacterEvent extends Equatable {
  const CharacterEvent();

  @override
  List<Object?> get props => [];
}

class CharacterStarted extends CharacterEvent {
  const CharacterStarted();
}

class CharacterSelected extends CharacterEvent {
  final String id;
  const CharacterSelected(this.id);

  @override
  List<Object?> get props => [id];
}

class CharacterSaved extends CharacterEvent {
  final CompanionCharacter character;
  const CharacterSaved(this.character);

  @override
  List<Object?> get props => [character];
}

class CharacterDeleted extends CharacterEvent {
  final String id;
  const CharacterDeleted(this.id);

  @override
  List<Object?> get props => [id];
}
