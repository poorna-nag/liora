import 'package:hive_ce/hive.dart';

/// Author of a chat message.
enum ChatRole { user, assistant, system }

/// Manual Hive adapter (typeId 0).
class ChatRoleAdapter extends TypeAdapter<ChatRole> {
  @override
  final int typeId = 0;

  @override
  ChatRole read(BinaryReader reader) {
    final index = reader.readByte();
    return ChatRole.values[index];
  }

  @override
  void write(BinaryWriter writer, ChatRole obj) {
    writer.writeByte(obj.index);
  }
}
