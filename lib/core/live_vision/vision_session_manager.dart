import 'dart:async';
import 'dart:typed_data';

import 'package:battery_plus/battery_plus.dart';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/emotion/data/models/emotion.dart';
import '../../features/live_vision/data/repositories/live_vision_repository.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../companion/companion_manager.dart';
import '../companion/speech_engine.dart';
import '../error/failures.dart';
import '../services/camera_service.dart';
import '../services/permission_service.dart';
import '../services/speech_service.dart';
import 'frame_scheduler.dart';
import 'frame_processor.dart';
import 'models/coach_mode.dart';
import 'models/frame_analysis.dart';
import 'models/live_vision_session_state.dart';
import 'models/scene_observation.dart';
import 'scene_memory_manager.dart';

/// The brain of Live Vision and the single stateful owner of a session. It wires
/// the camera, the [FrameScheduler], the [SceneMemoryManager] and the analyze →
/// speak loop together, and exposes plain [Stream]s the UI subscribes to.
///
/// Deliberately surface-agnostic: it knows nothing about Flutter widgets or the
/// bloc, so a future AR / glasses / desktop front-end can drive it directly.
class VisionSessionManager {
  final CameraService _camera;
  final CompanionManager _companion;
  final SpeechEngine _speech;
  final SpeechService _stt;
  final PermissionService _permissions;
  final LiveVisionRepository _repository;
  final FrameProcessor _processor;
  final SettingsRepository _settings;
  final Battery _battery;
  final Connectivity _connectivity;

  VisionSessionManager(
    this._camera,
    this._companion,
    this._speech,
    this._stt,
    this._permissions,
    this._repository,
    this._processor,
    this._settings,
    this._battery,
    this._connectivity,
  );

  // --- Streams the UI listens to -------------------------------------------
  final _observations = StreamController<SceneObservation>.broadcast();
  final _states = StreamController<LiveVisionSessionState>.broadcast();
  final _notices = StreamController<String>.broadcast();

  Stream<SceneObservation> get observations => _observations.stream;
  Stream<LiveVisionSessionState> get states => _states.stream;

  /// Transient, non-blocking user-facing notices (e.g. "snapshot saved").
  Stream<String> get notices => _notices.stream;

  CameraController? _controller;
  CameraController? get controller => _controller;

  late final SceneMemoryManager _sceneMemory = SceneMemoryManager();
  FrameScheduler? _scheduler;

  LiveVisionSessionState _state = LiveVisionSessionState.idle;
  LiveVisionSessionState get state => _state;

  bool _voiceEnabled = true;
  bool get voiceEnabled => _voiceEnabled;
  bool _micAvailable = false;

  CoachMode _mode = CoachMode.general;
  CoachMode get mode => _mode;
  final _modes = StreamController<CoachMode>.broadcast();
  Stream<CoachMode> get modes => _modes.stream;

  String? _pendingQuestion;
  bool _speaking = false;
  bool _disposed = false;
  int _consecutiveFailures = 0;
  bool _batteryThrottled = false;
  Uint8List? _lastFrame;
  Timer? _listenWatchdog;

  static const _baseInterval = Duration(milliseconds: 2500);
  static const _throttledInterval = Duration(milliseconds: 6000);

  // --- Lifecycle -----------------------------------------------------------

  Future<void> startSession() async {
    if (_state != LiveVisionSessionState.idle &&
        _state != LiveVisionSessionState.error) {
      return;
    }
    _setState(LiveVisionSessionState.initializing);

    final cameraGranted = await _permissions.requestCamera();
    if (!cameraGranted) {
      _fail('I need camera access to see what you see. '
          'You can enable it in Settings, then come back.');
      return;
    }

    try {
      _controller = await _camera.createController(
        preset: ResolutionPreset.medium,
      );
    } catch (e) {
      _fail("I couldn't start the camera — let's try again in a moment.");
      return;
    }

    // Voice is best-effort: if the mic is denied, we keep observing silently.
    _micAvailable = await _permissions.requestSpeech();
    if (!_micAvailable) {
      _voiceEnabled = false;
      _emitNotice("Mic access is off, so I'll just observe for now.");
    }

    _scheduler = FrameScheduler(
      captureRaw: _captureRaw,
      processFrame: _processor.process,
      onFrameAccepted: _onFrameAccepted,
      onFrameSkipped: _onFrameSkipped,
    );

    _setState(LiveVisionSessionState.observing);
    await _speakGreeting();
    _scheduler!.start();
    _startListenWatchdog();
  }

