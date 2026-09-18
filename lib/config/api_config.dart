import 'dart:io';

import 'package:flutter/foundation.dart';

enum ApiEnvironment {
  /// BE chạy trên máy (localhost / 10.0.2.2 trên Android emulator).
  local,

  /// BE production: api.ofocus.vn
  server,
}

/// Path layout per environment — chỉ khai báo 1 lần ở đây.
final class _ApiPaths {
  const _ApiPaths({required this.apiVersion, required this.authPrefix});
  final String apiVersion;

  /// `users` (v1) hoặc `auth` (v2 mobile) cho login/google-login.
  final String authPrefix;
  static const server = _ApiPaths(
    apiVersion: '/api/v2/mobile',
    authPrefix: 'auth',
  );

  static const local = _ApiPaths(
    apiVersion: '/api/v2/mobile',
    authPrefix: 'auth',
  );

  String join(String baseUrl, String path) {
    final clean = path.replaceFirst(RegExp(r'^/+'), '');
    return '$baseUrl$apiVersion/$clean';
  }
}

/// Backend API endpoints and base URLs.
abstract final class ApiConfig {
  // ---------------------------------------------------------------------------
  // Cách 1 — đổi 1 dòng khi dev (nhanh nhất):
  //   ApiEnvironment.local  → BE localhost
  //   ApiEnvironment.server → BE production
  // ---------------------------------------------------------------------------
  static const defaultEnvironment = ApiEnvironment.server;
  static const _envName = String.fromEnvironment('API_ENV');
  static const _customBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _serverHost = 'https://api.ofocus.vn';
  static const _localPort = 5000;

  static ApiEnvironment get environment {
    if (_customBaseUrl.isNotEmpty) return ApiEnvironment.local;
    return switch (_envName) {
      'local' => ApiEnvironment.local,
      'server' => ApiEnvironment.server,
      _ => defaultEnvironment,
    };
  }

  static bool get isLocal => environment == ApiEnvironment.local;

  static _ApiPaths get _paths => switch (environment) {
    ApiEnvironment.server => _ApiPaths.server,
    ApiEnvironment.local => _ApiPaths.local,
  };

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;

    if (environment == ApiEnvironment.server) return _serverHost;

    if (kIsWeb) return 'http://127.0.0.1:$_localPort';

    if (Platform.isAndroid) {
      // 127.0.0.1 trên Android emulator = chính emulator, không phải PC host.
      return 'http://10.0.2.2:$_localPort';
    }

    return 'http://127.0.0.1:$_localPort';
  }

  /// Ghép endpoint mới: `_endpoint('users/profile')`.
  static String _endpoint(String path) => _paths.join(baseUrl, path);

  // --- Endpoints (thêm URL mới = thêm 1 dòng bên dưới) ---
  static String get login => _endpoint('${_paths.authPrefix}/login');
  static String get googleLogin =>
      _endpoint('${_paths.authPrefix}/google-login');
  static String get updateAvatar => _endpoint('users/update-avatar');
  static String get classMine => _endpoint('class/mine');
  static String get classCreate => _endpoint('class');
  static String classDelete(int classId) => _endpoint('class/$classId');
  static String get classScheduleSpecial => _endpoint('class-schedule/special');
  static String get classScheduleActive => _endpoint('class-schedule/active');
  static String get classScheduleClosed => _endpoint('class-schedule/closed');
  static String get roomToken => _endpoint('room/token');

  static String get label => '${environment.name} → $baseUrl';
}
