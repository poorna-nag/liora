import 'dart:convert';

import '../../../../core/live_vision/models/scene_observation.dart';
import '../../../emotion/data/models/emotion.dart';

/// Builds the per-frame instruction and parses the model's JSON reply back into
/// a [SceneObservation].
///
/// The companion engine ([CompanionManager.respondToImage]) returns prose, so to
/// get the structured data overlays need WITHOUT modifying the engine, we ask —
/// in the instruction — for a compact JSON object and parse it here. The
/// instruction is the only knob we shape; persona/memory are still injected by
/// the engine's system prompt.
class ObservationParser {
  const ObservationParser._();

  /// The JSON contract requested from the model.
  static const String _contract = '''
You are observing a LIVE camera feed for a friend, moment to moment, like a person standing beside them looking at the same thing. Be warm, natural and brief. Do NOT behave like an object detector or read text aloud unless asked.

Reply with ONLY a compact JSON object, no markdown, no prose outside JSON, using exactly this schema:
{
  "scene": "kitchen|office|bedroom|living_room|bathroom|restaurant|garden|classroom|street|store|vehicle|unknown",
  "speech": "<one or two natural, friendly sentences to say out loud now. Under 25 words. Do NOT repeat anything in PRIOR SCENE CONTEXT. If nothing new is worth mentioning, return an empty string.>",
  "new_objects": ["<objects newly visible vs the prior context>"],
  "changes": ["<notable changes vs the prior context, e.g. 'desk moved left'>"],
  "guidance": { "direction": "left|right|up|down|closer|farther|none", "reason": "<short reason, e.g. 'to see the window'>" },
  "suggestion": "<one optional actionable tip, else empty string>",
  "highlight": null,
  "confidence": 0.0
}
"highlight", when present, is { "x":0.0, "y":0.0, "w":0.0, "h":0.0, "label":"" } with coordinates normalized 0..1 relative to the frame; use null when unsure.
If the frame is unclear or dark, set scene to "unknown", guidance.direction to "none", and in speech gently ask the user to improve the lighting or angle.''';

  /// Assembles the full instruction: the persona-neutral contract, the prior
  /// scene summary (so the AI doesn't repeat itself), and any pending user
  /// question folded into the same single call.
  static String buildInstruction({
    required String sceneSummary,
    String? userQuestion,
    String? coachDirective,
  }) {
    final buffer = StringBuffer(_contract);
    final directive = coachDirective?.trim();
    if (directive != null && directive.isNotEmpty) {
      buffer.write('\n\n');
      buffer.write(directive);
    }
    if (sceneSummary.trim().isNotEmpty) {
      buffer.write('\n\n');
      buffer.write(sceneSummary.trim());
    }
    final q = userQuestion?.trim();
    if (q != null && q.isNotEmpty) {
      buffer.write('\n\nThe user just asked: "$q" '
          'Answer it using what you can see, and put the answer in "speech".');
    }
    return buffer.toString();
  }

  /// Parses [raw] model text into a [SceneObservation]. Tolerates code fences
  /// and surrounding prose (mirrors GeminiService._parseStructured). Falls back
  /// to treating the whole text as [speech] if no JSON object is found, and to
  /// [SceneObservation.empty] if even that is empty.
  static SceneObservation parse(String raw, {required Emotion emotion}) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceAll(RegExp(r'```[a-zA-Z]*'), '').replaceAll('```', '').trim();
    }
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end > start) {
      try {
        final map = jsonDecode(s.substring(start, end + 1)) as Map<String, dynamic>;
        return _fromMap(map, emotion);
      } catch (_) {
        // Fall through to plain-text handling.
      }
    }
    final fallbackSpeech = raw.trim();
    if (fallbackSpeech.isEmpty) return SceneObservation.empty;
    return SceneObservation(speech: fallbackSpeech, emotion: emotion, confidence: 0.5);
  }

  static SceneObservation _fromMap(Map<String, dynamic> map, Emotion emotion) {
    return SceneObservation(
      scene: sceneTypeFromKey(map['scene']?.toString()),
      speech: (map['speech'] ?? '').toString().trim(),
      newObjects: _stringList(map['new_objects']),
      changes: _stringList(map['changes']),
      guidance: _guidance(map['guidance']),
      suggestion: (map['suggestion'] ?? '').toString().trim(),
      highlight: _highlight(map['highlight']),
      confidence: _toDouble(map['confidence']),
      emotion: emotion,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static GuidanceHint _guidance(dynamic value) {
    if (value is Map) {
      return GuidanceHint(
        direction: guidanceDirectionFromKey(value['direction']?.toString()),
        reason: (value['reason'] ?? '').toString().trim(),
      );
    }
    return GuidanceHint.none;
  }

  static HighlightRect? _highlight(dynamic value) {
    if (value is Map) {
      final x = _toDouble(value['x']);
      final y = _toDouble(value['y']);
      final w = _toDouble(value['w']);
      final h = _toDouble(value['h']);
      if (w <= 0 || h <= 0) return null;
      return HighlightRect(
        x: x.clamp(0.0, 1.0),
        y: y.clamp(0.0, 1.0),
        w: w.clamp(0.0, 1.0),
        h: h.clamp(0.0, 1.0),
        label: (value['label'] ?? '').toString().trim(),
      );
    }
    return null;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
