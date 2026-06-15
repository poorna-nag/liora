import 'package:equatable/equatable.dart';

/// The outcome of a single translation (not persisted directly; the underlying
/// conversation is stored via the shared conversation store).
class TranslationResult extends Equatable {
  final String sourceText;
  final String translatedText;
  final String sourceLanguageName;
  final String targetLanguageName;

  const TranslationResult({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguageName,
    required this.targetLanguageName,
  });

  @override
  List<Object?> get props =>
      [sourceText, translatedText, sourceLanguageName, targetLanguageName];
}
