import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/live_vision/models/coach_mode.dart';
import '../../../../core/live_vision/models/live_vision_session_state.dart';
import '../bloc/live_vision_bloc.dart';
import '../overlay/models/overlay_spec.dart';
import '../widgets/direction_arrow.dart';
import '../widgets/highlight_box.dart';
import '../widgets/live_status_chip.dart';
import '../widgets/recommendation_bubble.dart';
import '../widgets/suggestion_card.dart';

/// The Live Vision experience: a full-screen camera feed the companion observes
/// continuously, with minimal overlays and hands-free voice. Photo capture is
/// replaced by continuous, friend-like observation.
class LiveVisionScreen extends StatelessWidget {
  const LiveVisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<LiveVisionBloc, LiveVisionState>(
        listenWhen: (a, b) => a.noticeToken != b.noticeToken,
        listener: (context, state) {
          final notice = state.notice;
          if (notice != null && notice.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(notice),
                behavior: SnackBarBehavior.floating,
              ));
          }
        },
        builder: (context, state) {
          if (state.status == LiveVisionStatus.error) {
            return _ErrorView(message: state.notice);
          }
          final controller = context.read<LiveVisionBloc>().controller;
          return Stack(
            fit: StackFit.expand,
            children: [
              _CameraLayer(controller: controller),
              // Subtle gradient so overlays stay readable.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent, Colors.black54],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              _OverlayLayer(overlays: state.overlays),
              _TopBar(state: state),
              _ModeSelector(active: state.mode),
              _BottomControls(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _CameraLayer extends StatelessWidget {
  final CameraController? controller;
  const _CameraLayer({this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null || !c.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // Cover the screen while preserving aspect ratio.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: c.value.previewSize?.height ?? 0,
        height: c.value.previewSize?.width ?? 0,
        child: CameraPreview(c),
      ),
    );
  }
}

class _OverlayLayer extends StatelessWidget {
  final List<OverlaySpec> overlays;
  const _OverlayLayer({required this.overlays});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final spec in overlays) {
      switch (spec) {
        case HighlightBoxSpec(:final rect):
          children.add(Positioned.fill(child: HighlightBox(rect: rect)));
        case DirectionArrowSpec(:final direction, :final caption):
          final arrow = DirectionArrow(direction: direction, caption: caption);
          children.add(Align(alignment: arrow.alignment, child: Padding(
            padding: const EdgeInsets.all(24),
            child: arrow,
          )));
        case SuggestionCardSpec(:final text):
          children.add(Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120, left: 24, right: 24),
              child: SuggestionCard(text: text),
            ),
          ));
        case RecommendationBubbleSpec(:final text):
          children.add(Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 96, left: 24, right: 24),
              child: RecommendationBubble(text: text),
            ),
          ));
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Stack(
        key: ValueKey(overlays.map((o) => o.id).join(',')),
        children: children,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final LiveVisionState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _RoundButton(
              icon: Icons.close,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
            LiveStatusChip(state: state.sessionState),
            const Spacer(),
            _RoundButton(
              icon: state.voiceEnabled ? Icons.mic : Icons.mic_off,
              onTap: () =>
                  context.read<LiveVisionBloc>().add(const LiveVisionVoiceToggled()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final CoachMode active;
  const _ModeSelector({required this.active});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final mode in CoachMode.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ModeChip(
                      mode: mode,
                      selected: mode == active,
                      onTap: () => context
                          .read<LiveVisionBloc>()
                          .add(LiveVisionModeChanged(mode)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final CoachMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          mode.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final LiveVisionState state;
  const _BottomControls({required this.state});

  @override
  Widget build(BuildContext context) {
    final paused = state.sessionState == LiveVisionSessionState.paused;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundButton(
                icon: Icons.photo_camera_outlined,
                label: 'Save',
                onTap: () => context
                    .read<LiveVisionBloc>()
                    .add(const LiveVisionSnapshotRequested()),
              ),
              const SizedBox(width: 28),
              _RoundButton(
                icon: paused ? Icons.play_arrow : Icons.pause,
                label: paused ? 'Resume' : 'Pause',
                big: true,
                onTap: () => context.read<LiveVisionBloc>().add(
                    paused ? const LiveVisionResumed() : const LiveVisionPaused()),
              ),
              const SizedBox(width: 28),
              const SizedBox(width: 48), // balance the row
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool big;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = big ? 64.0 : 48.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.black.withValues(alpha: 0.5),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: Colors.white, size: big ? 30 : 22),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(label!, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? message;
  const _ErrorView({this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white70, size: 56),
            const SizedBox(height: 16),
            Text(
              message ?? 'Live Vision is unavailable right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Go back'),
                ),
                FilledButton(
                  onPressed: () =>
                      context.read<LiveVisionBloc>().add(const LiveVisionStarted()),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
