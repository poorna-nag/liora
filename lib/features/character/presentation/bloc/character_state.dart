part of 'character_bloc.dart';

enum CharacterStatus { initial, ready }

class CharacterState extends Equatable {
  final CharacterStatus status;
  final List<CompanionCharacter> characters;

  /// Id of the currently selected companion.
  final String? activeId;

  const CharacterState({
    this.status = CharacterStatus.initial,
    this.characters = const [],
    this.activeId,
  });

  /// The currently selected companion resolved from [characters], or null.
  CompanionCharacter? get active {
    if (activeId == null) return null;
    for (final c in characters) {
      if (c.id == activeId) return c;
    }
    return null;
  }

  CharacterState copyWith({
    CharacterStatus? status,
    List<CompanionCharacter>? characters,
    String? activeId,
  }) =>
      CharacterState(
        status: status ?? this.status,
        characters: characters ?? this.characters,
        activeId: activeId ?? this.activeId,
      );

  @override
  List<Object?> get props => [status, characters, activeId];
}
