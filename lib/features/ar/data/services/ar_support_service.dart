import 'package:flutter/foundation.dart';

/// Phase 7 — best-effort AR capability probe and friendly-message source.
///
/// The plugin has no Dart-level ARCore/ARKit availability API, so true
/// device-support is determined at runtime (the screen falls back to the
/// unsupported view if the AR view never initializes — see [ArBloc]). This
/// service at least rules out platforms that can never run AR (web/desktop) and
/// centralizes the user-facing copy.
class ArSupportService {
  const ArSupportService();

  /// Platforms that could conceivably host ARCore/ARKit. Anything else (web,
  /// desktop) is unsupported up front.
  bool get isPlatformCapable {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get unsupportedMessage =>
      "Augmented Reality isn't available on this device. It needs a phone with "
      'ARCore (Android) or ARKit (iPhone/iPad) support.';

  String get initFailedMessage =>
      "I couldn't start the AR camera. Make sure AR services are installed and "
      'try again.';

  String get hint => 'Point at a flat surface, then tap to place me.';
}
