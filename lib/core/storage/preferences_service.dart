import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over [SharedPreferences] for small scalar values
/// (theme, language, guest id, active ids).
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  /// Convenience initializer used during app startup / DI.
  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();
}
