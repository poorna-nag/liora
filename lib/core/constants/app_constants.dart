/// App-wide constant values.
///
/// Box names are intentionally generic; per-user scoping is achieved by
/// namespacing keys with the current `userId` (see [SessionManager]), which
/// keeps V2 auth migration to a simple re-key/copy operation.
class AppConstants {
  AppConstants._();

  static const String appName = 'Liora';
  static const String appTagline = 'Your intelligent everyday companion';

  // Hive box names (structured data).
  static const String conversationsBox = 'conversations';
  static const String messagesBox = 'messages';
  static const String memoryBox = 'memory_entries';
  static const String personalityBox = 'personalities';
  static const String settingsBox = 'app_settings';
  // V2 companion data.
  static const String characterBox = 'characters';
  static const String relationshipBox = 'relationships';
  static const String profileBox = 'companion_profile';

  // SharedPreferences keys (small scalars).
  static const String prefGuestId = 'guest_id';
  // Remembers how the user last entered the app: 'guest' or 'authenticated'.
  // Absent => the user has not chosen yet (show the login screen).
  static const String prefAuthChoice = 'auth_choice';
  static const String authChoiceGuest = 'guest';
  static const String authChoiceAuthenticated = 'authenticated';
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguageCode = 'language_code';
  static const String prefActivePersonalityId = 'active_personality_id';
  static const String prefActiveSettingsId = 'active_settings_id';
  // V2: per-user selected companion character.
  static const String prefActiveCharacterId = 'active_character_id';

  // Single fixed key for the singleton settings record.
  static const String settingsKey = 'current';

  // Namespacing separator for per-user scoped storage keys.
  static const String keySeparator = '::';
}
