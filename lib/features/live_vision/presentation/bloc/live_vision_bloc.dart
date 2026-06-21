import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/live_vision/models/coach_mode.dart';
import '../../../../core/live_vision/models/live_vision_session_state.dart';
import '../../../../core/live_vision/models/scene_observation.dart';
import '../../../../core/live_vision/vision_session_manager.dart';
import '../overlay/models/overlay_spec.dart';
import '../overlay/overlay_manager.dart';

part 'live_vision_event.dart';
part 'live_vision_state.dart';

/// Thin presentation layer over [VisionSessionManager]. It forwards UI intents
/// to the manager and re-emits the manager's streams as bloc state, deriving
/// overlays via [OverlayManager]. It owns no timers, camera or isolates.
class LiveVisionBloc extends Bloc<LiveVisionEvent, LiveVisionState> {
  final VisionSessionManager _session;
  final OverlayManager _overlays;

  StreamSubscription<SceneObservation>? _obsSub;
  StreamSubscription<LiveVisionSessionState>? _stateSub;
  StreamSubscription<String>? _noticeSub;

  /// The live camera controller, available once the session has initialized.
  /// Exposed for the preview widget only; all control flows through events.
  CameraController? get controller => _session.controller;

  LiveVisionBloc(this._session, {OverlayManager overlays = const OverlayManager()})
      : _overlays = overlays,
        super(const LiveVisionState()) {
    on<LiveVisionStarted>(_onStarted);
    on<LiveVisionPaused>(_onPaused);
    on<LiveVisionResumed>(_onResumed);
    on<LiveVisionVoiceToggled>(_onVoiceToggled);
    on<LiveVisionQuestionAsked>(_onQuestionAsked);
    on<LiveVisionModeChanged>(_onModeChanged);
    on<LiveVisionSnapshotRequested>(_onSnapshotRequested);
    on<LiveVisionObservationReceived>(_onObservationReceived);
    on<LiveVisionSessionStateChanged>(_onSessionStateChanged);
    on<LiveVisionNoticeReceived>(_onNoticeReceived);
  }

  void _onModeChanged(
      LiveVisionModeChanged event, Emitter<LiveVisionState> emit) {
    _session.setMode(event.mode);
    emit(state.copyWith(mode: event.mode));
  }

  Future<void> _onStarted(
      LiveVisionStarted event, Emitter<LiveVisionState> emit) async {
    _obsSub ??= _session.observations
        .listen((o) => add(LiveVisionObservationReceived(o)));
    _stateSub ??= _session.states
        .listen((s) => add(LiveVisionSessionStateChanged(s)));
    _noticeSub ??=
        _session.notices.listen((n) => add(LiveVisionNoticeReceived(n)));
    emit(state.copyWith(voiceEnabled: _session.voiceEnabled));
    await _session.startSession();
  }

  Future<void> _onPaused(
      LiveVisionPaused event, Emitter<LiveVisionState> emit) async {
    await _session.pause();
  }

  Future<void> _onResumed(
      LiveVisionResumed event, Emitter<LiveVisionState> emit) async {
    await _session.resume();
  }

  void _onVoiceToggled(
      LiveVisionVoiceToggled event, Emitter<LiveVisionState> emit) {
    final enabled = !state.voiceEnabled;
    _session.setVoiceEnabled(enabled);
    emit(state.copyWith(voiceEnabled: _session.voiceEnabled));
  }

  void _onQuestionAsked(
      LiveVisionQuestionAsked event, Emitter<LiveVisionState> emit) {
    _session.askQuestion(event.text);
  }

  Future<void> _onSnapshotRequested(
      LiveVisionSnapshotRequested event, Emitter<LiveVisionState> emit) async {
    await _session.saveSnapshot();
  }

  void _onObservationReceived(
      LiveVisionObservationReceived event, Emitter<LiveVisionState> emit) {
    emit(state.copyWith(
      latest: event.observation,
      overlays: _overlays.map(event.observation),
    ));
  }

  void _onSessionStateChanged(
      LiveVisionSessionStateChanged event, Emitter<LiveVisionState> emit) {
    emit(state.copyWith(
      sessionState: event.sessionState,
      status: _statusFor(event.sessionState),
    ));
  }

  void _onNoticeReceived(
      LiveVisionNoticeReceived event, Emitter<LiveVisionState> emit) {
    emit(state.copyWith(notice: event.message));
  }

  LiveVisionStatus _statusFor(LiveVisionSessionState s) {
    switch (s) {
      case LiveVisionSessionState.idle:
        return LiveVisionStatus.initial;
      case LiveVisionSessionState.initializing:
        return LiveVisionStatus.initializing;
      case LiveVisionSessionState.observing:
      case LiveVisionSessionState.speaking:
      case LiveVisionSessionState.listening:
        return LiveVisionStatus.active;
      case LiveVisionSessionState.paused:
        return LiveVisionStatus.paused;
      case LiveVisionSessionState.error:
        return LiveVisionStatus.error;
    }
  }

  @override
  Future<void> close() async {
    await _obsSub?.cancel();
    await _stateSub?.cancel();
    await _noticeSub?.cancel();
    await _session.endSession();
    return super.close();
  }
}
