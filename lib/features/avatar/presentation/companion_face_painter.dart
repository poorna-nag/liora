import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../character/data/models/character_archetype.dart';
import '../../emotion/data/models/emotion.dart';

/// Per-emotion facial expression parameters. Pure data the painter reads to
/// morph brows, eyes and mouth.
class _Expression {
  final double browLift; // -1 (down) .. 1 (up)
  final double browInnerUp; // 0 .. 1 (sad / worried)
  final double eyeOpen; // multiplier on eye height
  final double mouthCurve; // -1 (frown) .. 1 (smile)
  final double mouthOpen; // 0 .. 1 base openness
  final bool blush;
  final bool smirk; // asymmetric mouth (confident)

  const _Expression({
    this.browLift = 0,
    this.browInnerUp = 0,
    this.eyeOpen = 1,
    this.mouthCurve = 0.1,
    this.mouthOpen = 0,
    this.blush = false,
    this.smirk = false,
  });

  static _Expression of(Emotion e) {
    switch (e) {
      case Emotion.happy:
        return const _Expression(browLift: 0.2, eyeOpen: 0.95, mouthCurve: 0.8);
      case Emotion.excited:
        return const _Expression(
            browLift: 0.5, eyeOpen: 1.2, mouthCurve: 1.0, mouthOpen: 0.3, blush: true);
      case Emotion.thinking:
        return const _Expression(browLift: -0.1, eyeOpen: 0.9, mouthCurve: 0.1);
      case Emotion.sad:
        return const _Expression(
            browInnerUp: 0.9, eyeOpen: 0.8, mouthCurve: -0.7);
      case Emotion.concerned:
        return const _Expression(
            browInnerUp: 0.5, eyeOpen: 0.9, mouthCurve: -0.3);
      case Emotion.laughing:
        return const _Expression(
            browLift: 0.3, eyeOpen: 0.25, mouthCurve: 1.0, mouthOpen: 0.5, blush: true);
      case Emotion.confident:
        return const _Expression(
            browLift: -0.1, eyeOpen: 0.85, mouthCurve: 0.5, smirk: true);
      case Emotion.calm:
        return const _Expression(browLift: 0.1, eyeOpen: 0.9, mouthCurve: 0.4);
      case Emotion.surprised:
        return const _Expression(
            browLift: 0.6, eyeOpen: 1.4, mouthCurve: 0.0, mouthOpen: 0.7);
      case Emotion.neutral:
        return const _Expression(eyeOpen: 1.0, mouthCurve: 0.1);
    }
  }
}

/// Draws a stylised, expressive companion face entirely with vector primitives.
/// Distinct per [CharacterArchetype]; morphs per [Emotion]; animated via the
/// [blink], [mouthOpen] and [lookUp] inputs supplied by the avatar widget.
class CompanionFacePainter extends CustomPainter {
  final CharacterArchetype archetype;
  final Emotion emotion;

  /// 0 = eyes fully open, 1 = fully closed (blink).
  final double blink;

  /// 0 = mouth at rest, 1 = fully open (speech).
  final double mouthOpen;

  /// 0 = looking forward, 1 = looking up (thinking).
  final double lookUp;

  /// Whether to draw the floating "thinking" dots.
  final bool showThinkDots;

  /// 0..1 animation phase for the thinking dots.
  final double thinkPhase;

