import '../../../../core/constants/app_constants.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/preferences_service.dart';
import '../models/companion_character.dart';
import 'character_repository.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final LocalStorageService _storage;
  final SessionManager _session;
  final PreferencesService _prefs;

  CharacterRepositoryImpl(this._storage, this._session, this._prefs);

  String get _prefix => '${_session.current.userId}${AppConstants.keySeparator}';
  String _key(String id) => '$_prefix$id';

  /// Active-character preference is scoped to the user so each identity keeps
  /// its own companion choice.
  String get _activeKey =>
      '$_prefix${AppConstants.prefActiveCharacterId}';

  @override
  List<CompanionCharacter> getAll() {
    final all = _storage.getAll<CompanionCharacter>(
      AppConstants.characterBox,
      keyPrefix: _prefix,
    );
    all.sort((a, b) {
      if (a.isBuiltIn != b.isBuiltIn) return a.isBuiltIn ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return all;
  }

  @override
  CompanionCharacter? getById(String id) =>
      _storage.get<CompanionCharacter>(AppConstants.characterBox, _key(id));

  @override
  String? getActiveId() => _prefs.getString(_activeKey);

  @override
  CompanionCharacter getActiveOrDefault() {
    final activeId = getActiveId();
    if (activeId != null) {
      final byId = getById(activeId);
      if (byId != null) return byId;
    }
    final all = getAll();
    return all.isNotEmpty ? all.first : CompanionCharacter.presets.first;
  }

  @override
  Future<void> setActive(String id) => _prefs.setString(_activeKey, id);

  @override
  Future<void> save(CompanionCharacter character) => _storage.put(
        AppConstants.characterBox,
        _key(character.id),
        character,
      );

  @override
  Future<void> delete(String id) =>
      _storage.delete(AppConstants.characterBox, _key(id));

  @override
  Future<void> seedPresetsIfNeeded() async {
    if (getAll().isNotEmpty) return;
    for (final preset in CompanionCharacter.presets) {
      await save(preset);
    }
  }
}
