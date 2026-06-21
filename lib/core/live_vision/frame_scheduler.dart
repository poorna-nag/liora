import 'dart:async';
import 'dart:typed_data';

import 'models/frame_analysis.dart';

/// Tunable parameters for the capture loop. Defaults match the V3 plan.
class FrameSchedulerConfig {
  final Duration captureInterval;
  final double blurThreshold;
  final int hashDistanceThreshold;
  final int maxConsecutiveBlur;
  final Duration forceRefreshAfter;

  const FrameSchedulerConfig({
    this.captureInterval = const Duration(milliseconds: 2500),
    this.blurThreshold = 120.0,
    this.hashDistanceThreshold = 8,
    this.maxConsecutiveBlur = 3,
    this.forceRefreshAfter = const Duration(seconds: 20),
  });

  FrameSchedulerConfig copyWith({Duration? captureInterval}) =>
      FrameSchedulerConfig(
        captureInterval: captureInterval ?? this.captureInterval,
        blurThreshold: blurThreshold,
        hashDistanceThreshold: hashDistanceThreshold,
        maxConsecutiveBlur: maxConsecutiveBlur,
        forceRefreshAfter: forceRefreshAfter,
      );
}

/// Why a captured frame was not sent for analysis. Surfaced so the session
/// manager can react (e.g. nudge the user when it's too blurry/dark).
enum FrameSkipReason { blurry, duplicate }

/// Drives the "capture every 2–3s" loop and decides which frames are worth an
/// (expensive) model call. It is a passive utility: it asks the owner to grab a
/// raw frame and to process it, then calls back with an accepted frame or a
/// skip reason. It owns NO camera and NO network — that keeps it trivially
/// testable and reusable across surfaces.
///
/// Responsibilities:
/// * cadence via a periodic timer,
/// * pause/resume (the session manager pauses while the companion speaks),
/// * skip blurry frames (Laplacian variance below threshold),
/// * skip near-duplicate frames (average-hash Hamming distance),
/// * force a refresh after a long stretch of duplicates so the companion never
///   goes permanently silent,
/// * an in-flight guard so a slow model call never overlaps the next tick.
class FrameScheduler {
  FrameSchedulerConfig config;

  /// Grabs a raw JPEG from the camera. Returns null to skip this tick.
  final Future<Uint8List?> Function() captureRaw;

  /// Heavy processing (decode/compress/hash/blur), off the main isolate.
  final Future<FrameAnalysis?> Function(Uint8List raw) processFrame;

  /// Called when a frame is accepted for analysis.
  final void Function(FrameAnalysis analysis) onFrameAccepted;

  /// Called when a frame is captured but intentionally skipped.
  final void Function(FrameSkipReason reason)? onFrameSkipped;

  FrameScheduler({
    required this.captureRaw,
    required this.processFrame,
    required this.onFrameAccepted,
    this.onFrameSkipped,
    FrameSchedulerConfig? config,
  }) : config = config ?? const FrameSchedulerConfig();

  Timer? _timer;
  bool _paused = false;
  bool _inFlight = false;
  int? _lastAcceptedHash;
  int _consecutiveBlur = 0;
  DateTime? _lastAcceptedAt;

  bool get isRunning => _timer != null;
  bool get isPaused => _paused;

  /// Consecutive blurry frames — the session manager uses this to decide when
  /// to coach the user ("it's a bit dark, hold steady").
  int get consecutiveBlur => _consecutiveBlur;

  void start() {
    if (_timer != null) return;
    _paused = false;
    _timer = Timer.periodic(config.captureInterval, (_) => _tick());
  }

  /// Restarts the periodic timer with the current [config] interval. Used when
  /// the session manager backs off the cadence (rate limit / low battery).
  void restartTimer() {
    if (_timer == null) return;
    _timer!.cancel();
    _timer = Timer.periodic(config.captureInterval, (_) => _tick());
  }

  void pause() => _paused = true;

  void resume() => _paused = false;

  void stop() {
    _timer?.cancel();
    _timer = null;
    _paused = false;
    _inFlight = false;
    _lastAcceptedHash = null;
    _consecutiveBlur = 0;
    _lastAcceptedAt = null;
  }

  Future<void> _tick() async {
    if (_paused || _inFlight) return;
    _inFlight = true;
    try {
      final raw = await captureRaw();
      if (raw == null) return;

      final analysis = await processFrame(raw);
      if (analysis == null) return;

      final forceRefresh = _lastAcceptedAt != null &&
          DateTime.now().difference(_lastAcceptedAt!) >= config.forceRefreshAfter;

      // Blur gate (skipped when forcing a refresh so we don't go silent).
      if (!forceRefresh && analysis.blurScore < config.blurThreshold) {
        _consecutiveBlur++;
        onFrameSkipped?.call(FrameSkipReason.blurry);
        return;
      }
      _consecutiveBlur = 0;

      // Duplicate gate.
      final last = _lastAcceptedHash;
      if (!forceRefresh && last != null) {
        final distance =
            FrameAnalysis.hammingDistance(last, analysis.averageHash);
        if (distance < config.hashDistanceThreshold) {
          onFrameSkipped?.call(FrameSkipReason.duplicate);
          return;
        }
      }

      _lastAcceptedHash = analysis.averageHash;
      _lastAcceptedAt = DateTime.now();
      onFrameAccepted(analysis);
    } finally {
      _inFlight = false;
    }
  }
}
