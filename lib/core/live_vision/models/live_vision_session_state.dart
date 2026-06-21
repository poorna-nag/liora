/// Lifecycle of a single Live Vision session, emitted by [VisionSessionManager]
/// and mapped to bloc state. Surface-agnostic: a future AR / glasses / desktop
/// front-end can consume the same stream without a Flutter bloc.
enum LiveVisionSessionState {
  /// Nothing running yet.
  idle,

  /// Acquiring permissions + initializing the camera controller.
  initializing,

  /// Camera is live; the frame scheduler is capturing and analyzing.
  observing,

  /// The companion is speaking; capture is paused to free the audio route.
  speaking,

  /// Listening to the user (STT). Mutually exclusive with [speaking].
  listening,

  /// Temporarily paused (backgrounded, low battery throttle, user paused).
  paused,

  /// A non-recoverable error stopped the session.
  error,
}
