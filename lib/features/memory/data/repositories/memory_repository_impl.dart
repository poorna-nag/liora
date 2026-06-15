import '../../../../core/services/memory_service.dart';
import '../models/memory_entry.dart';
import 'memory_repository.dart';

/// Delegates to the core [MemoryService] so prompt-injection and the memory
/// management UI share a single source of truth.
class MemoryRepositoryImpl implements MemoryRepository {
  final MemoryService _service;

  MemoryRepositoryImpl(this._service);

  @override
  List<MemoryEntry> getAll() => _service.getEntries();

  @override
  Future<void> add(String content, {bool pinned = false}) =>
      _service.addEntry(content, pinned: pinned);

  @override
  Future<void> update(MemoryEntry entry) => _service.updateEntry(entry);

  @override
  Future<void> delete(String id) => _service.deleteEntry(id);

  @override
  Future<void> clear() => _service.clear();
}
