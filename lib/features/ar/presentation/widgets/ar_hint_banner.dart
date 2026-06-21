import 'package:flutter/material.dart';

/// Bottom pill guiding the user to find a surface and tap — shown while the
/// scene is ready but nothing has been placed yet.
class ArHintBanner extends StatelessWidget {
  final String text;
  const ArHintBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app_outlined,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
