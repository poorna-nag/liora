import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/memory_service.dart';
import '../../../../core/storage/conversation_store.dart';
import '../../../chat/data/models/chat_message.dart';
import '../../../chat/data/models/chat_role.dart';
import '../../../history/data/models/conversation.dart';
import '../../../personality/data/repositories/personality_repository.dart';
import '../../../settings/data/repositories/settings_repository.dart';
import 'vision_repository.dart';

class VisionRepositoryImpl implements VisionRepository {
  final GeminiService _gemini;
  final ConversationStore _store;
  final PersonalityRepository _personality;
  final SettingsRepository _settings;
  final MemoryService _memory;
  final _uuid = const Uuid();

  VisionRepositoryImpl(
    this._gemini,
    this._store,
    this._personality,
    this._settings,
    this._memory,
  );

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
      final question =
          prompt.trim().isEmpty ? 'What do you see in this image?' : prompt.trim();

      await _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.user,
        content: question,
        imagePath: imagePath,
      );

      final analysis = await _gemini.analyzeImage(
        imageBytes: imageBytes,
        prompt: question,
        mimeType: mimeType,
        systemPrompt: _buildSystemPrompt(),
      );

      return _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.assistant,
        content: analysis,
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

  String _buildSystemPrompt() {
    final settings = _settings.load();
    final personality =
        _personality.getActiveOrDefault(settings.activePersonalityId);
    final buffer = StringBuffer(personality.systemPrompt);
    if (settings.memoryEnabled) {
      final memory = _memory.buildMemoryContext();
      if (memory.isNotEmpty) buffer.write('\n\n$memory');
    }
    return buffer.toString();
  }
}
