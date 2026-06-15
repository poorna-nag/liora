/// Abstract key-value storage façade used by repositories.
///
/// V1 is backed by Hive ([HiveStorageService]). Because repositories depend on
/// this interface rather than Hive directly, V2 can introduce a remote-backed
/// implementation (or a composite local+remote one) without changing callers.
///
/// Keys are expected to be namespaced by the caller with the current `userId`
/// (see [AppConstants.keySeparator]) so per-user data can be enumerated and
/// migrated later.
abstract class LocalStorageService {
  Future<void> put(String boxName, String key, Object value);

  T? get<T>(String boxName, String key);

  /// All values in [boxName] (optionally restricted to keys starting with
  /// [keyPrefix], used for per-user scoping).
  List<T> getAll<T>(String boxName, {String? keyPrefix});

  List<String> keys(String boxName, {String? keyPrefix});

  Future<void> delete(String boxName, String key);

  /// Deletes every entry in [boxName] whose key starts with [keyPrefix]
  /// (or the whole box when [keyPrefix] is null). Used by "clear data" and
  /// future guest -> account migration.
  Future<void> clear(String boxName, {String? keyPrefix});
}
