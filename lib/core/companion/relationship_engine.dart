import '../constants/app_constants.dart';
import '../session/session_manager.dart';
import '../storage/local_storage_service.dart';
import 'models/relationship_state.dart';

/// Tracks and grows the bond between the user and each companion. Every
/// interaction adds points; the derived [RelationshipLevel] feeds the
/// [PersonalityEngine] so the companion's tone warms up over time.
///
/// State is persisted per user and per companion, so switching companions keeps
/// each relationship independent.
class RelationshipEngine {
  final LocalStorageService _storage;
  final SessionManager _session;

  RelationshipEngine(this._storage, this._session);

  String get _prefix => '${_session.current.userId}${AppConstants.keySeparator}';
  String _key(String companionId) => '$_prefix$companionId';

  /// Returns the stored relationship for [companionId], creating a fresh one
  /// (Stranger, on first meeting) if none exists yet.
  RelationshipState getOrCreate(String companionId) {
    final existing = _storage.get<RelationshipState>(
        AppConstants.relationshipBox, _key(companionId));
    if (existing != null) return existing;
    final now = DateTime.now();
    return RelationshipState(
      companionId: companionId,
      score: 0,
      firstMetAt: now,
      lastInteractionAt: now,
    );
  }

  RelationshipLevel levelFor(String companionId) =>
      getOrCreate(companionId).level;

  /// Records an interaction with [companionId], adding [points] and returning
  /// the updated state. Persisted immediately.
  Future<RelationshipState> registerInteraction(
    String companionId, {
    int points = 1,
  }) async {
    final current = getOrCreate(companionId);
    final updated = current.copyWith(
      score: current.score + points,
      lastInteractionAt: DateTime.now(),
    );
    await _storage.put(
        AppConstants.relationshipBox, _key(companionId), updated);
    return updated;
  }

  /// All known relationships for the current user (for the dashboard).
  List<RelationshipState> all() => _storage.getAll<RelationshipState>(
        AppConstants.relationshipBox,
        keyPrefix: _prefix,
      );
}
