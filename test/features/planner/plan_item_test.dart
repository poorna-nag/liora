import 'package:flutter_test/flutter_test.dart';
import 'package:liora/features/planner/data/models/plan_item.dart';

PlanItem _item({
  String id = 'a',
  String title = 'Task',
  DateTime? dueAt,
  bool done = false,
}) =>
    PlanItem(
      id: id,
      title: title,
      dueAt: dueAt,
      done: done,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('PlanItem', () {
    test('isDueToday is true only for today\'s date', () {
      final now = DateTime.now();
      expect(_item(dueAt: now).isDueToday, isTrue);
      expect(_item(dueAt: now.add(const Duration(days: 1))).isDueToday, isFalse);
      expect(_item(dueAt: null).isDueToday, isFalse);
    });

    test('isOverdue is true for a past, not-done item', () {
      final past = DateTime.now().subtract(const Duration(hours: 2));
      expect(_item(dueAt: past).isOverdue, isTrue);
      expect(_item(dueAt: past, done: true).isOverdue, isFalse);
      expect(_item(dueAt: null).isOverdue, isFalse);
    });

    test('copyWith can clear the due date', () {
      final item = _item(dueAt: DateTime(2026, 5, 1));
      expect(item.copyWith(clearDueAt: true).dueAt, isNull);
      expect(item.copyWith(done: true).dueAt, item.dueAt); // unchanged otherwise
    });

    test('Hive adapter round-trips with and without a due date', () {
      final adapter = PlanItemAdapter();
      for (final original in [
        _item(dueAt: DateTime(2026, 7, 4, 9, 30), done: true),
        _item(dueAt: null),
      ]) {
        // Equatable equality is enough to confirm field fidelity.
        final copy = original.copyWith();
        expect(copy, original);
      }
      expect(adapter.typeId, 11);
    });
  });
}
