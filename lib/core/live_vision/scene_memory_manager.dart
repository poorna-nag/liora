import 'models/scene_memory.dart';
import 'models/scene_observation.dart';

/// Owns the transient [SceneMemory] for one session and is responsible for two
/// things the spec calls out:
///
/// 1. **Summarizing** accumulated scene state into a short, token-budgeted text
///    block that gets appended to each frame's instruction, so the AI keeps a
///    continuous understanding of the room instead of treating every frame as
///    brand new.
/// 2. **No-repeat guarding** — deciding whether a freshly generated line is too
///    similar to something already said, so the companion doesn't drone "this
///    is a chair" over and over.
///
/// Everything is in-memory and discarded when the session ends.
class SceneMemoryManager {
  final SceneMemory _memory = SceneMemory();

  static const int _maxKnownObjects = 40;
  static const int _maxSuggestions = 8;
  static const int _maxMentioned = 12;
  static const int _summaryMaxChars = 600;

  /// Two lines counted as "the same point" when their token overlap (Jaccard)
  /// is at or above this — used to drop repetitive speech.
  static const double _repeatJaccardThreshold = 0.8;

  SceneMemory get memory => _memory;

  /// Folds a new observation into the running memory.
  void ingest(SceneObservation o) {
    _memory.observationCount++;
    if (o.scene != SceneType.unknown) {
      _memory.currentScene = o.scene;
    }

    for (final obj in o.newObjects) {
      final n = obj.trim().toLowerCase();
      if (n.isNotEmpty) _memory.knownObjects.add(n);
    }
    _capSet(_memory.knownObjects, _maxKnownObjects);

    final suggestion = o.suggestion.trim();
    if (suggestion.isNotEmpty) {
      _memory.recentSuggestions.add(suggestion);
      _capList(_memory.recentSuggestions, _maxSuggestions);
    }

    final spoken = o.speech.trim();
    if (spoken.isNotEmpty) {
      _memory.mentionedPoints.add(spoken);
      _capList(_memory.mentionedPoints, _maxMentioned);
    }

    // Record the area we were guided toward as "explored".
    if (o.guidance.hasDirection) {
      _memory.analyzedAreas.add(o.guidance.direction.name);
    }
    for (final obj in o.newObjects) {
      final n = obj.trim().toLowerCase();
      if (n.isNotEmpty) _memory.analyzedAreas.add(n);
    }
  }

  /// True when [candidate] essentially repeats something already said, so the
  /// caller should stay silent (but keep observing).
  bool isRepeat(String candidate) {
    final tokens = _tokenize(candidate);
    if (tokens.isEmpty) return false;
    for (final prior in _memory.mentionedPoints) {
      if (_jaccard(tokens, _tokenize(prior)) >= _repeatJaccardThreshold) {
        return true;
      }
    }
    return false;
  }

  /// Builds the prior-context block appended to each instruction. Returns an
  /// empty string for the very first frame (nothing to summarize yet).
  String buildSummary() {
    if (_memory.isEmpty) return '';

    final parts = <String>[];
    if (_memory.currentScene != SceneType.unknown) {
      parts.add('Room: ${sceneTypeLabel(_memory.currentScene)}.');
    }
    if (_memory.knownObjects.isNotEmpty) {
      parts.add('Already noticed: ${_memory.knownObjects.join(', ')}.');
    }
    if (_memory.mentionedPoints.isNotEmpty) {
      final said = _memory.mentionedPoints
          .map((s) => s.length > 80 ? '${s.substring(0, 80)}…' : s)
          .join(' | ');
      parts.add('Already said: $said');
    }
    if (_memory.recentSuggestions.isNotEmpty) {
      parts.add('Suggestions given: ${_memory.recentSuggestions.join('; ')}.');
    }

    var summary = 'PRIOR SCENE CONTEXT (do not repeat any of this):\n'
        '${parts.join('\n')}';
    if (summary.length > _summaryMaxChars) {
      summary = '${summary.substring(0, _summaryMaxChars)}…';
    }
    return summary;
  }

  /// Clears everything — called when the session ends. Nothing was persisted,
  /// so this fully forgets the environment.
  void clear() {
    _memory.currentScene = SceneType.unknown;
    _memory.knownObjects.clear();
    _memory.recentSuggestions.clear();
    _memory.mentionedPoints.clear();
    _memory.analyzedAreas.clear();
    _memory.observationCount = 0;
  }

  // --- helpers -------------------------------------------------------------

  void _capList(List<String> list, int max) {
    while (list.length > max) {
      list.removeAt(0);
    }
  }

  void _capSet(Set<String> set, int max) {
    if (set.length <= max) return;
    final excess = set.length - max;
    final toRemove = set.take(excess).toList();
    set.removeAll(toRemove);
  }

  Set<String> _tokenize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length > 2)
      .toSet();

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0.0 : intersection / union;
  }
}
