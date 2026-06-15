import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/widgets/message_bubble.dart';
import '../bloc/vision_bloc.dart';

class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, Uint8List? bytes) {
    if (bytes == null) return;
    context
        .read<VisionBloc>()
        .add(VisionImageSubmitted(bytes, _promptController.text.trim()));
    _promptController.clear();
  }

  Future<void> _openLivePreview(BuildContext context) async {
    final granted = await sl<PermissionService>().requestCamera();
    if (!granted || !context.mounted) return;
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const _CameraCaptureScreen()),
    );
    if (context.mounted) _submit(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Vision Analysis')),
      body: BlocConsumer<VisionBloc, VisionState>(
        listenWhen: (p, c) => c.status == VisionStatus.error,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Capture a photo or pick one from your gallery, '
                            'then ask about it.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) {
                          final m = state.messages[i];
                          return MessageBubble(
                            text: m.content,
                            isUser: m.isUser,
                            imagePath: m.imagePath,
                          );
                        },
                      ),
              ),
              if (state.isAnalyzing)
                const LinearProgressIndicator(minHeight: 2),
              _Controls(
                promptController: _promptController,
                onLive: () => _openLivePreview(context),
                onPhoto: () async {
                  final bytes = await sl<CameraService>().capturePhoto();
                  if (context.mounted) _submit(context, bytes);
                },
                onGallery: () async {
                  final bytes = await sl<CameraService>().pickFromGallery();
                  if (context.mounted) _submit(context, bytes);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final TextEditingController promptController;
  final VoidCallback onLive;
  final VoidCallback onPhoto;
  final VoidCallback onGallery;

  const _Controls({
    required this.promptController,
    required this.onLive,
    required this.onPhoto,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            TextField(
              controller: promptController,
              decoration: const InputDecoration(
                hintText: 'Ask something about the image (optional)…',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Action(
                    icon: Icons.videocam, label: 'Live', onTap: onLive),
                _Action(
                    icon: Icons.photo_camera, label: 'Photo', onTap: onPhoto),
                _Action(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: onGallery),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Full-screen live camera preview with a shutter button. Returns the captured
/// JPEG bytes via [Navigator.pop].
class _CameraCaptureScreen extends StatefulWidget {
  const _CameraCaptureScreen();

  @override
  State<_CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<_CameraCaptureScreen> {
  CameraController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = await sl<CameraService>().createController();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      setState(() => _error = 'Camera unavailable: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null) return;
    final bytes = await sl<CameraService>().captureFromController(controller);
    if (mounted) Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: _error != null
          ? Center(
              child: Text(_error!,
                  style: const TextStyle(color: Colors.white)))
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(child: CameraPreview(_controller!)),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: FloatingActionButton(
                        onPressed: _capture,
                        child: const Icon(Icons.camera),
                      ),
                    ),
                  ],
                ),
    );
  }
}