  CompanionFacePainter({
    required this.archetype,
    required this.emotion,
    required this.blink,
    required this.mouthOpen,
    required this.lookUp,
    required this.showThinkDots,
    required this.thinkPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final expr = _Expression.of(emotion);
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.30;

    _paintGlow(canvas, c, r);
    if (archetype.isRobot) {
      _paintRobotHead(canvas, c, r);
    } else {
      _paintHead(canvas, c, r);
      _paintHair(canvas, c, r);
    }
    _paintEyes(canvas, c, r, expr);
    _paintBrows(canvas, c, r, expr);
    if (expr.blush) _paintBlush(canvas, c, r);
    _paintMouth(canvas, c, r, expr);
    if (archetype.hasBeard) _paintBeard(canvas, c, r);
    if (archetype.hasGlasses) _paintGlasses(canvas, c, r);
    if (showThinkDots) _paintThinkDots(canvas, c, r);
  }

  void _paintGlow(Canvas canvas, Offset c, double r) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          emotion.color.withValues(alpha: 0.30),
          emotion.color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r * 1.9));
    canvas.drawCircle(c, r * 1.9, glow);
  }

  void _paintHead(Canvas canvas, Offset c, double r) {
    final skin = Paint()..color = archetype.skinTone;
    // Slightly oval head.
    final rect = Rect.fromCenter(center: c, width: r * 1.8, height: r * 2.05);
    canvas.drawOval(rect, skin);
    // Ears.
    canvas.drawCircle(Offset(c.dx - r * 0.92, c.dy + r * 0.05), r * 0.16, skin);
    canvas.drawCircle(Offset(c.dx + r * 0.92, c.dy + r * 0.05), r * 0.16, skin);
  }

  void _paintRobotHead(Canvas canvas, Offset c, double r) {
    final chassis = Paint()..color = archetype.skinTone;
    final trim = Paint()
      ..color = archetype.hairColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: r * 1.9, height: r * 1.95),
      Radius.circular(r * 0.45),
    );
    canvas.drawRRect(rrect, chassis);
    canvas.drawRRect(rrect, trim);
    // Antenna.
    final antPaint = Paint()
      ..color = archetype.hairColor
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(c.dx, c.dy - r * 0.98), Offset(c.dx, c.dy - r * 1.35), antPaint);
    canvas.drawCircle(
        Offset(c.dx, c.dy - r * 1.4), r * 0.1, Paint()..color = emotion.color);
    // Side bolts.
    final bolt = Paint()..color = archetype.hairColor;
    canvas.drawCircle(Offset(c.dx - r * 0.98, c.dy), r * 0.1, bolt);
    canvas.drawCircle(Offset(c.dx + r * 0.98, c.dy), r * 0.1, bolt);
  }

  void _paintHair(Canvas canvas, Offset c, double r) {
    final hair = Paint()..color = archetype.hairColor;
    final top = c.dy - r * 0.78;
    switch (archetype) {
      case CharacterArchetype.friendlyMale:
        final path = Path()
          ..moveTo(c.dx - r * 0.9, c.dy - r * 0.2)
          ..quadraticBezierTo(c.dx - r, top - r * 0.5, c.dx, top - r * 0.55)
          ..quadraticBezierTo(c.dx + r, top - r * 0.5, c.dx + r * 0.9, c.dy - r * 0.2)
          ..quadraticBezierTo(c.dx, top + r * 0.15, c.dx - r * 0.9, c.dy - r * 0.2)
          ..close();
        canvas.drawPath(path, hair);
        break;
      case CharacterArchetype.friendlyFemale:
        // Long hair framing the face.
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(c.dx, c.dy - r * 0.15),
                width: r * 2.2,
                height: r * 2.4),
            hair);
        // Re-draw face over hair to keep it as a frame.
        _paintHead(canvas, c, r);
        break;
      case CharacterArchetype.grandpa:
        // Side hair only (balding).
        canvas.drawArc(
            Rect.fromCenter(center: c, width: r * 1.95, height: r * 2.1),
            math.pi * 0.78, math.pi * 0.44, false,
            Paint()
              ..color = archetype.hairColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.22);
        break;
      case CharacterArchetype.grandma:
        // Bun + soft hairline.
        canvas.drawCircle(Offset(c.dx, top - r * 0.2), r * 0.45, hair);
        final path = Path()
          ..moveTo(c.dx - r * 0.92, c.dy - r * 0.1)
          ..quadraticBezierTo(c.dx, top, c.dx + r * 0.92, c.dy - r * 0.1)
          ..quadraticBezierTo(c.dx, top + r * 0.35, c.dx - r * 0.92, c.dy - r * 0.1)
          ..close();
        canvas.drawPath(path, hair);
        break;
      case CharacterArchetype.child:
        // Little tuft.
        canvas.drawCircle(Offset(c.dx, top - r * 0.05), r * 0.5, hair);
        _paintHead(canvas, c, r);
        canvas.drawCircle(Offset(c.dx + r * 0.05, top - r * 0.35), r * 0.14, hair);
        break;
      case CharacterArchetype.anime:
        // Spiky fringe.
        final path = Path()..moveTo(c.dx - r, c.dy - r * 0.2);
        const spikes = 5;
        for (var i = 0; i <= spikes; i++) {
          final x = c.dx - r + (2 * r) * (i / spikes);
          final y = (i.isEven) ? top - r * 0.45 : top + r * 0.05;
          path.lineTo(x, y);
        }
        path
          ..lineTo(c.dx + r, c.dy - r * 0.2)
          ..quadraticBezierTo(c.dx, top + r * 0.1, c.dx - r, c.dy - r * 0.2)
          ..close();
        canvas.drawPath(path, hair);
        break;
      case CharacterArchetype.robot:
        break; // handled by robot head
    }
  }

  Offset get _gaze => Offset(0, -lookUp * 4);

  void _paintEyes(Canvas canvas, Offset c, double r, _Expression expr) {
    final eyeColor = Paint()..color = Colors.white;
    final iris = Paint()..color = const Color(0xFF2A2A35);
    final eyeY = c.dy - r * 0.08;
    final dx = r * 0.42;
    final baseW = r * 0.30 * archetype.eyeScale;
    final baseH = r * 0.36 * archetype.eyeScale * expr.eyeOpen * (1 - blink);

    for (final sign in [-1.0, 1.0]) {
      final center = Offset(c.dx + sign * dx, eyeY);
      if (baseH < r * 0.04) {
        // Effectively closed: draw a happy curved line.
        final p = Paint()
          ..color = const Color(0xFF2A2A35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..strokeCap = StrokeCap.round;
        final path = Path()
          ..moveTo(center.dx - baseW * 0.6, center.dy)
          ..quadraticBezierTo(
              center.dx, center.dy + baseH.clamp(2, r) + r * 0.12,
              center.dx + baseW * 0.6, center.dy);
        canvas.drawPath(path, p);
        continue;
      }
      final eyeRect = Rect.fromCenter(
          center: center, width: baseW, height: baseH.clamp(2, r));
      canvas.drawOval(eyeRect, eyeColor);
      // Iris follows the gaze.
      canvas.drawCircle(center + _gaze, baseW * 0.30, iris);
      // Catchlight.
      canvas.drawCircle(center + _gaze + Offset(-baseW * 0.1, -baseH * 0.12),
          baseW * 0.09, Paint()..color = Colors.white);
    }
  }

  void _paintBrows(Canvas canvas, Offset c, double r, _Expression expr) {
    final p = Paint()
      ..color = archetype.isRobot ? archetype.hairColor : _browColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    final browY = c.dy - r * 0.40 - expr.browLift * r * 0.12;
    final dx = r * 0.42;
    final w = r * 0.26;
    for (final sign in [-1.0, 1.0]) {
      final inner = Offset(
          c.dx + sign * (dx - w * 0.5),
          browY + expr.browInnerUp * -r * 0.10 + (1 - expr.browInnerUp) * 0);
      final outer = Offset(
          c.dx + sign * (dx + w * 0.5),
          browY + expr.browInnerUp * r * 0.06);
      canvas.drawLine(inner, outer, p);
    }
  }

  Color _browColor() {
    // Darken hair a touch for brows.
    final h = archetype.hairColor;
    return Color.fromARGB(255, (h.r * 255 * 0.7).round(),
        (h.g * 255 * 0.7).round(), (h.b * 255 * 0.7).round());
  }

  void _paintBlush(Canvas canvas, Offset c, double r) {
    final blush = Paint()..color = const Color(0x33FF6B8A);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx - r * 0.5, c.dy + r * 0.28),
            width: r * 0.32,
            height: r * 0.2),
        blush);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx + r * 0.5, c.dy + r * 0.28),
            width: r * 0.32,
            height: r * 0.2),
        blush);
  }

  void _paintMouth(Canvas canvas, Offset c, double r, _Expression expr) {
    final open = (expr.mouthOpen + mouthOpen).clamp(0.0, 1.0);
    final mouthY = c.dy + r * 0.5;
    final w = r * 0.5;
    final curve = expr.mouthCurve;

    if (open > 0.12) {
      // Open mouth: rounded shape whose height tracks openness.
      final h = r * (0.12 + open * 0.5);
      final rect = Rect.fromCenter(
          center: Offset(c.dx, mouthY + h * 0.2), width: w * (0.7 + 0.3 * (1 - open)), height: h);
      final mouthPaint = Paint()..color = const Color(0xFF7A2E33);
      canvas.drawOval(rect, mouthPaint);
      // Tongue hint.
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(c.dx, mouthY + h * 0.45), width: w * 0.5, height: h * 0.5),
          0, math.pi, true, Paint()..color = const Color(0xFFE5737B));
      return;
    }

    // Closed mouth: a curved stroke (smile/frown), optionally a smirk.
    final p = Paint()
      ..color = const Color(0xFF7A2E33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (expr.smirk) {
      path
        ..moveTo(c.dx - w * 0.5, mouthY)
        ..quadraticBezierTo(
            c.dx + w * 0.2, mouthY + curve * r * 0.22, c.dx + w * 0.5,
            mouthY - r * 0.06);
    } else {
      path
        ..moveTo(c.dx - w * 0.5, mouthY)
        ..quadraticBezierTo(
            c.dx, mouthY + curve * r * 0.30, c.dx + w * 0.5, mouthY);
    }
    canvas.drawPath(path, p);
  }

  void _paintBeard(Canvas canvas, Offset c, double r) {
    final beard = Paint()..color = archetype.hairColor;
    final path = Path()
      ..moveTo(c.dx - r * 0.7, c.dy + r * 0.25)
      ..quadraticBezierTo(
          c.dx, c.dy + r * 1.25, c.dx + r * 0.7, c.dy + r * 0.25)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.7, c.dx - r * 0.7, c.dy + r * 0.25)
      ..close();
    canvas.drawPath(path, beard);
  }

  void _paintGlasses(Canvas canvas, Offset c, double r) {
    final p = Paint()
      ..color = const Color(0xFF3A3A45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.04;
    final eyeY = c.dy - r * 0.08;
    final dx = r * 0.42;
    final w = r * 0.42;
    final left =
        Rect.fromCenter(center: Offset(c.dx - dx, eyeY), width: w, height: w);
    final right =
        Rect.fromCenter(center: Offset(c.dx + dx, eyeY), width: w, height: w);
    canvas.drawRRect(
        RRect.fromRectAndRadius(left, Radius.circular(r * 0.1)), p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(right, Radius.circular(r * 0.1)), p);
    canvas.drawLine(Offset(c.dx - dx + w * 0.5, eyeY),
        Offset(c.dx + dx - w * 0.5, eyeY), p);
  }

  void _paintThinkDots(Canvas canvas, Offset c, double r) {
    final base = Offset(c.dx + r * 1.05, c.dy - r * 0.9);
    for (var i = 0; i < 3; i++) {
      final t = ((thinkPhase + i / 3) % 1.0);
      final scale = 0.5 + 0.5 * math.sin(t * math.pi);
      canvas.drawCircle(
          Offset(base.dx + i * r * 0.28, base.dy),
          r * 0.10 * scale,
          Paint()..color = emotion.color.withValues(alpha: 0.4 + 0.6 * scale));
    }
  }

  @override
  bool shouldRepaint(covariant CompanionFacePainter old) =>
      old.archetype != archetype ||
      old.emotion != emotion ||
      old.blink != blink ||
      old.mouthOpen != mouthOpen ||
      old.lookUp != lookUp ||
      old.showThinkDots != showThinkDots ||
      old.thinkPhase != thinkPhase;
}
