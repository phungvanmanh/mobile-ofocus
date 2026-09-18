import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ofocus/config/api_config.dart';
import 'package:ofocus/services/api_client.dart';
import 'package:ofocus/services/session_manager.dart';

class RoomService {
  RoomService({SessionManager? sessionManager})
      : _sessionManager = sessionManager ?? SessionManager();

  final SessionManager _sessionManager;

  Future<RoomTokenResult> fetchRoomToken({
    required String roomName,
    required String participantName,
    required int classId,
  }) async {
    final token = await _sessionManager.getAuthToken();
    if (token == null || token.isEmpty) {
      return RoomTokenResult.failure('Phiên đăng nhập không hợp lệ');
    }

    try {
      final url = ApiConfig.roomToken;
      final response = await http.post(
        Uri.parse(url),
        headers: ApiClient.authHeaders(token),
        body: jsonEncode({
          'roomName': roomName,
          'participantName': participantName,
          'classId': classId,
        }),
      );

      debugPrint('[RoomService] POST $url → ${response.statusCode}');

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return RoomTokenResult.failure('Phản hồi không hợp lệ từ máy chủ');
      }

      if (!_isSuccess(body)) {
        return RoomTokenResult.failure(_extractErrorMessage(body));
      }

      final data = body['data'];
      if (data is Map) {
        final roomToken = data['token'];
        if (roomToken is String && roomToken.isNotEmpty) {
          return RoomTokenResult.success(roomToken);
        }
      }

      return RoomTokenResult.failure('Không lấy được token phòng học');
    } catch (error, stack) {
      debugPrint('[RoomService] fetchRoomToken error: $error');
      debugPrint('$stack');
      return RoomTokenResult.failure('Không thể tham gia phòng học');
    }
  }

  bool _isSuccess(Map<String, dynamic> body) {
    final meta = body['meta'];
    if (meta is Map && meta.containsKey('success')) {
      return meta['success'] == true;
    }
    return true;
  }

  String _extractErrorMessage(Map<String, dynamic> body) {
    final meta = body['meta'];
    if (meta is Map) {
      final external = meta['externalMessage'];
      if (external is String && external.isNotEmpty && external != 'Error') {
        return external;
      }
    }
    return 'Không thể tham gia phòng học';
  }
}

class RoomTokenResult {
  const RoomTokenResult._({
    required this.isSuccess,
    this.token,
    this.errorMessage,
  });

  factory RoomTokenResult.success(String token) {
    return RoomTokenResult._(isSuccess: true, token: token);
  }

  factory RoomTokenResult.failure(String message) {
    return RoomTokenResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final String? token;
  final String? errorMessage;
}
