import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ofocus/models/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  factory SessionManager() => instance;

  static const _tokenKey = 'auth_token';
  static const _expiresAtKey = 'auth_expires_at_ms';
  static const _userDataKey = 'auth_user_data';

  /// API oFocus JWT hiện chỉ có `iat`, không có `exp`.
  static const defaultTokenTtl = Duration(days: 7);

  String? _token;

  String? get token => _token;

  /// Token đã lưu lúc login (`auth_token` trong SharedPreferences).
  /// Luôn gọi method này trước khi gọi API cần xác thực.
  Future<String?> getAuthToken() async {
    if (_token != null && _token!.isNotEmpty) return _token;

    final session = await loadSession();
    return session?.token;
  }

  Future<UserSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiresAtMs = prefs.getInt(_expiresAtKey);

    if (token == null || token.isEmpty || expiresAtMs == null) {
      _token = null;
      return null;
    }

    _token = token;

    Map<String, dynamic>? userData;
    final rawUser = prefs.getString(_userDataKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawUser);
        if (decoded is Map<String, dynamic>) {
          userData = _normalizeStoredUserData(decoded, token);
        }
      } catch (_) {}
    }

    return UserSession(
      token: token,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMs),
      userData: userData,
    );
  }

  Future<bool> isSessionValid() async {
    final session = await loadSession();
    return session != null && session.isValid;
  }

  Future<UserSession?> saveSessionFromLoginData(dynamic data) async {
    final parsed = _parseLoginData(data);
    if (parsed == null) return null;

    final prefs = await SharedPreferences.getInstance();
    _token = parsed.token;
    await prefs.setString(_tokenKey, parsed.token);
    await prefs.setInt(_expiresAtKey, parsed.expiresAt.millisecondsSinceEpoch);

    if (parsed.userData != null) {
      await prefs.setString(_userDataKey, jsonEncode(parsed.userData));
      debugPrint(
        '[Auth] User saved: ${parsed.userData!['full_name']} | '
        '${parsed.userData!['avatar_url']}',
      );
    } else {
      await prefs.remove(_userDataKey);
    }

    logSessionExpiry(parsed);
    return parsed;
  }

  Future<Map<String, dynamic>?> updateUserData(
    Map<String, dynamic> updates,
  ) async {
    final session = await loadSession();
    final current = session?.userData;
    if (current == null) return null;

    final updated = Map<String, dynamic>.from(current)..addAll(updates);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(updated));
    return updated;
  }

  Future<void> clearSession() async {
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresAtKey);
    await prefs.remove(_userDataKey);
    debugPrint('[Auth] Đã xóa phiên đăng nhập, token = null');
  }

  void logSessionExpiry(UserSession session) {
    final localExpiry = session.expiresAt.toLocal();
    final remaining = session.remaining;

    debugPrint('═══════════════════════════════════════');
    debugPrint('[Auth] Token hết hạn lúc: $localExpiry');
    if (remaining.isNegative) {
      debugPrint('[Auth] Trạng thái: ĐÃ HẾT HẠN');
    } else {
      debugPrint(
        '[Auth] Còn lại: ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m ${remaining.inSeconds.remainder(60)}s',
      );
    }
    debugPrint('═══════════════════════════════════════');
  }

  UserSession? _parseLoginData(dynamic data) {
    if (data is! Map) return null;

    final map = Map<String, dynamic>.from(data);
    final token = _findToken(map);
    if (token == null || token.isEmpty) return null;

    final expiresAt =
        _findExpiresAt(map, token) ??
        _fallbackExpiry(token, source: 'login response');

    return UserSession(
      token: token,
      expiresAt: expiresAt,
      userData: _enrichUserFromJwt(_findUserData(map), token),
    );
  }

  String? _findToken(Map<String, dynamic> map) {
    const keys = ['accessToken', 'access_token', 'token', 'jwt', 'authToken'];

    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
    }

    for (final nestedKey in ['data', 'user', 'result', 'auth']) {
      final nested = map[nestedKey];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        final token = _findToken(nestedMap);
        if (token != null) return token;
      }
    }

    return null;
  }

  DateTime? _findExpiresAt(Map<String, dynamic> map, String token) {
    final direct = _readExpiresAt(map);
    if (direct != null) return direct;

    for (final nestedKey in ['data', 'user', 'result', 'auth']) {
      final nested = map[nestedKey];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        final expiresAt = _readExpiresAt(nestedMap);
        if (expiresAt != null) return expiresAt;
      }
    }

    final jwtExpiry = _readJwtExpiry(token);
    if (jwtExpiry != null) return jwtExpiry;

    return _fallbackExpiry(token, source: 'stored token');
  }

  DateTime? _readExpiresAt(Map<String, dynamic> map) {
    const dateKeys = [
      'expiresAt',
      'expireAt',
      'expiredAt',
      'tokenExpireAt',
      'tokenExpiresAt',
    ];

    for (final key in dateKeys) {
      final value = map[key];
      final parsed = _parseDateTime(value);
      if (parsed != null) return parsed;
    }

    const durationKeys = ['expiresIn', 'expires_in', 'expireIn', 'expire_in'];
    for (final key in durationKeys) {
      final value = map[key];
      if (value is num && value > 0) {
        return DateTime.now().add(Duration(seconds: value.toInt()));
      }
    }

    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  Map<String, dynamic>? _readJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  DateTime? _readJwtExpiry(String token) {
    final payload = _readJwtPayload(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    }

    return null;
  }

  DateTime _fallbackExpiry(String token, {required String source}) {
    final payload = _readJwtPayload(token);
    final iat = payload?['iat'];
    if (iat is num) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(iat.toInt() * 1000)
          .add(defaultTokenTtl);
      debugPrint(
        '[Auth] Token không có exp ($source), dùng iat + ${defaultTokenTtl.inDays} ngày',
      );
      return expiresAt;
    }

    final expiresAt = DateTime.now().add(defaultTokenTtl);
    debugPrint(
      '[Auth] Token không có exp ($source), dùng mặc định ${defaultTokenTtl.inDays} ngày',
    );
    return expiresAt;
  }

  Map<String, dynamic>? _normalizeStoredUserData(
    Map<String, dynamic> raw,
    String token,
  ) {
    if (_looksLikeUserProfile(raw)) {
      return _enrichUserFromJwt(raw, token);
    }

    final extracted = _findUserData(raw);
    return _enrichUserFromJwt(extracted, token);
  }

  bool _looksLikeUserProfile(Map<String, dynamic> map) {
    return map['email'] is String ||
        map['full_name'] is String ||
        map['fullName'] is String;
  }

  Map<String, dynamic>? _findUserData(Map<String, dynamic> map) {
    final user = map['user'];
    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }

    for (final nestedKey in ['data', 'result', 'auth']) {
      final nested = map[nestedKey];
      if (nested is Map) {
        final found = _findUserData(Map<String, dynamic>.from(nested));
        if (found != null) return found;
      }
    }

    return null;
  }

  Map<String, dynamic>? _enrichUserFromJwt(
    Map<String, dynamic>? user,
    String token,
  ) {
    if (user == null) return null;

    final payload = _readJwtPayload(token);
    if (payload == null) return user;

    final enriched = Map<String, dynamic>.from(user);

    const jwtToUserKeys = {
      'avatar_url': ['avatar_url', 'avatarUrl'],
      'full_name': ['full_name', 'fullName', 'name'],
      'email': ['email'],
      'role': ['role'],
    };

    for (final entry in jwtToUserKeys.entries) {
      final jwtValue = payload[entry.key];
      if (jwtValue is! String || jwtValue.isEmpty) continue;

      final hasValue = entry.value.any((key) {
        final current = enriched[key];
        return current is String && current.isNotEmpty;
      });
      if (!hasValue) {
        enriched[entry.value.first] = jwtValue;
      }
    }

    return enriched;
  }
}
