import '../models/memory_entry.dart';

/// CRUD over the user's persistent memory entries.
abstract class MemoryRepository {
  List<MemoryEntry> getAll();
  Future<void> add(String content, {bool pinned});
  Future<void> update(MemoryEntry entry);
  Future<void> delete(String id);
  Future<void> clear();
}
