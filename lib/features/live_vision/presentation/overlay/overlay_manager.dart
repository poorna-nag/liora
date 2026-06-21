import '../../../../core/live_vision/models/scene_observation.dart';
import 'models/overlay_spec.dart';

/// Maps a [SceneObservation] into a minimal, clean set of overlays. Caps the
/// number on screen so the UI never gets busy (the spec wants clean & minimal,
/// NOT full AR).
class OverlayManager {
  const OverlayManager();

  /// Confidence below which we suppress visual overlays entirely.
  static const double _confidenceFloor = 0.35;

  List<OverlaySpec> map(SceneObservation o) {
    if (o.confidence < _confidenceFloor) return const [];

    final specs = <OverlaySpec>[];

    if (o.guidance.hasDirection) {
      specs.add(DirectionArrowSpec(o.guidance.direction, o.guidance.reason));
    }
    if (o.highlight != null) {
      specs.add(HighlightBoxSpec(o.highlight!));
    }
    if (o.suggestion.trim().isNotEmpty) {
      specs.add(SuggestionCardSpec(o.suggestion.trim()));
    } else if (o.hasSpeech) {
      // Fall back to echoing the spoken line as a bubble when there's no tip.
      specs.add(RecommendationBubbleSpec(o.speech.trim()));
    }

    // Keep it minimal: at most three overlays at once.
    return specs.length <= 3 ? specs : specs.sublist(0, 3);
  }
}
