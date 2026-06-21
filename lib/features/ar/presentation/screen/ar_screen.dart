import 'package:ar_flutter_plugin_engine/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_engine/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_engine/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_engine/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_engine/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_engine/models/ar_node.dart';
import 'package:ar_flutter_plugin_engine/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../../../core/di/service_locator.dart';
import '../../data/services/ar_model_loader.dart';
import '../../data/services/ar_support_service.dart';
import '../../utils/ar_constants.dart';
import '../bloc/ar_bloc.dart';
import '../widgets/ar_hint_banner.dart';
import '../widgets/ar_loading.dart';
import '../widgets/ar_unsupported.dart';

/// Phase 7 — the reusable AR experience. Point the camera at a surface and tap
/// to place an anchored 3D model that stays fixed in space as you move, with
/// pinch/drag/rotate gestures to scale, move and rotate it.
///
/// The plugin's `ARView` manages the camera permission prompt itself; this
/// screen layers status (loading / unsupported / hint) on top via [ArBloc].
class ArScreen extends StatelessWidget {
  const ArScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final support = sl<ArSupportService>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<ArBloc, ArState>(
        listenWhen: (a, b) => a.status != b.status && b.status == ArStatus.error,
        listener: (context, state) {
          final msg = state.message;
          if (msg != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        builder: (context, state) {
          if (state.status == ArStatus.unsupported) {
            return ArUnsupported(
              message: state.message ?? support.unsupportedMessage,
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              // The AR view mounts underneath; when its managers are created we
              // flip the bloc to "ready".
              const _ArExperience(),
              if (state.status == ArStatus.initializing) const ArLoading(),
              if (state.status == ArStatus.ready && !state.hasPlacedObjects)
                ArHintBanner(text: support.hint),
              _TopBar(canClear: state.hasPlacedObjects),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool canClear;
  const _TopBar({required this.canClear});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RoundIcon(
              icon: Icons.close,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            if (canClear)
              _RoundIcon(
                icon: Icons.delete_sweep_outlined,
                onTap: () => _ArExperience.clearOf(context),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

/// Owns the plugin's AR managers and the placement/clear logic. Kept separate
/// from [ArScreen] so the bloc/UI stays declarative while the imperative AR
/// session lives in one place.
class _ArExperience extends StatefulWidget {
  const _ArExperience();

  /// Lets the top bar trigger "clear all" without threading a controller.
  static void clearOf(BuildContext context) =>
      context.findAncestorStateOfType<_ArExperienceState>()?._clearObjects();

  @override
  State<_ArExperience> createState() => _ArExperienceState();
}

class _ArExperienceState extends State<_ArExperience> {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;

  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];
  ArModelRef? _modelRef;

  @override
  Widget build(BuildContext context) {
    return ARView(
      onARViewCreated: _onARViewCreated,
      planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
    );
  }

  Future<void> _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;

    sessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: true, // drag to move
      handleRotation: true, // twist to rotate (pinch scales too)
    );
    objectManager.onInitialize();
    sessionManager.onPlaneOrPointTap = _onPlaneOrPointTap;

    // Resolve the model once up front so the first tap places instantly.
    try {
      _modelRef = await const ArModelLoader().resolve();
    } catch (_) {
      _modelRef = const ArModelRef(NodeType.webGLB, ArConstants.fallbackModelUrl);
    }

    if (mounted) context.read<ArBloc>().add(const ArViewReady());
  }

  Future<void> _onPlaneOrPointTap(List<ARHitTestResult> hits) async {
    final objectManager = _objectManager;
    final anchorManager = _anchorManager;
    final modelRef = _modelRef;
    if (objectManager == null || anchorManager == null || modelRef == null) {
      return;
    }
    if (hits.isEmpty) return;

    // Prefer a plane hit (a real surface) over a feature point.
    final hit = hits.firstWhere(
      (h) => h.type == ARHitTestResultType.plane,
      orElse: () => hits.first,
    );

    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final didAddAnchor = await anchorManager.addAnchor(anchor);
    if (didAddAnchor != true) {
      if (mounted) {
        context.read<ArBloc>().add(
            const ArErrorReported('Could not anchor here — try another spot.'));
      }
      return;
    }
    _anchors.add(anchor);

    final node = ARNode(
      type: modelRef.type,
      uri: modelRef.uri,
      scale: Vector3.all(ArConstants.initialScale),
    );
    final didAddNode =
        await objectManager.addNode(node, planeAnchor: anchor);
    if (didAddNode == true) {
      _nodes.add(node);
      if (mounted) context.read<ArBloc>().add(const ArObjectPlaced());
    } else {
      anchorManager.removeAnchor(anchor);
      _anchors.remove(anchor);
    }
  }

  void _clearObjects() {
    final objectManager = _objectManager;
    final anchorManager = _anchorManager;
    for (final node in _nodes) {
      objectManager?.removeNode(node);
    }
    for (final anchor in _anchors) {
      anchorManager?.removeAnchor(anchor);
    }
    _nodes.clear();
    _anchors.clear();
    if (mounted) context.read<ArBloc>().add(const ArCleared());
  }

  @override
  void dispose() {
    _sessionManager?.dispose();
    super.dispose();
  }
}
