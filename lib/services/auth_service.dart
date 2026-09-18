import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ofocus/config/api_config.dart';

class AuthService {
  Future<LoginResult> login({
    required String email,
    required String password,
  }) {
    return _postLogin(
      ApiConfig.login,
      {'email': email, 'password': password},
    );
  }

  Future<LoginResult> googleLogin({required String credential}) {
    return _postLogin(
      ApiConfig.googleLogin,
      {'credential': credential},
    );
  }

  Future<LoginResult> _postLogin(
    String url,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return LoginResult.failure('Phản hồi không hợp lệ từ máy chủ');
      }

      final meta = body['meta'];
      final success = meta is Map && meta['success'] == true;

      if (success) {
        return LoginResult.success(_normalizeLoginPayload(body['data']));
      }

      final message = _extractErrorMessage(body);
      return LoginResult.failure(message);
    } catch (_) {
      return LoginResult.failure('Không thể kết nối máy chủ. Vui lòng thử lại.');
    }
  }

  /// Unwraps nested `{ meta, data: { token, user } }` payloads from v2 API.
  dynamic _normalizeLoginPayload(dynamic data) {
    if (data is! Map) return data;

    var map = Map<String, dynamic>.from(data);

    while (true) {
      final inner = map['data'];
      if (inner is! Map) break;

      final innerMap = Map<String, dynamic>.from(inner);
      final hasAuthPayload = innerMap.containsKey('token') ||
          innerMap.containsKey('accessToken') ||
          innerMap.containsKey('access_token') ||
          innerMap.containsKey('user');

      if (!hasAuthPayload) break;
      map = innerMap;
    }

    return map;
  }

  String _extractErrorMessage(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is String && data.isNotEmpty) return data;

    final meta = body['meta'];
    if (meta is Map) {
      final external = meta['externalMessage'];
      if (external is String && external.isNotEmpty && external != 'Error') {
        return external;
      }
    }

    return 'Đăng nhập thất bại';
  }
}

class LoginResult {
  const LoginResult._({required this.isSuccess, this.data, this.errorMessage});

  factory LoginResult.success(dynamic data) {
    return LoginResult._(isSuccess: true, data: data);
  }

  factory LoginResult.failure(String message) {
    return LoginResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final dynamic data;
  final String? errorMessage;
}
