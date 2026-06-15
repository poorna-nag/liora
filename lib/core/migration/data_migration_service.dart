/// Seam for migrating locally-stored guest data to an authenticated account.
///
/// V1 ships a no-op implementation so the rest of the app can depend on the
/// interface today. When Firebase Authentication is added in V2, implement
/// [migrateGuestData] to copy every entry scoped by the old guest `userId`
/// into the new account's namespace (and/or push it to a remote store), then
/// optionally clear the guest namespace.
abstract class DataMigrationService {
  Future<void> migrateGuestData({
    required String fromUserId,
    required String toUserId,
  });
}

/// V1 no-op: there is no account to migrate to yet.
class NoopDataMigrationService implements DataMigrationService {
  const NoopDataMigrationService();

  @override
  Future<void> migrateGuestData({
    required String fromUserId,
    required String toUserId,
  }) async {
    // Intentionally does nothing in V1.
  }
}
