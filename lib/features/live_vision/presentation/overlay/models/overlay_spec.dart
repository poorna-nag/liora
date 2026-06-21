import 'package:equatable/equatable.dart';

import '../../../../../core/live_vision/models/scene_observation.dart';

/// A minimal, declarative description of one on-screen overlay. The screen
/// renders these; nothing here knows about widgets, so the same observation
/// could later drive AR anchors instead of flat overlays.
sealed class OverlaySpec extends Equatable {
  /// Stable id so the screen can animate add/remove without rebuild churn.
  final String id;

  const OverlaySpec(this.id);

  @override
  List<Object?> get props => [id];
}

/// A bottom card with an actionable tip.
class SuggestionCardSpec extends OverlaySpec {
  final String text;
  const SuggestionCardSpec(this.text) : super('suggestion');

  @override
  List<Object?> get props => [id, text];
}

/// A bubble near the companion showing what it just said.
class RecommendationBubbleSpec extends OverlaySpec {
  final String text;
  const RecommendationBubbleSpec(this.text) : super('bubble');

  @override
  List<Object?> get props => [id, text];
}

/// An edge-anchored arrow guiding the camera, with a short caption.
class DirectionArrowSpec extends OverlaySpec {
  final GuidanceDirection direction;
  final String caption;
  const DirectionArrowSpec(this.direction, this.caption) : super('arrow');

  @override
  List<Object?> get props => [id, direction, caption];
}

/// A normalized highlight rectangle (best-effort region of interest).
class HighlightBoxSpec extends OverlaySpec {
  final HighlightRect rect;
  const HighlightBoxSpec(this.rect) : super('highlight');

  @override
  List<Object?> get props => [id, rect];
}
