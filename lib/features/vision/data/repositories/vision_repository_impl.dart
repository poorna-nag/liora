import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/companion/companion_manager.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/conversation_store.dart';
import '../../../chat/data/models/chat_message.dart';
import '../../../chat/data/models/chat_role.dart';
import '../../../history/data/models/conversation.dart';
import 'vision_repository.dart';

/// Camera vision now flows through the [CompanionManager]: the active companion
/// describes the image in its own personality, and the result carries an
/// emotion for the avatar/voice. This repository only handles persistence and
/// saving the image file locally.
class VisionRepositoryImpl implements VisionRepository {
  final ConversationStore _store;
  final CompanionManager _companion;
  final _uuid = const Uuid();

  VisionRepositoryImpl(this._store, this._companion);

  @override
  Future<Conversation> start() =>
      _store.createConversation(kind: ConversationKind.vision);

  @override
  List<ChatMessage> loadMessages(String conversationId) =>
      _store.loadMessages(conversationId);

  @override
  Future<ChatMessage> analyze({
    required String conversationId,
    required Uint8List imageBytes,
    required String prompt,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final imagePath = await _persistImage(imageBytes);
      final question = prompt.trim().isEmpty
          ? 'What do you see in this image?'
          : prompt.trim();

      await _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.user,
        content: question,
        imagePath: imagePath,
      );

      final response = await _companion.respondToImage(
        imageBytes: imageBytes,
        instruction: question,
        mimeType: mimeType,
      );

      return _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.assistant,
        content: response.text,
        emotion: response.emotion,
      );
    } on AppException catch (e) {
      throw e is ServerException
          ? ServerFailure(e.message)
          : UnknownFailure(e.message);
    } catch (e) {
      throw ServerFailure('Image analysis failed: $e');
    }
  }

  Future<String> _persistImage(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/vision');
    if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);
    final file = File('${imagesDir.path}/${_uuid.v4()}.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
