import '../../../../core/constants/app_constants.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../models/ai_personality.dart';
import 'personality_repository.dart';

class PersonalityRepositoryImpl implements PersonalityRepository {
  final LocalStorageService _storage;
  final SessionManager _session;

  PersonalityRepositoryImpl(this._storage, this._session);

  String get _prefix => '${_session.current.userId}${AppConstants.keySeparator}';
  String _key(String id) => '$_prefix$id';

  @override
  List<AIPersonality> getAll() {
    final all = _storage.getAll<AIPersonality>(
      AppConstants.personalityBox,
      keyPrefix: _prefix,
    );
    all.sort((a, b) {
      if (a.isBuiltIn != b.isBuiltIn) return a.isBuiltIn ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return all;
  }

  @override
  AIPersonality? getById(String id) =>
      _storage.get<AIPersonality>(AppConstants.personalityBox, _key(id));

  @override
  AIPersonality getActiveOrDefault(String id) {
    final byId = getById(id);
    if (byId != null) return byId;
    final all = getAll();
    return all.isNotEmpty ? all.first : AIPersonality.presets.first;
  }

  @override
  Future<void> save(AIPersonality personality) => _storage.put(
        AppConstants.personalityBox,
        _key(personality.id),
        personality,
      );

  @override
  Future<void> delete(String id) =>
      _storage.delete(AppConstants.personalityBox, _key(id));

  @override
  Future<void> seedPresetsIfNeeded() async {
    if (getAll().isNotEmpty) return;
    for (final preset in AIPersonality.presets) {
      await save(preset);
    }
  }
}
