import 'dart:convert';

import 'memory_service.dart';
import 'gemini_service.dart';

/// Phase 5 — proactive memory. After a user speaks, this quietly asks the model
/// to pull out any *durable* personal facts (goals, routines, work, hobbies,
/// preferences, important people) and stores the new ones via [MemoryService],
/// so the companion can bring them up naturally on later days.
///
/// It runs fire-and-forget and never throws: a failure here must not affect the
/// conversation. It also de-duplicates against what's already remembered so the
/// memory list doesn't fill with near-identical entries.
class MemoryExtractor {
  final GeminiService _gemini;
  final MemoryService _memory;

  MemoryExtractor(this._gemini, this._memory);

  /// Minimum user-message length worth analyzing (skips "ok", "thanks", etc.).
  static const int _minLength = 12;

  /// Cap on how many facts we'll add from a single message.
  static const int _maxPerMessage = 4;

  Future<void> captureFrom(String userText) async {
    final text = userText.trim();
    if (!_gemini.isAvailable || text.length < _minLength) return;

    try {
      final raw = await _gemini.generateOnce(
        systemPrompt:
            'You extract durable, long-term facts about the user from a single '
            'message. Only capture stable information worth remembering for '
            'months: their name, goals, routines, job/studies, hobbies, '
            'preferences, important people, and similar. Ignore transient or '
            'one-off remarks, questions, and small talk. Respond with ONLY a '
            'JSON array of short factual strings (third person, e.g. '
            '"User is learning Flutter"). Return [] if there is nothing '
            'durable.',
        prompt: 'Message:\n$text',
      );

      final facts = _parseFacts(raw);
      if (facts.isEmpty) return;

      final existing = _memory
          .getEntries()
          .map((e) => e.content.toLowerCase())
          .toList();

      var added = 0;
      for (final fact in facts) {
        if (added >= _maxPerMessage) break;
        final normalized = fact.toLowerCase();
        final duplicate = existing.any((e) =>
            e == normalized || e.contains(normalized) || normalized.contains(e));
        if (duplicate) continue;
        await _memory.addEntry(fact);
        existing.add(normalized);
        added++;
      }
    } catch (_) {
      // Best-effort: never disrupt the conversation.
    }
  }

  /// Parses a JSON array of strings out of [raw], tolerating code fences and
  /// surrounding prose (mirrors the app's other lenient JSON parsers).
  List<String> _parseFacts(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceAll(RegExp(r'```[a-zA-Z]*'), '').replaceAll('```', '').trim();
    }
    final start = s.indexOf('[');
    final end = s.lastIndexOf(']');
    if (start == -1 || end <= start) return const [];
    try {
      final decoded = jsonDecode(s.substring(start, end + 1));
      if (decoded is! List) return const [];
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.length > 3)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