  Future<void> pause() async {
    if (_state == LiveVisionSessionState.idle ||
        _state == LiveVisionSessionState.error) {
      return;
    }
    _scheduler?.pause();
    await _stopListening();
    _setState(LiveVisionSessionState.paused);
  }

  Future<void> resume() async {
    if (_state != LiveVisionSessionState.paused) return;
    _scheduler?.resume();
    _setState(LiveVisionSessionState.observing);
  }

  /// Folds a spoken/typed question into the next frame's instruction.
  void askQuestion(String text) {
    final q = text.trim();
    if (q.isNotEmpty) _pendingQuestion = q;
  }

  /// Switch the lifestyle-coach focus (Phase 8). Takes effect on the next frame
  /// and the companion acknowledges the change out loud.
  void setMode(CoachMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    if (!_modes.isClosed) _modes.add(mode);
    if (mode != CoachMode.general &&
        _state == LiveVisionSessionState.observing) {
      _say("Okay, ${mode.label} mode — let's take a look.");
    }
  }

  void setVoiceEnabled(bool enabled) {
    if (enabled && !_micAvailable) return;
    _voiceEnabled = enabled;
    if (!enabled) {
      _stopListening();
    }
  }

  Future<void> saveSnapshot() async {
    final frame = _lastFrame;
    if (frame == null) {
      _emitNotice('No frame to save yet — give me a second.');
      return;
    }
    try {
      await _repository.saveSnapshot(
        imageBytes: frame,
        note: _sceneMemory.memory.mentionedPoints.isNotEmpty
            ? _sceneMemory.memory.mentionedPoints.last
            : '',
      );
      _emitNotice('Saved this view to your Vision history.');
    } on Failure catch (f) {
      _emitNotice(f.message);
    }
  }

  Future<void> endSession() async {
    if (_disposed) return;
    _disposed = true;
    _listenWatchdog?.cancel();
    _scheduler?.stop();
    await _stopListening();
    await _companion.stopSpeaking();
    _sceneMemory.clear();
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
    _lastFrame = null;
    if (!_states.isClosed) _setState(LiveVisionSessionState.idle);
    await _observations.close();
    await _states.close();
    await _notices.close();
    await _modes.close();
  }

  // --- Capture + analyze loop ----------------------------------------------

  Future<Uint8List?> _captureRaw() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    if (_speaking || _state != LiveVisionSessionState.observing) return null;
    try {
      return await _camera.captureFromController(controller);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onFrameAccepted(FrameAnalysis analysis) async {
    _lastFrame = analysis.compressed;

    // Offline check first — gives a friendlier message than a raw failure.
    if (await _isOffline()) {
      _consecutiveFailures++;
      if (_consecutiveFailures == 1) {
        await _say("Looks like we're offline — I'll keep watching and pick "
            'back up when we reconnect.');
      }
      return;
    }

    await _maybeThrottleForBattery();

    try {
      final observation = await _repository
          .analyzeFrame(
            imageBytes: analysis.compressed,
            sceneSummary: _sceneMemory.buildSummary(),
            userQuestion: _pendingQuestion,
            coachDirective: _mode.directive,
          )
          .timeout(const Duration(seconds: 12));

      _consecutiveFailures = 0;
      _pendingQuestion = null;

      _sceneMemory.ingest(observation);
      if (!_observations.isClosed) _observations.add(observation);

      // Speak only fresh, non-repetitive lines (continuous-conversation rule).
      if (observation.hasSpeech &&
          observation.confidence >= 0.35 &&
          !_sceneMemory.isRepeat(observation.speech)) {
        await _say(observation.speech, emotion: observation.emotion);
      }
    } on TimeoutException {
      _backOff();
    } on Failure {
      _consecutiveFailures++;
      if (_consecutiveFailures == 3) {
        await _say("I'm having a little trouble seeing clearly right now — "
            'give me a sec.');
      }
      _backOff();
    }
  }

  void _onFrameSkipped(FrameSkipReason reason) {
    if (reason == FrameSkipReason.blurry &&
        _scheduler != null &&
        _scheduler!.consecutiveBlur == _scheduler!.config.maxConsecutiveBlur) {
      _say("It's a little dark or blurry — a bit more light or holding steady "
          'would help me see.');
    }
  }

  // --- Speech --------------------------------------------------------------

  Future<void> _speakGreeting() async {
    final c = _companion.activeCompanion;
    await _say(
      "${c.name} here — let's take a look around together. "
      'Point me at anything you like.',
    );
  }

  /// Speaks [text] in the companion's voice + emotion prosody, pausing capture
  /// and listening for the duration so the audio route is free.
  Future<void> _say(String text, {Emotion emotion = Emotion.neutral}) async {
    if (_disposed || text.trim().isEmpty) return;
    _speaking = true;
    _scheduler?.pause();
    await _stopListening();
    _setState(LiveVisionSessionState.speaking);

    final c = _companion.activeCompanion;
    final pitch = (c.voicePitch + emotion.pitchDelta).clamp(0.5, 2.0);
    final rate = (c.voiceRate + emotion.rateDelta).clamp(0.1, 1.0);
    try {
      // awaitSpeakCompletion is enabled, so this resolves when speech finishes.
      await _speech.speakText(
        text,
        languageCode: c.voiceLocale,
        rate: rate.toDouble(),
        pitch: pitch.toDouble(),
      );
    } catch (_) {
      // Speech failure must not break the observation loop.
    }

    _speaking = false;
    if (_disposed) return;
    if (_state == LiveVisionSessionState.speaking) {
      _setState(LiveVisionSessionState.observing);
      _scheduler?.resume();
    }
  }

  // --- Voice (always-listening) --------------------------------------------

  void _startListenWatchdog() {
    _listenWatchdog?.cancel();
    _listenWatchdog = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _ensureListening(),
    );
  }

