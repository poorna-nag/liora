import '../models/ai_personality.dart';

/// Manages the set of AI personalities for the current user.
abstract class PersonalityRepository {
  List<AIPersonality> getAll();
  AIPersonality? getById(String id);

  /// Returns [id]'s personality, or a sensible default if missing.
  AIPersonality getActiveOrDefault(String id);

  Future<void> save(AIPersonality personality);
  Future<void> delete(String id);

  /// Seeds built-in presets on first launch (no-op if already seeded).
  Future<void> seedPresetsIfNeeded();
}
