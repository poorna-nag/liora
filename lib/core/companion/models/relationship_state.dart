import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

/// How close the user and a companion have become. Derived from the interaction
/// [RelationshipState.score]; the companion's tone warms up as this rises.
enum RelationshipLevel {
  stranger,
  friend,
  closeFriend,
  bestFriend,
  trustedCompanion,
}

extension RelationshipLevelInfo on RelationshipLevel {
  String get label {
    switch (this) {
      case RelationshipLevel.stranger:
        return 'Stranger';
      case RelationshipLevel.friend:
        return 'Friend';
      case RelationshipLevel.closeFriend:
        return 'Close Friend';
      case RelationshipLevel.bestFriend:
        return 'Best Friend';
      case RelationshipLevel.trustedCompanion:
        return 'Trusted Companion';
    }
  }

  /// A short tone instruction injected into the prompt so the companion's
  /// familiarity matches the relationship.
  String get toneHint {
    switch (this) {
      case RelationshipLevel.stranger:
        return 'You have just met the user. Be warm but a little polite, as '
            'you are still getting to know each other.';
      case RelationshipLevel.friend:
        return 'You and the user are friends. Be relaxed, friendly and familiar.';
      case RelationshipLevel.closeFriend:
        return 'You are close friends. Be affectionate, informal and refer '
            'back to shared context naturally.';
      case RelationshipLevel.bestFriend:
        return 'You are best friends. Be playful, deeply supportive and very '
            'familiar, like someone who knows the user well.';
      case RelationshipLevel.trustedCompanion:
        return 'You are the user\'s most trusted companion. Be intimate, loyal '
            'and deeply attuned, speaking with the ease of years together.';
    }
  }

  /// Minimum score (interaction points) required to reach this level.
  int get threshold {
    switch (this) {
      case RelationshipLevel.stranger:
        return 0;
      case RelationshipLevel.friend:
        return 10;
      case RelationshipLevel.closeFriend:
        return 30;
      case RelationshipLevel.bestFriend:
        return 80;
      case RelationshipLevel.trustedCompanion:
        return 160;
    }
  }

  static RelationshipLevel fromScore(int score) {
    var level = RelationshipLevel.stranger;
    for (final l in RelationshipLevel.values) {
      if (score >= l.threshold) level = l;
    }
    return level;
  }
}

/// Persisted relationship between the user and one companion.
class RelationshipState extends Equatable {
  final String companionId;
  final int score;
  final DateTime firstMetAt;
  final DateTime lastInteractionAt;

  const RelationshipState({
    required this.companionId,
    required this.score,
    required this.firstMetAt,
    required this.lastInteractionAt,
  });

  RelationshipLevel get level => RelationshipLevelInfo.fromScore(score);

  /// Progress (0..1) toward the next level, for dashboard display.
  double get progressToNext {
    final current = level;
    final values = RelationshipLevel.values;
    final idx = values.indexOf(current);
    if (idx >= values.length - 1) return 1.0;
    final next = values[idx + 1];
    final span = next.threshold - current.threshold;
    if (span <= 0) return 1.0;
    return ((score - current.threshold) / span).clamp(0.0, 1.0);
  }

  RelationshipState copyWith({
    int? score,
    DateTime? lastInteractionAt,
  }) =>
      RelationshipState(
        companionId: companionId,
        score: score ?? this.score,
        firstMetAt: firstMetAt,
        lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      );

  @override
  List<Object?> get props => [companionId, score, firstMetAt, lastInteractionAt];
}

/// Manual Hive adapter (typeId 9).
class RelationshipStateAdapter extends TypeAdapter<RelationshipState> {
  @override
  final int typeId = 9;

  @override
  RelationshipState read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, n = reader.readByte(); i < n; i++)
        reader.readByte(): reader.read(),
    };
    return RelationshipState(
      companionId: fields[0] as String,
      score: fields[1] as int,
      firstMetAt: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
      lastInteractionAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
    );
  }

  @override
  void write(BinaryWriter writer, RelationshipState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.companionId)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.firstMetAt.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.lastInteractionAt.millisecondsSinceEpoch);
  }
}
