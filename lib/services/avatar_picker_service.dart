import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum AvatarPickResult {
  success,
  cancelled,
  permissionDenied,
  permissionPermanentlyDenied,
  failed,
}

class AvatarPickerService {
  AvatarPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Requests gallery permission if needed, then opens the system photo picker.
  Future<({AvatarPickResult result, String? path})> pickFromGallery() async {
    final granted = await _ensureGalleryPermission();
    if (!granted) {
      final blocked = await _isPermanentlyBlocked();
      if (blocked) {
        return (result: AvatarPickResult.permissionPermanentlyDenied, path: null);
      }
      return (result: AvatarPickResult.permissionDenied, path: null);
    }

    return _pickImage();
  }

  Future<void> openSettings() => openAppSettings();

  Future<bool> _ensureGalleryPermission() async {
    final permissions = _galleryPermissions();

    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) return true;
    }

    for (final permission in permissions) {
      final status = await permission.request();
      if (status.isGranted || status.isLimited) return true;
    }

    return false;
  }

  Future<bool> _isPermanentlyBlocked() async {
    for (final permission in _galleryPermissions()) {
      final status = await permission.status;
      if (status.isPermanentlyDenied || status.isRestricted) return true;
    }
    return false;
  }

  List<Permission> _galleryPermissions() {
    if (Platform.isIOS) return [Permission.photos];
    // Android 13+ uses photos; older versions use storage.
    return [Permission.photos, Permission.storage];
  }

  Future<({AvatarPickResult result, String? path})> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) {
        return (result: AvatarPickResult.cancelled, path: null);
      }
      return (result: AvatarPickResult.success, path: file.path);
    } catch (_) {
      return (result: AvatarPickResult.failed, path: null);
    }
  }
}
