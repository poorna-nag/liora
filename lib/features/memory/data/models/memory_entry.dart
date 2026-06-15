import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

/// A persistent fact the assistant should remember across conversations
/// (e.g. "User's name is Aditya", "Prefers concise answers").
class MemoryEntry extends Equatable {
  final String id;
  final String content;
  final DateTime createdAt;

  /// User-pinned memories are always injected; others may be summarized.
  final bool pinned;

  const MemoryEntry({
    required this.id,
    required this.content,
    required this.createdAt,
    this.pinned = false,
  });

  MemoryEntry copyWith({String? content, bool? pinned}) => MemoryEntry(
        id: id,
        content: content ?? this.content,
        createdAt: createdAt,
        pinned: pinned ?? this.pinned,
      );

  @override
  List<Object?> get props => [id, content, createdAt, pinned];
}

/// Manual Hive adapter (typeId 3).
class MemoryEntryAdapter extends TypeAdapter<MemoryEntry> {
  @override
  final int typeId = 3;

  @override
  MemoryEntry read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, n = reader.readByte(); i < n; i++)
        reader.readByte(): reader.read(),
    };
    return MemoryEntry(
      id: fields[0] as String,
      content: fields[1] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
      pinned: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MemoryEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.pinned);
  }
}
