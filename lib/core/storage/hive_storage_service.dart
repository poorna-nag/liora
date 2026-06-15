import 'package:hive_ce/hive.dart';

import '../error/exceptions.dart';
import 'local_storage_service.dart';

/// Hive-backed implementation of [LocalStorageService].
///
/// Boxes are opened during startup (see `AppInitializer`) and accessed here as
/// dynamic boxes holding objects whose adapters have been registered.
class HiveStorageService implements LocalStorageService {
  Box _box(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw CacheException('Box "$boxName" is not open.');
    }
    return Hive.box(boxName);
  }

  @override
  Future<void> put(String boxName, String key, Object value) async {
    try {
      await _box(boxName).put(key, value);
    } catch (e) {
      throw CacheException('Failed to write "$key" to "$boxName": $e');
    }
  }

  @override
  T? get<T>(String boxName, String key) {
    try {
      return _box(boxName).get(key) as T?;
    } catch (e) {
      throw CacheException('Failed to read "$key" from "$boxName": $e');
    }
  }

  @override
  List<T> getAll<T>(String boxName, {String? keyPrefix}) {
    try {
      final box = _box(boxName);
      if (keyPrefix == null) {
        return box.values.cast<T>().toList();
      }
      return box.keys
          .where((k) => k is String && k.startsWith(keyPrefix))
          .map((k) => box.get(k) as T)
          .toList();
    } catch (e) {
      throw CacheException('Failed to read all from "$boxName": $e');
    }
  }

  @override
  List<String> keys(String boxName, {String? keyPrefix}) {
    final box = _box(boxName);
    return box.keys
        .whereType<String>()
        .where((k) => keyPrefix == null || k.startsWith(keyPrefix))
        .toList();
  }

  @override
  Future<void> delete(String boxName, String key) async {
    try {
      await _box(boxName).delete(key);
    } catch (e) {
      throw CacheException('Failed to delete "$key" from "$boxName": $e');
    }
  }

  @override
  Future<void> clear(String boxName, {String? keyPrefix}) async {
    try {
      final box = _box(boxName);
      if (keyPrefix == null) {
        await box.clear();
        return;
      }
      final toDelete = box.keys
          .where((k) => k is String && k.startsWith(keyPrefix))
          .toList();
      await box.deleteAll(toDelete);
    } catch (e) {
      throw CacheException('Failed to clear "$boxName": $e');
    }
  }
}
