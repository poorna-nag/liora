import 'package:flutter/material.dart';

/// A speech bubble echoing what the companion just said, shown near the top.
class RecommendationBubble extends StatelessWidget {
  final String text;

  const RecommendationBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: accent, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
