import 'package:uuid/uuid.dart';

import '../../features/memory/data/models/memory_entry.dart';
import '../constants/app_constants.dart';
import '../session/session_manager.dart';
import '../storage/local_storage_service.dart';

/// Manages persistent "memory" entries scoped to the current user and builds
/// the memory context string injected into AI prompts.
///
/// Lives in core because multiple features (chat, voice, the memory screen)
/// read/write memory; the memory feature's repository simply delegates here.
class MemoryService {
  final LocalStorageService _storage;
  final SessionManager _session;
  final _uuid = const Uuid();

  MemoryService(this._storage, this._session);

  String get _prefix => '${_session.current.userId}${AppConstants.keySeparator}';
  String _key(String id) => '$_prefix$id';

  List<MemoryEntry> getEntries() {
    final entries = _storage.getAll<MemoryEntry>(
      AppConstants.memoryBox,
      keyPrefix: _prefix,
    );
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<MemoryEntry> addEntry(String content, {bool pinned = false}) async {
    final entry = MemoryEntry(
      id: _uuid.v4(),
      content: content.trim(),
      createdAt: DateTime.now(),
      pinned: pinned,
    );
    await _storage.put(AppConstants.memoryBox, _key(entry.id), entry);
    return entry;
  }

  Future<void> updateEntry(MemoryEntry entry) =>
      _storage.put(AppConstants.memoryBox, _key(entry.id), entry);

  Future<void> deleteEntry(String id) =>
      _storage.delete(AppConstants.memoryBox, _key(id));

  Future<void> clear() =>
      _storage.clear(AppConstants.memoryBox, keyPrefix: _prefix);

  /// Builds a compact context block of remembered facts for prompt injection.
  /// Pinned entries first, then most recent, capped at [limit].
  String buildMemoryContext({int limit = 20}) {
    final entries = getEntries();
    if (entries.isEmpty) return '';
    entries.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    final selected = entries.take(limit).map((e) => '- ${e.content}');
    return 'Known facts about the user:\n${selected.join('\n')}';
  }
}
