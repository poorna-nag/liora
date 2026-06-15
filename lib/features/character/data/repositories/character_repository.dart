import '../models/companion_character.dart';

/// Manages the set of companion characters and the active selection for the
/// current user.
abstract class CharacterRepository {
  List<CompanionCharacter> getAll();
  CompanionCharacter? getById(String id);

  /// The id of the currently selected companion (null if never chosen).
  String? getActiveId();

  /// The active companion, or a sensible default when nothing is selected.
  CompanionCharacter getActiveOrDefault();

  Future<void> setActive(String id);

  Future<void> save(CompanionCharacter character);
  Future<void> delete(String id);

  /// Seeds built-in companions on first launch (no-op if already seeded).
  Future<void> seedPresetsIfNeeded();
}
