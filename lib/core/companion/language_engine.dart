/// Governs the language the companion speaks in — supports a persisted default
/// plus runtime switching without restarting conversations. Detection is kept
/// deliberately light (the Gemini model handles understanding mixed-language
/// input); this engine's job is to *steer the output language*.
class LanguageEngine {
  /// Runtime override set when the user switches language mid-conversation.
  String? _override;

  /// Switch the active output language at runtime (BCP-47 code, e.g. 'es').
  void setLanguage(String? code) => _override = code;

  String? get current => _override;

  /// Builds the system-prompt instruction that forces the reply language.
  /// Returns null for English/no preference (the model's default).
  String? instructionFor(String? languageCode) {
    final code = (languageCode ?? _override)?.trim().toLowerCase();
    if (code == null || code.isEmpty || code.startsWith('en')) return null;
    return 'Always respond in ${nameFor(code)} ($code), regardless of the '
        'language the user writes in, unless they explicitly ask otherwise.';
  }

  /// Human-readable name for a small set of common languages (extend freely).
  String nameFor(String code) {
    switch (code.split('-').first) {
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'hi':
        return 'Hindi';
      case 'ja':
        return 'Japanese';
      case 'zh':
        return 'Chinese';
      case 'ar':
        return 'Arabic';
      case 'pt':
        return 'Portuguese';
      case 'ru':
        return 'Russian';
      case 'it':
        return 'Italian';
      default:
        return code;
    }
  }
}
