part of 'live_vision_bloc.dart';

sealed class LiveVisionEvent extends Equatable {
  const LiveVisionEvent();

  @override
  List<Object?> get props => [];
}

/// Start the session (acquire camera/mic, begin observing).
class LiveVisionStarted extends LiveVisionEvent {
  const LiveVisionStarted();
}

/// Temporarily pause observing (and listening).
class LiveVisionPaused extends LiveVisionEvent {
  const LiveVisionPaused();
}

/// Resume after a pause.
class LiveVisionResumed extends LiveVisionEvent {
  const LiveVisionResumed();
}

/// Toggle always-listening voice input.
class LiveVisionVoiceToggled extends LiveVisionEvent {
  const LiveVisionVoiceToggled();
}

/// Fold a (typed) question into the next frame's instruction.
class LiveVisionQuestionAsked extends LiveVisionEvent {
  final String text;
  const LiveVisionQuestionAsked(this.text);

  @override
  List<Object?> get props => [text];
}

/// Switch the lifestyle-coach focus (Phase 8).
class LiveVisionModeChanged extends LiveVisionEvent {
  final CoachMode mode;
  const LiveVisionModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Explicitly save the current frame to Vision history.
class LiveVisionSnapshotRequested extends LiveVisionEvent {
  const LiveVisionSnapshotRequested();
}

// --- Internal events bridged from the session manager's streams ----------

class LiveVisionObservationReceived extends LiveVisionEvent {
  final SceneObservation observation;
  const LiveVisionObservationReceived(this.observation);

  @override
  List<Object?> get props => [observation];
}

class LiveVisionSessionStateChanged extends LiveVisionEvent {
  final LiveVisionSessionState sessionState;
  const LiveVisionSessionStateChanged(this.sessionState);

  @override
  List<Object?> get props => [sessionState];
}

class LiveVisionNoticeReceived extends LiveVisionEvent {
  final String message;
  const LiveVisionNoticeReceived(this.message);

  @override
  List<Object?> get props => [message];
}
