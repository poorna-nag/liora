import 'scene_observation.dart';

/// Transient, session-only memory of the environment being observed. Lives only
/// for the duration of one Live Vision session and is discarded on end — nothing
/// here is ever persisted, honoring the privacy requirement.
///
/// It lets the companion behave like a friend who remembers what's already in
/// the room: it tracks what was seen, what was already said, and which areas
/// were explored, so the AI can avoid repeating itself and notice changes.
class SceneMemory {
  /// The most recently inferred room/context type.
  SceneType currentScene = SceneType.unknown;

  /// Everything noticed so far this session (normalized lowercase).
  final Set<String> knownObjects = <String>{};

  /// Recent suggestions, newest last (ring buffer capped in the manager).
  final List<String> recentSuggestions = <String>[];

  /// Short phrases the companion has already said, used for the no-repeat guard.
  final List<String> mentionedPoints = <String>[];

  /// Guidance targets/areas already explored (e.g. "left", "window").
  final Set<String> analyzedAreas = <String>{};

  /// How many observations have been ingested this session.
  int observationCount = 0;

  bool get isEmpty => observationCount == 0;
}
