/// Phase 7 — AR tuning constants in one place.
class ArConstants {
  ArConstants._();

  /// Bundled model the AR scene places. Drop your own GLB here (see the README
  /// in assets/models/) and it will be used automatically; otherwise the scene
  /// falls back to [fallbackModelUrl].
  static const String modelAssetPath = 'assets/models/companion.glb';

  /// Filename used when the bundled asset is copied into the app's documents
  /// folder (the plugin can only load local GLBs from there, not from the
  /// Flutter asset bundle directly).
  static const String localModelFileName = 'companion.glb';

  /// Public, offline-unavailable fallback model used when no bundled asset is
  /// present — a small, known-good glTF-binary sample.
  static const String fallbackModelUrl =
      'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb';

  /// Initial uniform scale applied to a freshly placed model (metres).
  static const double initialScale = 0.2;

  /// How long to wait for the AR view to come up before assuming the device
  /// can't run AR and showing the friendly unsupported screen.
  static const Duration initTimeout = Duration(seconds: 8);
}
