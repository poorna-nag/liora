import 'package:equatable/equatable.dart';

import '../../../features/emotion/data/models/emotion.dart';

/// High-level room/context type the companion infers from the frame. Drives
/// context-aware suggestions (a kitchen tip differs from an office tip).
enum SceneType {
  kitchen,
  office,
  bedroom,
  livingRoom,
  bathroom,
  restaurant,
  garden,
  classroom,
  street,
  store,
  vehicle,
  unknown,
}

/// Direction the companion suggests moving the camera, like a friend saying
/// "show me the window over there".
enum GuidanceDirection { left, right, up, down, closer, farther, none }

/// A camera-movement hint with a short human reason.
class GuidanceHint extends Equatable {
  final GuidanceDirection direction;
  final String reason;

  const GuidanceHint({this.direction = GuidanceDirection.none, this.reason = ''});

  static const none = GuidanceHint();

  bool get hasDirection => direction != GuidanceDirection.none;

  @override
  List<Object?> get props => [direction, reason];
}

/// An optional region of interest, in normalized (0..1) coordinates relative to
/// the frame. Rendered as a minimal highlight box (NOT full AR tracking).
class HighlightRect extends Equatable {
  final double x;
  final double y;
  final double w;
  final double h;
  final String label;

  const HighlightRect({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.label = '',
  });

  @override
  List<Object?> get props => [x, y, w, h, label];
}

/// The structured result of observing one frame — parsed from the model's JSON
/// reply by the LiveVision data layer. This is the surface-agnostic semantic
/// unit the whole feature is built around: overlays, speech and scene memory
/// are all derived from it, so future surfaces (3D avatar, AR, glasses) consume
/// the same model unchanged.
class SceneObservation extends Equatable {
  final SceneType scene;

  /// The natural-language line to speak now (already free of JSON wrapper).
  final String speech;

  /// Objects newly visible versus the prior scene summary.
  final List<String> newObjects;

  /// Notable changes versus the prior summary (e.g. "desk moved left").
  final List<String> changes;

  final GuidanceHint guidance;

  /// A single optional actionable tip; empty when none.
  final String suggestion;

  final HighlightRect? highlight;

  /// Model self-reported confidence 0..1. Low values suppress overlays/speech.
  final double confidence;

  /// Emotion carried from the [CompanionResponse] (drives avatar + prosody).
  final Emotion emotion;

  const SceneObservation({
    this.scene = SceneType.unknown,
    this.speech = '',
    this.newObjects = const [],
    this.changes = const [],
    this.guidance = GuidanceHint.none,
    this.suggestion = '',
    this.highlight,
    this.confidence = 0.0,
    this.emotion = Emotion.neutral,
  });

  /// An empty observation used when the model output is unusable.
  static const empty = SceneObservation();

  bool get hasSpeech => speech.trim().isNotEmpty;

  @override
  List<Object?> get props => [
        scene,
        speech,
        newObjects,
        changes,
        guidance,
        suggestion,
        highlight,
        confidence,
        emotion,
      ];
}

/// Maps the JSON `scene` string to a [SceneType], tolerating unknown values.
SceneType sceneTypeFromKey(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'kitchen':
      return SceneType.kitchen;
    case 'office':
      return SceneType.office;
    case 'bedroom':
      return SceneType.bedroom;
    case 'living_room':
    case 'livingroom':
      return SceneType.livingRoom;
    case 'bathroom':
      return SceneType.bathroom;
    case 'restaurant':
      return SceneType.restaurant;
    case 'garden':
      return SceneType.garden;
    case 'classroom':
      return SceneType.classroom;
    case 'street':
      return SceneType.street;
    case 'store':
      return SceneType.store;
    case 'vehicle':
      return SceneType.vehicle;
    default:
      return SceneType.unknown;
  }
}

/// Human label for a [SceneType], used in scene-memory summaries and overlays.
String sceneTypeLabel(SceneType type) {
  switch (type) {
    case SceneType.kitchen:
      return 'kitchen';
    case SceneType.office:
      return 'office';
    case SceneType.bedroom:
      return 'bedroom';
    case SceneType.livingRoom:
      return 'living room';
    case SceneType.bathroom:
      return 'bathroom';
    case SceneType.restaurant:
      return 'restaurant';
    case SceneType.garden:
      return 'garden';
    case SceneType.classroom:
      return 'classroom';
    case SceneType.street:
      return 'street';
    case SceneType.store:
      return 'store';
    case SceneType.vehicle:
      return 'vehicle';
    case SceneType.unknown:
      return 'unknown';
  }
}

/// Maps the JSON `direction` string to a [GuidanceDirection].
GuidanceDirection guidanceDirectionFromKey(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'left':
      return GuidanceDirection.left;
    case 'right':
      return GuidanceDirection.right;
    case 'up':
      return GuidanceDirection.up;
    case 'down':
      return GuidanceDirection.down;
    case 'closer':
      return GuidanceDirection.closer;
    case 'farther':
    case 'further':
      return GuidanceDirection.farther;
    default:
      return GuidanceDirection.none;
  }
}
