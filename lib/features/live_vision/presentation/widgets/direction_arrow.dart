import 'package:flutter/material.dart';

import '../../../../core/live_vision/models/scene_observation.dart';

/// An edge-anchored arrow that nudges the user to move the camera, with a short
/// caption — like a friend pointing and saying "look over there".
class DirectionArrow extends StatelessWidget {
  final GuidanceDirection direction;
  final String caption;

  const DirectionArrow({
    super.key,
    required this.direction,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: Colors.white, size: 22),
          if (caption.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                caption,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData get _icon {
    switch (direction) {
      case GuidanceDirection.left:
        return Icons.arrow_back;
      case GuidanceDirection.right:
        return Icons.arrow_forward;
      case GuidanceDirection.up:
        return Icons.arrow_upward;
      case GuidanceDirection.down:
        return Icons.arrow_downward;
      case GuidanceDirection.closer:
        return Icons.zoom_in;
      case GuidanceDirection.farther:
        return Icons.zoom_out;
      case GuidanceDirection.none:
        return Icons.center_focus_weak;
    }
  }

  /// Where on the screen this arrow should sit, given its [direction].
  Alignment get alignment {
    switch (direction) {
      case GuidanceDirection.left:
        return Alignment.centerLeft;
      case GuidanceDirection.right:
        return Alignment.centerRight;
      case GuidanceDirection.up:
        return Alignment.topCenter;
      case GuidanceDirection.down:
        return Alignment.bottomCenter;
      case GuidanceDirection.closer:
      case GuidanceDirection.farther:
      case GuidanceDirection.none:
        return Alignment.center;
    }
  }
}
