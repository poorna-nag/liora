import '../../../features/avatar/presentation/avatar_activity.dart';
import '../../../features/character/data/models/companion_character.dart';
import '../../../features/emotion/data/models/emotion.dart';
import 'relationship_state.dart';

/// The single, unified result produced by the [CompanionManager] pipeline and
/// consumed by every feature (chat, voice, vision, translation). It bundles the
/// reply with everything the UI/voice layers need to bring it to life.
class CompanionResponse {
  /// The companion's reply text (already stripped of any structured wrapper).
  final String text;

  /// Emotion the companion expressed for this reply.
  final Emotion emotion;

  /// Avatar behaviour to play for this reply.
  final AvatarActivity activity;

  /// The companion that produced the reply.
  final CompanionCharacter companion;

  /// Relationship level at the time of the reply.
  final RelationshipLevel relationshipLevel;

  const CompanionResponse({
    required this.text,
    required this.emotion,
    required this.activity,
    required this.companion,
    required this.relationshipLevel,
  });
}
