import '../../features/memory/data/models/memory_entry.dart';
import '../constants/app_constants.dart';
import '../services/memory_service.dart';
import '../session/session_manager.dart';
import '../storage/local_storage_service.dart';
import 'models/companion_profile.dart';

/// The companion's memory — step 2 of the pipeline. Combines two layers:
///   * a structured [CompanionProfile] (name, language, topics, goals, prefs)
///   * free-form facts via the existing [MemoryService] (reused, not duplicated)
/// and renders them into a context block injected into every prompt.
///
/// One profile per user; persisted locally and ready for cloud sync later.
class MemoryEngine {
  final MemoryService _facts;
  final LocalStorageService _storage;
  final SessionManager _session;

  MemoryEngine(this._facts, this._storage, this._session);

  String get _profileKey =>
      '${_session.current.userId}${AppConstants.keySeparator}profile';

  CompanionProfile getProfile() =>
      _storage.get<CompanionProfile>(AppConstants.profileBox, _profileKey) ??
      const CompanionProfile();

  Future<void> saveProfile(CompanionProfile profile) =>
      _storage.put(AppConstants.profileBox, _profileKey, profile);

  /// Convenience updater used by callers that learn one field at a time.
  Future<CompanionProfile> update({
    String? userName,
    String? preferredLanguage,
    List<String>? favouriteTopics,
    List<String>? goals,
    List<String>? preferences,
  }) async {
    final updated = getProfile().copyWith(
      userName: userName,
      preferredLanguage: preferredLanguage,
      favouriteTopics: favouriteTopics,
      goals: goals,
      preferences: preferences,
    );
    await saveProfile(updated);
    return updated;
  }

  /// Adds a free-form fact (delegates to the reused MemoryService).
  Future<MemoryEntry> remember(String fact, {bool pinned = false}) =>
      _facts.addEntry(fact, pinned: pinned);

  /// Builds the memory context string injected into the system prompt. Returns
  /// an empty string when there is nothing worth telling the model.
  String buildContext() {
    final buffer = StringBuffer();
    final profile = getProfile();

    if (!profile.isEmpty) {
      buffer.writeln('What you know about the user:');
      if (profile.userName != null && profile.userName!.isNotEmpty) {
        buffer.writeln('- Name: ${profile.userName}');
      }
      if (profile.preferredLanguage != null &&
          profile.preferredLanguage!.isNotEmpty) {
        buffer.writeln('- Preferred language: ${profile.preferredLanguage}');
      }
      if (profile.favouriteTopics.isNotEmpty) {
        buffer.writeln('- Favourite topics: ${profile.favouriteTopics.join(', ')}');
      }
      if (profile.goals.isNotEmpty) {
        buffer.writeln('- Goals: ${profile.goals.join(', ')}');
      }
      if (profile.preferences.isNotEmpty) {
        buffer.writeln('- Preferences: ${profile.preferences.join(', ')}');
      }
    }

    final facts = _facts.buildMemoryContext();
    if (facts.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(facts);
    }
    return buffer.toString().trim();
  }
}
