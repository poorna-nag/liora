import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

/// Phase 6 — a single thing the user wants to do or be reminded about (an
/// interview, a workout, a deadline). Stored locally and scoped per user; the
/// companion surfaces what's due proactively.
class PlanItem extends Equatable {
  final String id;
  final String title;
  final String notes;

  /// When it's due. Null means "someday / no specific time".
  final DateTime? dueAt;
  final bool done;
  final DateTime createdAt;

  const PlanItem({
    required this.id,
    required this.title,
    this.notes = '',
    this.dueAt,
    this.done = false,
    required this.createdAt,
  });

  PlanItem copyWith({
    String? title,
    String? notes,
    DateTime? dueAt,
    bool? done,
    bool clearDueAt = false,
  }) =>
      PlanItem(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
        done: done ?? this.done,
        createdAt: createdAt,
      );

  bool get isDueToday {
    final d = dueAt;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool get isOverdue => dueAt != null && dueAt!.isBefore(DateTime.now()) && !done;

  @override
  List<Object?> get props => [id, title, notes, dueAt, done, createdAt];
}

/// Manual Hive adapter (typeId 11).
class PlanItemAdapter extends TypeAdapter<PlanItem> {
  @override
  final int typeId = 11;

  @override
  PlanItem read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, n = reader.readByte(); i < n; i++)
        reader.readByte(): reader.read(),
    };
    final dueMs = fields[3] as int?;
    return PlanItem(
      id: fields[0] as String,
      title: fields[1] as String,
      notes: fields[2] as String,
      dueAt: dueMs == null ? null : DateTime.fromMillisecondsSinceEpoch(dueMs),
      done: fields[4] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
    );
  }

  @override
  void write(BinaryWriter writer, PlanItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.dueAt?.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.done)
      ..writeByte(5)
      ..write(obj.createdAt.millisecondsSinceEpoch);
  }
}
