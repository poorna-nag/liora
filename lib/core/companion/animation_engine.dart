import '../../features/avatar/presentation/avatar_activity.dart';
import '../../features/emotion/data/models/emotion.dart';

/// Chooses the avatar behaviour to play for a given pipeline phase / emotion —
/// the "Animation Engine" step. The avatar widget itself handles the constant
/// micro-animations (idle breathing, blinking, head movement); this engine
/// selects the higher-level [AvatarActivity] layered on top, so the avatar is
/// never static.
class AnimationEngine {
  AvatarActivity get whileThinking => AvatarActivity.thinking;
  AvatarActivity get whileListening => AvatarActivity.listening;
  AvatarActivity get atRest => AvatarActivity.idle;

  /// Behaviour while delivering a reply: lips move when [spoken], otherwise the
  /// avatar simply rests in its (emotional) expression.
  AvatarActivity activityForReply(Emotion emotion, {required bool spoken}) {
    return spoken ? AvatarActivity.talking : AvatarActivity.idle;
  }

  /// Greeting gesture (used when a companion is first shown / says hello).
  AvatarActivity greetingActivity(Emotion emotion) {
    switch (emotion) {
      case Emotion.excited:
      case Emotion.happy:
      case Emotion.laughing:
        return AvatarActivity.waving;
      default:
        return AvatarActivity.idle;
    }
  }
}
