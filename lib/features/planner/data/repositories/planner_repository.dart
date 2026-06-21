import '../models/plan_item.dart';

/// Phase 6 — persistence for the user's plans/reminders and the proactive
/// summary the companion uses.
abstract class PlannerRepository {
  /// All items, sorted: not-done first, then by due date (soonest first),
  /// undated last.
  List<PlanItem> list();

  Future<PlanItem> add({
    required String title,
    String notes,
    DateTime? dueAt,
  });

  Future<void> toggleDone(String id);

  Future<void> delete(String id);

  /// Pending items due today or overdue — what the companion should mention.
  List<PlanItem> dueNow();

  /// A short, friendly, companion-voiced line about what's due, or null when
  /// there's nothing to surface.
  String? proactiveSummary();
}
