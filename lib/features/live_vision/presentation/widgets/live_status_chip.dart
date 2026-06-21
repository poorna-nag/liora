import 'package:flutter/material.dart';

import '../../../../core/live_vision/models/live_vision_session_state.dart';

/// A small pill showing what the companion is doing right now (observing,
/// listening, speaking…). Keeps the live state legible without clutter.
class LiveStatusChip extends StatelessWidget {
  final LiveVisionSessionState state;

  const LiveStatusChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _present(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _present(BuildContext context) {
    switch (state) {
      case LiveVisionSessionState.idle:
        return ('Idle', Colors.grey, Icons.pause_circle_outline);
      case LiveVisionSessionState.initializing:
        return ('Starting…', Colors.amber, Icons.hourglass_top);
      case LiveVisionSessionState.observing:
        return ('Observing', Colors.greenAccent, Icons.visibility);
      case LiveVisionSessionState.speaking:
        return ('Speaking', Theme.of(context).colorScheme.primary, Icons.volume_up);
      case LiveVisionSessionState.listening:
        return ('Listening', Colors.lightBlueAccent, Icons.mic);
      case LiveVisionSessionState.paused:
        return ('Paused', Colors.orangeAccent, Icons.pause);
      case LiveVisionSessionState.error:
        return ('Error', Colors.redAccent, Icons.error_outline);
    }
  }
}
