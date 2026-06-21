import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../models/plan_item.dart';
import 'planner_repository.dart';

/// Hive-backed planner, scoped per user via the same key-namespacing convention
/// as [MemoryService]/[ConversationStore], so V2 account migration stays a
/// simple re-key. Dated items also schedule a local OS reminder (Phase 6).
class PlannerRepositoryImpl implements PlannerRepository {
  final LocalStorageService _storage;
  final SessionManager _session;
  final NotificationService _notifications;
  final _uuid = const Uuid();

  PlannerRepositoryImpl(this._storage, this._session, this._notifications);

  String get _prefix => '${_session.current.userId}${AppConstants.keySeparator}';
  String _key(String id) => '$_prefix$id';

  @override
  List<PlanItem> list() {
    final items = _storage.getAll<PlanItem>(
      AppConstants.plannerBox,
      keyPrefix: _prefix,
    );
    items.sort(_compare);
    return items;
  }

  @override
  Future<PlanItem> add({
    required String title,
    String notes = '',
    DateTime? dueAt,
  }) async {
    final item = PlanItem(
      id: _uuid.v4(),
      title: title.trim(),
      notes: notes.trim(),
      dueAt: dueAt,
      createdAt: DateTime.now(),
    );
    await _storage.put(AppConstants.plannerBox, _key(item.id), item);
    await _scheduleFor(item);
    return item;
  }

  @override
  Future<void> toggleDone(String id) async {
    final item = _storage.get<PlanItem>(AppConstants.plannerBox, _key(id));
    if (item == null) return;
    final updated = item.copyWith(done: !item.done);
    await _storage.put(AppConstants.plannerBox, _key(id), updated);
    // Completed items shouldn't nag; reopened ones get their reminder back.
    if (updated.done) {
      await _notifications.cancel(id);
    } else {
      await _scheduleFor(updated);
    }
  }

  @override
  Future<void> delete(String id) async {
    await _notifications.cancel(id);
    await _storage.delete(AppConstants.plannerBox, _key(id));
  }

  /// Schedules (or skips) the OS reminder for a plan. Asks for notification
  /// permission lazily, the first time a dated reminder is actually created.
  Future<void> _scheduleFor(PlanItem item) async {
    final due = item.dueAt;
    if (item.done || due == null || !due.isAfter(DateTime.now())) return;
    await _notifications.requestPermission();
    await _notifications.scheduleReminder(
      planId: item.id,
      title: item.title,
      body: item.notes.isEmpty ? 'Reminder from your planner' : item.notes,
      dueAt: due,
    );
  }

  @override
  List<PlanItem> dueNow() {
    final items = list()
        .where((i) => !i.done && (i.isDueToday || i.isOverdue))
        .toList();
    return items;
  }

  @override
  String? proactiveSummary() {
    final due = dueNow();
    if (due.isEmpty) return null;
    if (due.length == 1) {
      final item = due.first;
      return item.isOverdue
          ? "Don't forget — \"${item.title}\" was due."
          : 'Heads up: "${item.title}" is on your plan for today.';
    }
    final titles = due.take(3).map((i) => i.title).join(', ');
    return "You've got ${due.length} things on your plan"
        '${due.length > 3 ? ' (including' : ':'} $titles'
        '${due.length > 3 ? ')' : ''}.';
  }

  int _compare(PlanItem a, PlanItem b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    final ad = a.dueAt;
    final bd = b.dueAt;
    if (ad == null && bd == null) return b.createdAt.compareTo(a.createdAt);
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  }
}
