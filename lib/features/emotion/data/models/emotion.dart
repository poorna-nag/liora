import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/theme/app_colors.dart';

/// The set of emotions the companion can express. The model is asked to pick
/// one of these per reply (see the emotion protocol in the chat repository);
/// it drives the animated avatar's face, the voice prosody and dashboard mood.
enum Emotion {
  happy,
  excited,
  thinking,
  sad,
  concerned,
  laughing,
  confident,
  calm,
  surprised,
  neutral,
}

/// Presentation + voice metadata for each [Emotion]. Kept as an extension so the
/// enum stays a pure, Hive-serialisable value while the UI/voice layers read
/// rich data from here.
extension EmotionInfo on Emotion {
  /// Stable lowercase key used when (de)serialising from the model's reply.
  String get key => name;

  String get label {
    switch (this) {
      case Emotion.happy:
        return 'Happy';
      case Emotion.excited:
        return 'Excited';
      case Emotion.thinking:
        return 'Thinking';
      case Emotion.sad:
        return 'Sad';
      case Emotion.concerned:
        return 'Concerned';
      case Emotion.laughing:
        return 'Laughing';
      case Emotion.confident:
        return 'Confident';
      case Emotion.calm:
        return 'Calm';
      case Emotion.surprised:
        return 'Surprised';
      case Emotion.neutral:
        return 'Neutral';
    }
  }

  String get emoji {
    switch (this) {
      case Emotion.happy:
        return '😊';
      case Emotion.excited:
        return '🤩';
      case Emotion.thinking:
        return '🤔';
      case Emotion.sad:
        return '😢';
      case Emotion.concerned:
        return '😟';
      case Emotion.laughing:
        return '😄';
      case Emotion.confident:
        return '😎';
      case Emotion.calm:
        return '🙂';
      case Emotion.surprised:
        return '😮';
      case Emotion.neutral:
        return '😐';
    }
  }

  /// Accent colour used by the avatar glow and dashboard mood chip.
  Color get color {
    switch (this) {
      case Emotion.happy:
      case Emotion.laughing:
        return AppColors.success;
      case Emotion.excited:
        return AppColors.accent;
      case Emotion.thinking:
        return AppColors.secondary;
      case Emotion.sad:
        return const Color(0xFF5B8DEF);
      case Emotion.concerned:
        return const Color(0xFFE6A23C);
      case Emotion.confident:
        return AppColors.primary;
      case Emotion.calm:
        return const Color(0xFF5FB5A6);
      case Emotion.surprised:
        return const Color(0xFFF067B4);
      case Emotion.neutral:
        return AppColors.primary;
    }
  }

  /// Additive pitch offset applied on top of the character's base voice pitch.
  double get pitchDelta {
    switch (this) {
      case Emotion.excited:
      case Emotion.laughing:
        return 0.20;
      case Emotion.happy:
      case Emotion.surprised:
        return 0.12;
      case Emotion.confident:
        return 0.05;
      case Emotion.sad:
      case Emotion.concerned:
        return -0.15;
      case Emotion.thinking:
      case Emotion.calm:
        return -0.05;
      case Emotion.neutral:
        return 0.0;
    }
  }

  /// Additive speech-rate offset applied on top of the character's base rate.
  double get rateDelta {
    switch (this) {
      case Emotion.excited:
      case Emotion.laughing:
        return 0.08;
      case Emotion.surprised:
        return 0.05;
      case Emotion.sad:
      case Emotion.concerned:
      case Emotion.calm:
        return -0.08;
      case Emotion.thinking:
        return -0.05;
      case Emotion.happy:
      case Emotion.confident:
      case Emotion.neutral:
        return 0.0;
    }
  }

  /// Parses an [Emotion] from a model-provided string, tolerating case,
  /// whitespace and unknown values (falls back to [fallback]).
  static Emotion fromName(String? value, {Emotion fallback = Emotion.neutral}) {
    if (value == null) return fallback;
    final normalized = value.trim().toLowerCase();
    for (final e in Emotion.values) {
      if (e.name == normalized) return e;
    }
    return fallback;
  }
}

/// Manual Hive adapter (typeId 6).
class EmotionAdapter extends TypeAdapter<Emotion> {
  @override
  final int typeId = 6;

  @override
  Emotion read(BinaryReader reader) {
    final index = reader.readByte();
    return Emotion.values[index];
  }

  @override
  void write(BinaryWriter writer, Emotion obj) {
    writer.writeByte(obj.index);
  }
}
