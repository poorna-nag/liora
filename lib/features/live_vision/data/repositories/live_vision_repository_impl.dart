import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/companion/companion_manager.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/live_vision/models/scene_observation.dart';
import '../../../../core/storage/conversation_store.dart';
import '../../../chat/data/models/chat_role.dart';
import '../../../history/data/models/conversation.dart';
import '../models/observation_parser.dart';
import 'live_vision_repository.dart';

/// Routes live frames through [CompanionManager.respondToImage] (so persona,
/// memory, emotion and relationship all still apply) and parses the reply into
/// a [SceneObservation]. By default it persists nothing — frames are transient.
class LiveVisionRepositoryImpl implements LiveVisionRepository {
  final CompanionManager _companion;
  final ConversationStore _store;
  final _uuid = const Uuid();

  LiveVisionRepositoryImpl(this._companion, this._store);

  @override
  Future<SceneObservation> analyzeFrame({
    required Uint8List imageBytes,
    required String sceneSummary,
    String? userQuestion,
    String? coachDirective,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final instruction = ObservationParser.buildInstruction(
        sceneSummary: sceneSummary,
        userQuestion: userQuestion,
        coachDirective: coachDirective,
      );

      // speak: false — we parse the JSON first, then speak only the `speech`
      // field, so the companion never reads raw JSON aloud.
      final response = await _companion.respondToImage(
        imageBytes: imageBytes,
        instruction: instruction,
        mimeType: mimeType,
        speak: false,
      );

      return ObservationParser.parse(response.text, emotion: response.emotion);
    } on AppException catch (e) {
      throw e is ServerException
          ? ServerFailure(e.message)
          : UnknownFailure(e.message);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Live vision analysis failed: $e');
    }
  }

  @override
  Future<void> saveSnapshot({
    required Uint8List imageBytes,
    required String note,
  }) async {
    try {
      final imagePath = await _persistImage(imageBytes);
      final conversation =
          await _store.createConversation(kind: ConversationKind.vision);
      await _store.addMessage(
        conversationId: conversation.id,
        role: ChatRole.user,
        content: 'Saved from Live Vision',
        imagePath: imagePath,
      );
      if (note.trim().isNotEmpty) {
        await _store.addMessage(
          conversationId: conversation.id,
          role: ChatRole.assistant,
          content: note.trim(),
        );
      }
    } on AppException catch (e) {
      throw CacheFailure(e.message);
    } catch (e) {
      throw CacheFailure('Could not save snapshot: $e');
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
