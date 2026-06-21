import 'package:flutter/material.dart';

import '../../../../core/live_vision/models/scene_observation.dart';

/// A best-effort highlight rectangle drawn from normalized (0..1) coordinates.
/// Deliberately simple — a static box with an optional label, NOT tracked AR.
class HighlightBox extends StatelessWidget {
  final HighlightRect rect;

  const HighlightBox({super.key, required this.rect});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              left: rect.x * w,
              top: rect.y * h,
              width: rect.w * w,
              height: rect.h * h,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: accent, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.topLeft,
                child: rect.label.isEmpty
                    ? null
                    : Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: accent,
                        child: Text(
                          rect.label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
