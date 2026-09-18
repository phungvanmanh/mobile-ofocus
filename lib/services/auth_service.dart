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

  Future<AuthActionResult<ForgotPasswordData>> forgotPassword({
    required String email,
  }) {
    return _postAction(
      ApiConfig.forgotPassword,
      {'email': email},
      ForgotPasswordData.fromJson,
    );
  }

  Future<AuthActionResult<VerifyOtpData>> verifyOtp({
    required String email,
    required String otp,
  }) {
    return _postAction(
      ApiConfig.verifyOtp,
      {'email': email, 'otp': otp},
      VerifyOtpData.fromJson,
    );
  }

  Future<AuthActionResult<ResetPasswordData>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) {
    return _postAction(
      ApiConfig.resetPassword,
      {'resetToken': resetToken, 'newPassword': newPassword},
      ResetPasswordData.fromJson,
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

      return LoginResult.failure(_extractErrorMessage(body));
    } catch (_) {
      return LoginResult.failure('Không thể kết nối máy chủ. Vui lòng thử lại.');
    }
  }

  Future<AuthActionResult<T>> _postAction<T>(
    String url,
    Map<String, dynamic> payload,
    T Function(Map<String, dynamic> json) parseData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return AuthActionResult.failure('Phản hồi không hợp lệ từ máy chủ');
      }

      final meta = body['meta'];
      final success = meta is Map && meta['success'] == true;
      final data = body['data'];

      if (success && data is Map<String, dynamic>) {
        return AuthActionResult.success(parseData(data));
      }

      return AuthActionResult.failure(_extractErrorMessage(body));
    } catch (_) {
      return AuthActionResult.failure(
        'Không thể kết nối máy chủ. Vui lòng thử lại.',
      );
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
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (data is String && data.isNotEmpty) return data;

    final meta = body['meta'];
    if (meta is Map) {
      final external = meta['externalMessage'];
      if (external is String && external.isNotEmpty && external != 'Error') {
        return external;
      }
      final internal = meta['internalMessage'];
      if (internal is String && internal.isNotEmpty && internal != 'Error') {
        return internal;
      }
    }

    return 'Yêu cầu thất bại';
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

class AuthActionResult<T> {
  const AuthActionResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory AuthActionResult.success(T data) {
    return AuthActionResult._(isSuccess: true, data: data);
  }

  factory AuthActionResult.failure(String message) {
    return AuthActionResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final T? data;
  final String? errorMessage;
}

class ForgotPasswordData {
  const ForgotPasswordData({
    required this.message,
    required this.expiresInMinutes,
  });

  factory ForgotPasswordData.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordData(
      message: json['message'] as String? ?? 'Mã OTP đã được gửi',
      expiresInMinutes: (json['expiresInMinutes'] as num?)?.toInt() ?? 5,
    );
  }

  final String message;
  final int expiresInMinutes;
}

class VerifyOtpData {
  const VerifyOtpData({
    required this.message,
    required this.resetToken,
  });

  factory VerifyOtpData.fromJson(Map<String, dynamic> json) {
    return VerifyOtpData(
      message: json['message'] as String? ?? 'Xác thực OTP thành công',
      resetToken: json['resetToken'] as String? ?? '',
    );
  }

  final String message;
  final String resetToken;
}

class ResetPasswordData {
  const ResetPasswordData({required this.message});

  factory ResetPasswordData.fromJson(Map<String, dynamic> json) {
    return ResetPasswordData(
      message: json['message'] as String? ??
          'Đặt lại mật khẩu thành công. Bạn có thể đăng nhập bằng mật khẩu mới.',
    );
  }

  final String message;
}
