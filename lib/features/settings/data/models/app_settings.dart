import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

/// User-configurable application settings (single record per user).
class AppSettings extends Equatable {
  /// Stored as [ThemeMode.index].
  final ThemeMode themeMode;

  /// BCP-47-ish language code used for multilingual / TTS defaults.
  final String languageCode;

  /// Id of the active [AIPersonality].
  final String activePersonalityId;

  /// Whether the assistant may use stored memory entries in prompts.
  final bool memoryEnabled;

  /// Speech rate for text-to-speech (0.0 - 1.0).
  final double speechRate;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.languageCode = 'en',
    this.activePersonalityId = 'preset_friendly',
    this.memoryEnabled = true,
    this.speechRate = 0.5,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    String? activePersonalityId,
    bool? memoryEnabled,
    double? speechRate,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        languageCode: languageCode ?? this.languageCode,
        activePersonalityId: activePersonalityId ?? this.activePersonalityId,
        memoryEnabled: memoryEnabled ?? this.memoryEnabled,
        speechRate: speechRate ?? this.speechRate,
      );

  @override
  List<Object?> get props =>
      [themeMode, languageCode, activePersonalityId, memoryEnabled, speechRate];
}

/// Manual Hive adapter (typeId 5).
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 5;

  @override
  AppSettings read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, n = reader.readByte(); i < n; i++)
        reader.readByte(): reader.read(),
    };
    return AppSettings(
      themeMode: ThemeMode.values[fields[0] as int],
      languageCode: fields[1] as String,
      activePersonalityId: fields[2] as String,
      memoryEnabled: fields[3] as bool,
      speechRate: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.themeMode.index)
      ..writeByte(1)
      ..write(obj.languageCode)
      ..writeByte(2)
      ..write(obj.activePersonalityId)
      ..writeByte(3)
      ..write(obj.memoryEnabled)
      ..writeByte(4)
      ..write(obj.speechRate);
  }
}
