import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around runtime permission requests.
class PermissionService {
  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Speech recognition needs both mic and (on iOS) the speech permission.
  Future<bool> requestSpeech() async {
    final statuses = await [
      Permission.microphone,
      Permission.speech,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }
}