  Future<void> _ensureListening() async {
    if (_disposed ||
        !_voiceEnabled ||
        !_micAvailable ||
        _speaking ||
        _state != LiveVisionSessionState.observing) {
      return;
    }
    if (_stt.isListening) return;
    try {
      await _stt.listen(
        localeId: _sttLocale(),
        onResult: (transcript, isFinal) {
          if (isFinal) {
            final q = transcript.trim();
            if (q.isNotEmpty) askQuestion(q);
          }
        },
      );
    } catch (_) {
      // Recogniser hiccup — the watchdog will retry on the next tick.
    }
  }

  Future<void> _stopListening() async {
    if (_stt.isListening) {
      await _stt.stop();
    }
  }

  // --- Resilience helpers --------------------------------------------------

  Future<bool> _isOffline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.isEmpty || result.every((r) => r == ConnectivityResult.none);
    } catch (_) {
      return false; // If we can't tell, let the request try.
    }
  }

  Future<void> _maybeThrottleForBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final battState = await _battery.batteryState;
      final low = level <= 15 && battState != BatteryState.charging;
      if (low && !_batteryThrottled) {
        _batteryThrottled = true;
        _setInterval(_throttledInterval);
        await _say("Your battery's getting low, so I'll look a little less "
            'often to save power.');
      } else if (!low && _batteryThrottled) {
        _batteryThrottled = false;
        _setInterval(_baseInterval);
      }
    } catch (_) {
      // Battery info unavailable on some platforms — ignore.
    }
  }

  void _backOff() {
    if (_batteryThrottled) return; // already slowed
    _setInterval(const Duration(milliseconds: 4000));
  }

  void _setInterval(Duration interval) {
    final scheduler = _scheduler;
    if (scheduler == null) return;
    scheduler.config = scheduler.config.copyWith(captureInterval: interval);
    scheduler.restartTimer();
  }

  // --- small utils ---------------------------------------------------------

  void _setState(LiveVisionSessionState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  void _fail(String message) {
    _setState(LiveVisionSessionState.error);
    _emitNotice(message);
  }

  void _emitNotice(String message) {
    if (!_notices.isClosed) _notices.add(message);
  }

  String _sttLocale() {
    final code = _settings.load().languageCode;
    return _localeMap[code] ?? 'en_US';
  }

  static const _localeMap = {
    'en': 'en_US',
    'es': 'es_ES',
    'fr': 'fr_FR',
    'de': 'de_DE',
    'hi': 'hi_IN',
    'zh': 'zh_CN',
    'ar': 'ar_SA',
    'ja': 'ja_JP',
  };
}
