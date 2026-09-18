import 'package:permission_handler/permission_handler.dart';

class MediaPermissionService {
  static Future<bool> ensureCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> ensureMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<MediaPermissionStatus> ensureCameraAndMicrophone({
    bool requestCamera = true,
    bool requestMicrophone = true,
  }) async {
    var cameraGranted = !requestCamera;
    var microphoneGranted = !requestMicrophone;

    if (requestCamera) {
      cameraGranted = await ensureCamera();
    }
    if (requestMicrophone) {
      microphoneGranted = await ensureMicrophone();
    }

    return MediaPermissionStatus(
      cameraGranted: cameraGranted,
      microphoneGranted: microphoneGranted,
    );
  }
}

class MediaPermissionStatus {
  const MediaPermissionStatus({
    required this.cameraGranted,
    required this.microphoneGranted,
  });

  final bool cameraGranted;
  final bool microphoneGranted;

  bool get allGranted => cameraGranted && microphoneGranted;

  List<String> get warnings {
    final messages = <String>[];
    if (!cameraGranted) {
      messages.add('Quyền camera bị từ chối');
    }
    if (!microphoneGranted) {
      messages.add('Quyền microphone bị từ chối');
    }
    return messages;
  }
}
