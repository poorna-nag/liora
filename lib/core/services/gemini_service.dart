import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart' hide ServerException;

import '../constants/api_constants.dart';
import '../error/exceptions.dart';

/// A single prior turn of a conversation, used to give the model context.
class AiTurn {
  final bool isUser;
  final String text;
  const AiTurn({required this.isUser, required this.text});
}

/// A reply that carries both the message text and an optional emotion tag the
/// model chose. [emotionKey] is a raw string (e.g. "happy"); the caller maps it
/// to a domain emotion so this core service stays feature-agnostic.
class StructuredReply {
  final String text;
  final String? emotionKey;
  const StructuredReply({required this.text, this.emotionKey});
}

/// Wraps Firebase AI Logic (Gemini). Feature-agnostic: knows nothing about
/// storage, features, or the current user. Repositories compose it with the
/// active personality, memory, and persistence.
class GeminiService {
  /// Whether Firebase (and therefore this service) initialized successfully.
  /// When false, calls fail fast with a clear message instead of crashing.
  bool _available = false;

  void markAvailable(bool value) => _available = value;
  bool get isAvailable => _available;

  GenerativeModel _model({
    required String modelName,
    String? systemPrompt,
  }) {
    return FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction:
          systemPrompt == null ? null : Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        temperature: ApiConstants.defaultTemperature,
        maxOutputTokens: ApiConstants.defaultMaxOutputTokens,
      ),
    );
  }

  void _ensureAvailable() {
    if (!_available) {
      throw const ServerException(
        'AI service is not available. Check your connection and Firebase setup.',
      );
    }
  }

  /// Generates a text reply given a system prompt and prior conversation.
  Future<String> generateReply({
    required String systemPrompt,
    required List<AiTurn> history,
    required String userMessage,
  }) async {
    _ensureAvailable();
    try {
      final model = _model(
        modelName: ApiConstants.chatModel,
        systemPrompt: systemPrompt,
      );
      final chat = model.startChat(
        history: history
            .map((t) => t.isUser
                ? Content.text(t.text)
                : Content.model([TextPart(t.text)]))
            .toList(),
      );
      final response = await chat.sendMessage(Content.text(userMessage));
      return _extractText(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('AI request failed: $e');
    }
  }

  /// Like [generateReply] but expects the model to return a structured
  /// `{"emotion": ..., "message": ...}` JSON object (the caller injects the
  /// protocol into [systemPrompt]). Falls back to treating the whole response
  /// as the message when parsing fails, so callers always get usable text.
  Future<StructuredReply> generateStructuredReply({
    required String systemPrompt,
    required List<AiTurn> history,
    required String userMessage,
  }) async {
    _ensureAvailable();
    try {
      final model = _model(
        modelName: ApiConstants.chatModel,
        systemPrompt: systemPrompt,
      );
      final chat = model.startChat(
        history: history
            .map((t) => t.isUser
                ? Content.text(t.text)
                : Content.model([TextPart(t.text)]))
            .toList(),
      );
      final response = await chat.sendMessage(Content.text(userMessage));
      return _parseStructured(_extractText(response));
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('AI request failed: $e');
    }
  }

  /// Parses a `{"emotion","message"}` object out of [raw], tolerating code
  /// fences and surrounding prose. Returns the raw text as the message if no
  /// valid object is found.
  StructuredReply _parseStructured(String raw) {
    var s = raw.trim();
    // Strip ```json ... ``` fences if present.
    if (s.startsWith('```')) {
      s = s.replaceAll(RegExp(r'```[a-zA-Z]*'), '').replaceAll('```', '').trim();
    }
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end > start) {
      final jsonSlice = s.substring(start, end + 1);
      try {
        final map = jsonDecode(jsonSlice) as Map<String, dynamic>;
        final message = (map['message'] ?? map['reply'] ?? map['text'])
            ?.toString()
            .trim();
        final emotion = map['emotion']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return StructuredReply(text: message, emotionKey: emotion);
        }
      } catch (_) {
        // Fall through to plain-text handling.
      }
    }
    return StructuredReply(text: raw.trim());
  }

  /// One-shot generation from a single prompt (no chat history).
  Future<String> generateOnce({
    required String prompt,
    String? systemPrompt,
  }) async {
    _ensureAvailable();
    try {
      final model = _model(
        modelName: ApiConstants.chatModel,
        systemPrompt: systemPrompt,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      return _extractText(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('AI request failed: $e');
    }
  }

  /// Analyzes an image with an accompanying instruction (vision).
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
    String mimeType = 'image/jpeg',
    String? systemPrompt,
  }) async {
    _ensureAvailable();
    try {
      final model = _model(
        modelName: ApiConstants.visionModel,
        systemPrompt: systemPrompt,
      );
      final content = Content.multi([
        TextPart(prompt),
        InlineDataPart(mimeType, imageBytes),
      ]);
      final response = await model.generateContent([content]);
      return _extractText(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Image analysis failed: $e');
    }
  }

  String _extractText(GenerateContentResponse response) {
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw const ServerException('The AI returned an empty response.');
    }
    return text;
  }
}
