part of 'live_vision_bloc.dart';

enum LiveVisionStatus { initial, initializing, active, paused, error }

class LiveVisionState extends Equatable {
  final LiveVisionStatus status;
  final LiveVisionSessionState sessionState;

  /// Most recent parsed observation (drives latest scene info).
  final SceneObservation? latest;

  /// Overlays currently to render.
  final List<OverlaySpec> overlays;

  /// Whether always-listening voice input is on.
  final bool voiceEnabled;

  /// Active lifestyle-coach focus (Phase 8).
  final CoachMode mode;

  /// Transient user-facing notice (snackbar). [noticeToken] increments on each
  /// new notice so identical messages still notify listeners.
  final String? notice;
  final int noticeToken;

  const LiveVisionState({
    this.status = LiveVisionStatus.initial,
    this.sessionState = LiveVisionSessionState.idle,
    this.latest,
    this.overlays = const [],
    this.voiceEnabled = false,
    this.mode = CoachMode.general,
    this.notice,
    this.noticeToken = 0,
  });

  LiveVisionState copyWith({
    LiveVisionStatus? status,
    LiveVisionSessionState? sessionState,
    SceneObservation? latest,
    List<OverlaySpec>? overlays,
    bool? voiceEnabled,
    CoachMode? mode,
    String? notice,
  }) {
    return LiveVisionState(
      status: status ?? this.status,
      sessionState: sessionState ?? this.sessionState,
      latest: latest ?? this.latest,
      overlays: overlays ?? this.overlays,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      mode: mode ?? this.mode,
      notice: notice ?? this.notice,
      noticeToken: notice != null ? noticeToken + 1 : noticeToken,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sessionState,
        latest,
        overlays,
        voiceEnabled,
        mode,
        notice,
        noticeToken,
      ];
}
