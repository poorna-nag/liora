import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

/// Structured, long-term knowledge the companion keeps about the user. This
/// complements the free-form [MemoryEntry] facts: it holds the high-value,
/// queryable fields the spec calls out, and is injected into every prompt.
///
/// One record per user. Designed for future cloud sync (plain serialisable
/// fields, user-scoped key).
class CompanionProfile extends Equatable {
  final String? userName;
  final String? preferredLanguage;
  final List<String> favouriteTopics;
  final List<String> goals;
  final List<String> preferences;

  const CompanionProfile({
    this.userName,
    this.preferredLanguage,
    this.favouriteTopics = const [],
    this.goals = const [],
    this.preferences = const [],
  });

  bool get isEmpty =>
      (userName == null || userName!.isEmpty) &&
      (preferredLanguage == null || preferredLanguage!.isEmpty) &&
      favouriteTopics.isEmpty &&
      goals.isEmpty &&
      preferences.isEmpty;

  CompanionProfile copyWith({
    String? userName,
    String? preferredLanguage,
    List<String>? favouriteTopics,
    List<String>? goals,
    List<String>? preferences,
  }) =>
      CompanionProfile(
        userName: userName ?? this.userName,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        favouriteTopics: favouriteTopics ?? this.favouriteTopics,
        goals: goals ?? this.goals,
        preferences: preferences ?? this.preferences,
      );

  @override
  List<Object?> get props =>
      [userName, preferredLanguage, favouriteTopics, goals, preferences];
}

/// Manual Hive adapter (typeId 10).
class CompanionProfileAdapter extends TypeAdapter<CompanionProfile> {
  @override
  final int typeId = 10;

  @override
  CompanionProfile read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, n = reader.readByte(); i < n; i++)
        reader.readByte(): reader.read(),
    };
    return CompanionProfile(
      userName: fields[0] as String?,
      preferredLanguage: fields[1] as String?,
      favouriteTopics: (fields[2] as List?)?.cast<String>() ?? const [],
      goals: (fields[3] as List?)?.cast<String>() ?? const [],
      preferences: (fields[4] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, CompanionProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userName)
      ..writeByte(1)
      ..write(obj.preferredLanguage)
      ..writeByte(2)
      ..write(obj.favouriteTopics)
      ..writeByte(3)
      ..write(obj.goals)
      ..writeByte(4)
      ..write(obj.preferences);
  }
}
