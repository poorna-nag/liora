import 'dart:typed_data';

import '../../../chat/data/models/chat_message.dart';
import '../../../history/data/models/conversation.dart';

/// Analyzes images with the assistant and persists the exchange.
abstract class VisionRepository {
  Future<Conversation> start();
  List<ChatMessage> loadMessages(String conversationId);

  /// Persists the captured image + prompt as a user message, runs vision
  /// analysis, persists and returns the assistant's reply.
  Future<ChatMessage> analyze({
    required String conversationId,
    required Uint8List imageBytes,
    required String prompt,
    String mimeType,
  });
}
