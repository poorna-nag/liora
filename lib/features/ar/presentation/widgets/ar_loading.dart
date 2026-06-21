import 'package:flutter/material.dart';

/// Full-screen loading overlay shown while the AR session (and the first model)
/// initialize — requirement 10.
class ArLoading extends StatelessWidget {
  final String label;
  const ArLoading({super.key, this.label = 'Starting AR…'});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
