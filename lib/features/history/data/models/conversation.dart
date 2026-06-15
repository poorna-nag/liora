import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

/// Origin feature of a conversation, so history can label/filter it.
enum ConversationKind { chat, voice, vision, multilingual, translation }

/// Metadata for a stored conversation. Messages are stored separately
/// (keyed by [id]) so a list view can load cheaply.
class Conversation extends Equatable {
  final String id;
  final String title;
  final ConversationKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessagePreview;

  const Conversation({
    required this.id,
    required this.title,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessagePreview,
  });

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    String? lastMessagePreview,
  }) =>
      Conversation(
        id: id,
        title: title ?? this.title,
        kind: kind,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      );

  @override
  List<Object?> get props =>
      [id, title, kind, createdAt, updatedAt, lastMessagePreview];
}

/// Manual Hive adapter (typeId 2).
class ConversationAdapter extends TypeAdapter<Conversation> {
  @override
  final int typeId = 2;

  @override
  Conversation read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, n = reader.readByte(); i < n; i++)
        reader.readByte(): reader.read(),
    };
    return Conversation(
      id: fields[0] as String,
      title: fields[1] as String,
      kind: ConversationKind.values[fields[2] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      lastMessagePreview: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Conversation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.kind.index)
      ..writeByte(3)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.updatedAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.lastMessagePreview);
  }
}
