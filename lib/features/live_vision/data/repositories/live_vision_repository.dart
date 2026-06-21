import 'dart:typed_data';

import '../../../../core/live_vision/models/scene_observation.dart';

/// Data-layer entry point for Live Vision. Turns a compressed camera frame
/// (plus the running scene summary and any pending user question) into a
/// structured [SceneObservation] by routing through the CompanionManager and
/// parsing its reply. Also handles the optional, explicit snapshot save.
abstract class LiveVisionRepository {
  /// Analyzes one frame. [sceneSummary] is the prior-context block from
  /// [SceneMemoryManager]; [userQuestion] is folded into the same call when the
  /// user has just spoken.
  Future<SceneObservation> analyzeFrame({
    required Uint8List imageBytes,
    required String sceneSummary,
    String? userQuestion,
    String? coachDirective,
    String mimeType,
  });

  /// Persists a single frame to the (existing) Vision history at the user's
  /// explicit request. Nothing is stored otherwise.
  Future<void> saveSnapshot({
    required Uint8List imageBytes,
    required String note,
  });
}
