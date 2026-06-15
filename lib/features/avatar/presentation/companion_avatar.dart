import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../character/data/models/character_archetype.dart';
import '../../emotion/data/models/emotion.dart';
import 'avatar_activity.dart';
import 'companion_face_painter.dart';

/// A living, vector-drawn companion avatar. It is never completely static:
/// even when [activity] is [AvatarActivity.idle] it breathes, blinks and gently
/// sways. [emotion] morphs the face; [activity] layers behaviour (thinking
/// dots, lip-sync while talking, an attentive nod while listening).
///
/// Asset-free by design, so it works with no art pipeline. The widget boundary
/// is intentionally small ([CharacterArchetype] + [Emotion] + [AvatarActivity])
/// so a Rive/Lottie implementation can replace it later without touching callers.
class AnimatedCompanionAvatar extends StatefulWidget {
  final CharacterArchetype archetype;
  final Emotion emotion;
  final AvatarActivity activity;
  final double size;

  /// Multiplies animation speed (1.0 = default). Wired to settings later.
  final double animationSpeed;

  const AnimatedCompanionAvatar({
    super.key,
    required this.archetype,
    this.emotion = Emotion.calm,
    this.activity = AvatarActivity.idle,
    this.size = 160,
    this.animationSpeed = 1.0,
  });

  @override
  State<AnimatedCompanionAvatar> createState() =>
      _AnimatedCompanionAvatarState();
}

class _AnimatedCompanionAvatarState extends State<AnimatedCompanionAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _sway;
  late final AnimationController _blink;
  late final AnimationController _talk;
  late final AnimationController _think;

  double get _speed => widget.animationSpeed <= 0 ? 1.0 : widget.animationSpeed;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2600 / _speed).round()),
    )..repeat(reverse: true);
    _sway = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (4200 / _speed).round()),
    )..repeat(reverse: true);
    _blink = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (4000 / _speed).round()),
    )..repeat();
    _talk = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (210 / _speed).round()),
    );
    _think = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1200 / _speed).round()),
    );
    _applyActivity();
  }

  @override
  void didUpdateWidget(AnimatedCompanionAvatar old) {
    super.didUpdateWidget(old);
    if (old.activity != widget.activity) _applyActivity();
  }

  void _applyActivity() {
    if (widget.activity == AvatarActivity.talking) {
      _talk.repeat(reverse: true);
    } else {
      _talk
        ..stop()
        ..value = 0;
    }
    if (widget.activity == AvatarActivity.thinking) {
      _think.repeat();
    } else {
      _think
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _sway.dispose();
    _blink.dispose();
    _talk.dispose();
    _think.dispose();
    super.dispose();
  }

  double _blinkAmount() {
    final v = _blink.value;
    // Quick blink at the start of each cycle, eyes open the rest of the time.
    if (v < 0.08) return math.sin(v / 0.08 * math.pi);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([_breath, _sway, _blink, _talk, _think]);
    final isThinking = widget.activity == AvatarActivity.thinking;
    final isListening = widget.activity == AvatarActivity.listening;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          final breath = _breath.value; // 0..1
          final scale = 1 + 0.025 * breath;
          // Listening adds a gentle nod on top of the idle sway.
          final swayAngle = (_sway.value - 0.5) * 0.06 +
              (isListening ? math.sin(_sway.value * math.pi * 2) * 0.02 : 0);
          final bobY = -2.0 * breath +
              (isListening ? math.sin(_sway.value * math.pi * 2) * 2 : 0);
          final mouthOpen =
              widget.activity == AvatarActivity.talking ? _talk.value : 0.0;
          final lookUp = isThinking ? 1.0 : 0.0;

          return Transform.translate(
            offset: Offset(0, bobY),
            child: Transform.rotate(
              angle: swayAngle,
              child: Transform.scale(
                scale: scale,
                child: CustomPaint(
                  painter: CompanionFacePainter(
                    archetype: widget.archetype,
                    emotion: widget.emotion,
                    blink: _blinkAmount(),
                    mouthOpen: mouthOpen,
                    lookUp: lookUp,
                    showThinkDots: isThinking,
                    thinkPhase: _think.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
