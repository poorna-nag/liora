import '../models/app_settings.dart';

/// Reads and persists the single [AppSettings] record for the current user.
abstract class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);

  /// Wipes all locally-stored data for the current user (conversations,
  /// messages, memory, custom personalities) while keeping built-in presets.
  Future<void> clearAllData();
}
