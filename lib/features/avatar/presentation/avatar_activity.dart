/// What the companion avatar is *doing* right now. This is orthogonal to the
/// [Emotion] it is expressing: a companion can be `talking` while `happy`, or
/// `thinking` while `concerned`. Drives which animation loops are active.
enum AvatarActivity {
  /// Resting. Still performs subtle breathing, blinking and head sway — the
  /// avatar is never completely static.
  idle,

  /// The user is speaking / the mic is open (gentle attentive nod).
  listening,

  /// The companion is composing a reply (looks up, thought dots).
  thinking,

  /// The companion is speaking (lips move in sync with speech).
  talking,

  /// A one-off greeting wave.
  waving,
}
