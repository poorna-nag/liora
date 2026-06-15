import '../../../../core/constants/app_constants.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../models/app_settings.dart';
import 'settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final LocalStorageService _storage;
  final SessionManager _session;

  SettingsRepositoryImpl(this._storage, this._session);

  String get _key =>
      '${_session.current.userId}${AppConstants.keySeparator}${AppConstants.settingsKey}';

  @override
  AppSettings load() {
    return _storage.get<AppSettings>(AppConstants.settingsBox, _key) ??
        const AppSettings();
  }

  @override
  Future<void> save(AppSettings settings) =>
      _storage.put(AppConstants.settingsBox, _key, settings);

  @override
  Future<void> clearAllData() async {
    final prefix = '${_session.current.userId}${AppConstants.keySeparator}';
    await _storage.clear(AppConstants.conversationsBox, keyPrefix: prefix);
    await _storage.clear(AppConstants.messagesBox, keyPrefix: prefix);
    await _storage.clear(AppConstants.memoryBox, keyPrefix: prefix);
    // Custom personalities only; presets are re-seeded by their repository.
    await _storage.clear(AppConstants.personalityBox, keyPrefix: prefix);
  }
}
