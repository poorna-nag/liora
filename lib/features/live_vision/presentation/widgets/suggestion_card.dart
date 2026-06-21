import 'package:flutter/material.dart';

/// A minimal bottom card carrying an actionable tip from the companion.
class SuggestionCard extends StatelessWidget {
  final String text;

  const SuggestionCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 10),
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
