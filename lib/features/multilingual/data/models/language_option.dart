import 'package:equatable/equatable.dart';

/// A selectable conversation language.
class LanguageOption extends Equatable {
  final String code; // e.g. 'es'
  final String name; // e.g. 'Spanish'
  final String nativeName; // e.g. 'Español'

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  @override
  List<Object?> get props => [code, name, nativeName];

  /// Languages supported across multilingual chat and translation.
  static const List<LanguageOption> supported = [
    LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
    LanguageOption(code: 'es', name: 'Spanish', nativeName: 'Español'),
    LanguageOption(code: 'fr', name: 'French', nativeName: 'Français'),
    LanguageOption(code: 'de', name: 'German', nativeName: 'Deutsch'),
    LanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    LanguageOption(code: 'zh', name: 'Chinese', nativeName: '中文'),
    LanguageOption(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    LanguageOption(code: 'ja', name: 'Japanese', nativeName: '日本語'),
  ];

  static LanguageOption byCode(String code) => supported.firstWhere(
        (l) => l.code == code,
        orElse: () => supported.first,
      );
}
