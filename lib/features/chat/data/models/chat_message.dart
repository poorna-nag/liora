import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

import '../../../emotion/data/models/emotion.dart';
import 'chat_role.dart';

/// A single chat message belonging to a conversation.
class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  /// Optional local file path of an attached image (vision messages).
  final String? imagePath;

  /// Emotion the companion expressed for an assistant message (null for user
  /// messages and pre-V2 records).
  final Emotion? emotion;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.imagePath,
    this.emotion,
  });

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({String? content}) => ChatMessage(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        createdAt: createdAt,
        imagePath: imagePath,
        emotion: emotion,
      );

  @override
  List<Object?> get props =>
      [id, conversationId, role, content, createdAt, imagePath, emotion];
}

/// Manual Hive adapter (typeId 1).
class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 1;

  @override
  ChatMessage read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, n = reader.readByte(); i < n; i++)
        reader.readByte(): reader.read(),
    };
    return ChatMessage(
      id: fields[0] as String,
      conversationId: fields[1] as String,
      role: fields[2] as ChatRole,
      content: fields[3] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      imagePath: fields[5] as String?,
      emotion: fields[6] as Emotion?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.imagePath)
      ..writeByte(6)
      ..write(obj.emotion);
  }
}
