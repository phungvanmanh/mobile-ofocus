import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:ofocus/config/api_config.dart';
import 'package:ofocus/config/upload_config.dart';
import 'package:ofocus/services/api_client.dart';
import 'package:ofocus/services/session_manager.dart';

class AvatarService {
  AvatarService({SessionManager? sessionManager})
    : _sessionManager = sessionManager ?? SessionManager();

  final SessionManager _sessionManager;

  /// Uploads image to CDN, updates avatar on backend, persists session.
  Future<AvatarUploadResult> uploadAndUpdateAvatar(String filePath) async {
    // Cùng token đã lưu lúc login (SharedPreferences: auth_token).
    final token = await _sessionManager.getAuthToken();
    if (token == null || token.isEmpty) {
      return AvatarUploadResult.failure('Phiên đăng nhập không hợp lệ');
    }

    final bytes = await _readFileBytes(filePath);
    if (bytes == null || bytes.isEmpty) {
      return AvatarUploadResult.failure('Không đọc được file ảnh đã chọn');
    }

    final relativePath = await _uploadToCdn(
      bytes: bytes,
      fileName: _fileName(filePath),
    );
    if (relativePath == null) {
      return AvatarUploadResult.failure(
        'Không thể tải ảnh lên máy chủ lưu trữ',
      );
    }

    final avatarUrl = UploadConfig.avatarViewUrl(relativePath);
    // debugPrint('[Avatar] CDN ok → $avatarUrl');
    // debugPrint('[Avatar] Using login token from SessionManager');

    final updateError = await _updateAvatarOnBackend(
      avatarUrl: avatarUrl,
      token: token,
    );
    if (updateError != null) {
      return AvatarUploadResult.failure(updateError);
    }

    await _sessionManager.updateUserData({'avatar_url': avatarUrl});
    // debugPrint('[Avatar] Session updated');

    return AvatarUploadResult.success(avatarUrl);
  }

  Future<Uint8List?> _readFileBytes(String filePath) async {
    try {
      if (filePath.startsWith('content://') || filePath.startsWith('file://')) {
        return await XFile(filePath).readAsBytes();
      }

      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }

      return await XFile(filePath).readAsBytes();
    } catch (error, stack) {
      debugPrint('[Avatar] readFileBytes failed: $error');
      debugPrint('$stack');
      return null;
    }
  }

  Future<String?> _uploadToCdn({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(UploadConfig.uploadUrl),
      );

      request.files.add(
        http.MultipartFile.fromBytes('files', bytes, filename: fileName),
      );

      // debugPrint('[Avatar] Uploading to CDN (${bytes.length} bytes)...');
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      // debugPrint('[Avatar] CDN status: ${response.statusCode}');
      if (kDebugMode && response.body.isNotEmpty) {
        // debugPrint('[Avatar] CDN body: ${response.body}');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map) return null;

      final files = body['files'];
      if (files is! List || files.isEmpty) return null;

      final first = files.first;
      if (first is! Map) return null;

      final relativePath = first['relativePath'];
      if (relativePath is String && relativePath.isNotEmpty) {
        return relativePath;
      }

      return null;
    } catch (error, stack) {
      debugPrint('[Avatar] CDN upload error: $error');
      debugPrint('$stack');
      return null;
    }
  }

  /// Returns error message when update fails, null on success.
  Future<String?> _updateAvatarOnBackend({
    required String avatarUrl,
    required String token,
  }) async {
    final url = ApiConfig.updateAvatar;
    // debugPrint('[Avatar] Updating BE → $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: ApiClient.authHeaders(token),
        body: jsonEncode({'avatar_url': avatarUrl}),
      );

      // debugPrint('[Avatar] BE status: ${response.statusCode}');
      // debugPrint('[Avatar] Token: $token');
      // if (kDebugMode && response.body.isNotEmpty) {
      //   debugPrint('[Avatar] BE body: ${response.body}');
      // }

      if (_isApiSuccess(response)) {
        return null;
      }

      return _extractApiError(response);
    } catch (error, stack) {
      debugPrint('[Avatar] BE update error: $error');
      debugPrint('$stack');
      return 'Không thể kết nối máy chủ cập nhật avatar';
    }
  }

  bool _isApiSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    if (response.body.isEmpty) return true;

    try {
      final body = jsonDecode(response.body);
      if (body is! Map) return true;

      bool? readSuccess(dynamic meta) {
        if (meta is Map && meta.containsKey('success')) {
          return meta['success'] == true;
        }
        return null;
      }

      final outer = readSuccess(body['meta']);
      if (outer != null) return outer;

      final data = body['data'];
      if (data is Map) {
        final inner = readSuccess(data['meta']);
        if (inner != null) return inner;
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  String _extractApiError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        for (final key in ['meta', 'data']) {
          final section = body[key];
          if (section is Map) {
            final meta = section['meta'];
            if (meta is Map) {
              final msg = meta['externalMessage'] ?? meta['internalMessage'];
              if (msg is String && msg.isNotEmpty && msg != 'Error') {
                return msg;
              }
            }
            final direct = section['externalMessage'] ?? section['message'];
            if (direct is String && direct.isNotEmpty) {
              return direct;
            }
          }
        }
      }
    } catch (_) {}

    return 'Máy chủ từ chối cập nhật (HTTP ${response.statusCode})';
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    return name.isNotEmpty ? name : 'avatar.jpg';
  }
}

class AvatarUploadResult {
  const AvatarUploadResult._({
    required this.isSuccess,
    this.avatarUrl,
    this.errorMessage,
  });

  factory AvatarUploadResult.success(String avatarUrl) {
    return AvatarUploadResult._(isSuccess: true, avatarUrl: avatarUrl);
  }

  factory AvatarUploadResult.failure(String message) {
    return AvatarUploadResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final String? avatarUrl;
  final String? errorMessage;
}
