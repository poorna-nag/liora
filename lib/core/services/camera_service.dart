import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import '../error/exceptions.dart';

/// Provides image input for vision analysis via two paths:
/// - live camera preview + capture (the `camera` plugin), and
/// - photo capture / gallery pick (the `image_picker` plugin).
class CameraService {
  final ImagePicker _picker = ImagePicker();
  List<CameraDescription>? _cameras;

  /// Enumerates available cameras (called lazily before creating a controller).
  Future<List<CameraDescription>> availableCameraList() async {
    _cameras ??= await availableCameras();
    return _cameras!;
  }

  /// Creates and initializes a [CameraController] for live preview.
  /// Caller is responsible for disposing it.
  Future<CameraController> createController({
    CameraLensDirection direction = CameraLensDirection.back,
  }) async {
    final cameras = await availableCameraList();
    if (cameras.isEmpty) {
      throw const DeviceException('No camera available on this device.');
    }
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    return controller;
  }

  /// Captures a frame from an initialized live-preview controller.
  Future<Uint8List> captureFromController(CameraController controller) async {
    final file = await controller.takePicture();
    return file.readAsBytes();
  }

  /// Takes a single photo using the system camera UI.
  Future<Uint8List?> capturePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;
    return file.readAsBytes();
  }

  /// Picks an existing image from the gallery.
  Future<Uint8List?> pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return file.readAsBytes();
  }
}
