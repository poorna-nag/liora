import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/theme/app_colors.dart';

/// The visual + vocal "species" of a companion. This is what the vector avatar
/// painter switches on to draw the right face, and what supplies sensible
/// default voice parameters. Adding a new archetype here (plus a branch in the
/// avatar painter) is all it takes to support a brand-new look.
enum CharacterArchetype {
  friendlyMale,
  friendlyFemale,
  grandpa,
  grandma,
  child,
  robot,
  anime,
}

/// Rendering + voice metadata for each [CharacterArchetype]. Pure presentation
/// data, kept out of the persisted enum so storage stays a single byte.
extension CharacterArchetypeInfo on CharacterArchetype {
  String get key => name;

  String get label {
    switch (this) {
      case CharacterArchetype.friendlyMale:
        return 'Friendly Young Male';
      case CharacterArchetype.friendlyFemale:
        return 'Friendly Young Female';
      case CharacterArchetype.grandpa:
        return 'Grandpa';
      case CharacterArchetype.grandma:
        return 'Grandma';
      case CharacterArchetype.child:
        return 'Child';
      case CharacterArchetype.robot:
        return 'Robot';
      case CharacterArchetype.anime:
        return 'Anime Style';
    }
  }

  /// Primary skin / body tone used by the avatar painter.
  Color get skinTone {
    switch (this) {
      case CharacterArchetype.friendlyMale:
        return const Color(0xFFEAC393);
      case CharacterArchetype.friendlyFemale:
        return const Color(0xFFF2C9A0);
      case CharacterArchetype.grandpa:
        return const Color(0xFFE7C4A0);
      case CharacterArchetype.grandma:
        return const Color(0xFFF0CDB0);
      case CharacterArchetype.child:
        return const Color(0xFFF6D2B3);
      case CharacterArchetype.robot:
        return const Color(0xFFB8C4D6);
      case CharacterArchetype.anime:
        return const Color(0xFFFBE0D0);
    }
  }

  /// Hair / accent colour (also used for robot chassis trim).
  Color get hairColor {
    switch (this) {
      case CharacterArchetype.friendlyMale:
        return const Color(0xFF3B2A20);
      case CharacterArchetype.friendlyFemale:
        return const Color(0xFF5A3825);
      case CharacterArchetype.grandpa:
        return const Color(0xFFBFBFBF);
      case CharacterArchetype.grandma:
        return const Color(0xFFCFCFCF);
      case CharacterArchetype.child:
        return const Color(0xFF6B4423);
      case CharacterArchetype.robot:
        return AppColors.secondary;
      case CharacterArchetype.anime:
        return const Color(0xFF8E5BE8);
    }
  }

  /// Themed accent used for cards, glows and selection highlights.
  Color get accent {
    switch (this) {
      case CharacterArchetype.friendlyMale:
        return AppColors.primary;
      case CharacterArchetype.friendlyFemale:
        return AppColors.accent;
      case CharacterArchetype.grandpa:
        return const Color(0xFF7A8AA0);
      case CharacterArchetype.grandma:
        return const Color(0xFFC98AAE);
      case CharacterArchetype.child:
        return const Color(0xFFF2B705);
      case CharacterArchetype.robot:
        return AppColors.secondary;
      case CharacterArchetype.anime:
        return const Color(0xFF8E5BE8);
    }
  }

  bool get hasBeard => this == CharacterArchetype.grandpa;
  bool get hasGlasses =>
      this == CharacterArchetype.grandpa || this == CharacterArchetype.grandma;
  bool get isRobot => this == CharacterArchetype.robot;

  /// Big anime-style eyes / child-like proportions render larger eyes.
  double get eyeScale {
    switch (this) {
      case CharacterArchetype.anime:
        return 1.5;
      case CharacterArchetype.child:
        return 1.3;
      case CharacterArchetype.robot:
        return 1.15;
      default:
        return 1.0;
    }
  }

  // --- Default voice profile (overridable per character) -------------------

  String get defaultVoiceLocale => 'en-US';

  double get defaultVoicePitch {
    switch (this) {
      case CharacterArchetype.friendlyMale:
        return 0.95;
      case CharacterArchetype.friendlyFemale:
        return 1.15;
      case CharacterArchetype.grandpa:
        return 0.8;
      case CharacterArchetype.grandma:
        return 1.05;
      case CharacterArchetype.child:
        return 1.4;
      case CharacterArchetype.robot:
        return 0.85;
      case CharacterArchetype.anime:
        return 1.3;
    }
  }

  double get defaultVoiceRate {
    switch (this) {
      case CharacterArchetype.child:
      case CharacterArchetype.anime:
        return 0.55;
      case CharacterArchetype.grandpa:
      case CharacterArchetype.grandma:
        return 0.42;
      case CharacterArchetype.robot:
        return 0.48;
      default:
        return 0.5;
    }
  }

  static CharacterArchetype fromName(
    String? value, {
    CharacterArchetype fallback = CharacterArchetype.friendlyFemale,
  }) {
    if (value == null) return fallback;
    final normalized = value.trim();
    for (final a in CharacterArchetype.values) {
      if (a.name == normalized) return a;
    }
    return fallback;
  }
}

/// Manual Hive adapter (typeId 7).
class CharacterArchetypeAdapter extends TypeAdapter<CharacterArchetype> {
  @override
  final int typeId = 7;

  @override
  CharacterArchetype read(BinaryReader reader) {
    final index = reader.readByte();
    return CharacterArchetype.values[index];
  }

  @override
  void write(BinaryWriter writer, CharacterArchetype obj) {
    writer.writeByte(obj.index);
  }
}
