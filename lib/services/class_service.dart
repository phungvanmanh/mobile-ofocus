import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ofocus/config/api_config.dart';
import 'package:ofocus/models/active_class_schedule.dart';
import 'package:ofocus/models/daily_class_schedule.dart';
import 'package:ofocus/models/enrolled_class.dart';
import 'package:ofocus/services/api_client.dart';
import 'package:ofocus/services/session_manager.dart';

class ClassService {
  ClassService({SessionManager? sessionManager})
    : _sessionManager = sessionManager ?? SessionManager();

  final SessionManager _sessionManager;

  Future<String?> _resolveAuthToken() async {
    await _sessionManager.loadSession();
    final token = await _sessionManager.getAuthToken();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Future<http.Response> _authGet(String url) async {
    final token = await _resolveAuthToken();
    if (token == null) {
      throw StateError('missing_auth_token');
    }

    debugPrint('[ClassService] GET $url (Authorization: Bearer ***)');

    return http.get(
      Uri.parse(url),
      headers: ApiClient.authHeaders(token),
    );
  }

  Future<ActiveScheduleListResult> fetchActiveSchedules() async {
    final token = await _sessionManager.getAuthToken();
    if (token == null || token.isEmpty) {
      return ActiveScheduleListResult.failure('Phiên đăng nhập không hợp lệ');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.classScheduleActive),
        headers: ApiClient.authHeaders(token),
      );

      debugPrint(
        '[ClassService] GET ${ApiConfig.classScheduleActive} → ${response.statusCode}',
      );

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return ActiveScheduleListResult.failure(
          'Phản hồi không hợp lệ từ máy chủ',
        );
      }

      if (!_isSuccess(body)) {
        return ActiveScheduleListResult.failure(_extractErrorMessage(body));
      }

      final items = _extractList(body['data']);
      final schedules =
          items.map(ActiveClassSchedule.fromJson).toList(growable: false);

      return ActiveScheduleListResult.success(schedules);
    } catch (error, stack) {
      debugPrint('[ClassService] fetchActiveSchedules error: $error');
      debugPrint('$stack');
      return ActiveScheduleListResult.failure(
        'Không thể tải lớp đang diễn ra',
      );
    }
  }

  Future<DailyScheduleListResult> fetchMySchedulesByDate(DateTime date) async {
    final dateKey = formatApiDate(date);
    final url = ApiConfig.classScheduleMine(dateKey);

    try {
      final response = await _authGet(url);

      debugPrint('[ClassService] GET $url → ${response.statusCode}');

      if (response.statusCode == 401) {
        return DailyScheduleListResult.failure(
          'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
        );
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return DailyScheduleListResult.failure(
          'Phản hồi không hợp lệ từ máy chủ',
        );
      }

      if (!_isSuccess(body)) {
        return DailyScheduleListResult.failure(
          _extractErrorMessage(body, fallback: 'Không thể tải lịch học'),
        );
      }

      final items = _extractList(body['data']);
      final schedules = items
          .map(DailyClassSchedule.fromJson)
          .toList(growable: false)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      return DailyScheduleListResult.success(schedules);
    } on StateError catch (error) {
      if ('$error'.contains('missing_auth_token')) {
        return DailyScheduleListResult.failure('Phiên đăng nhập không hợp lệ');
      }
      rethrow;
    } catch (error, stack) {
      debugPrint('[ClassService] fetchMySchedulesByDate error: $error');
      debugPrint('$stack');
      return DailyScheduleListResult.failure('Không thể tải lịch học');
    }
  }

  static String formatApiDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  Future<ClassListResult> fetchMyClasses() async {
    final token = await _sessionManager.getAuthToken();
    if (token == null || token.isEmpty) {
      return ClassListResult.failure('Phiên đăng nhập không hợp lệ');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.classMine),
        headers: ApiClient.authHeaders(token),
      );

      debugPrint(
        '[ClassService] GET ${ApiConfig.classMine} → ${response.statusCode}',
      );

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return ClassListResult.failure('Phản hồi không hợp lệ từ máy chủ');
      }

      if (!_isSuccess(body)) {
        return ClassListResult.failure(_extractErrorMessage(body));
      }

      final items = _extractList(body['data']);
      // if (kDebugMode && items.isNotEmpty) {
      //   debugPrint('[ClassService] sample item: ${items.first}');
      // }
      final classes = items.map(EnrolledClass.fromJson).toList();

      return ClassListResult.success(classes);
    } catch (error, stack) {
      debugPrint('[ClassService] fetchMyClasses error: $error');
      debugPrint('$stack');
      return ClassListResult.failure('Không thể tải danh sách lớp học');
    }
  }

  Future<CreateClassResult> createClass({
    required String className,
    required int quantity,
  }) async {
    final token = await _sessionManager.getAuthToken();
    if (token == null || token.isEmpty) {
      return CreateClassResult.failure('Phiên đăng nhập không hợp lệ');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.classCreate),
        headers: ApiClient.authHeaders(token),
        body: jsonEncode({
          'class_name': className,
          'quantity': quantity,
        }),
      );

      debugPrint(
        '[ClassService] POST ${ApiConfig.classCreate} → ${response.statusCode}',
      );

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return CreateClassResult.failure('Phản hồi không hợp lệ từ máy chủ');
      }

      if (!_isSuccess(body)) {
        return CreateClassResult.failure(
          _extractErrorMessage(body, fallback: 'Không thể tạo lớp học'),
        );
      }

      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        return CreateClassResult.failure('Phản hồi không hợp lệ từ máy chủ');
      }

      return CreateClassResult.success(data);
    } catch (error, stack) {
      debugPrint('[ClassService] createClass error: $error');
      debugPrint('$stack');
      return CreateClassResult.failure('Không thể tạo lớp học');
    }
  }

  Future<DeleteClassResult> deleteClass(int classId) async {
    final token = await _sessionManager.getAuthToken();
    if (token == null || token.isEmpty) {
      return DeleteClassResult.failure('Phiên đăng nhập không hợp lệ');
    }

    try {
      final url = ApiConfig.classDelete(classId);
      final response = await http.delete(
        Uri.parse(url),
        headers: ApiClient.authHeaders(token),
      );

      debugPrint('[ClassService] DELETE $url → ${response.statusCode}');

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return DeleteClassResult.failure('Phản hồi không hợp lệ từ máy chủ');
      }

      if (!_isSuccess(body)) {
        return DeleteClassResult.failure(
          _extractErrorMessage(body, fallback: 'Không thể xóa lớp học'),
        );
      }

      final data = body['data'];
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return DeleteClassResult.success(message);
        }
      }

      return DeleteClassResult.success('Xóa lớp thành công');
    } catch (error, stack) {
      debugPrint('[ClassService] deleteClass error: $error');
      debugPrint('$stack');
      return DeleteClassResult.failure('Không thể xóa lớp học');
    }
  }

  Future<CloseClassScheduleResult> closeClassSchedule({
    required int classScheduleId,
  }) async {
    final token = await _sessionManager.getAuthToken();
    if (token == null || token.isEmpty) {
      return CloseClassScheduleResult.failure('Phiên đăng nhập không hợp lệ');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.classScheduleClosed),
        headers: ApiClient.authHeaders(token),
        body: jsonEncode({
          'class_schedule_id': classScheduleId,
        }),
      );

      debugPrint(
        '[ClassService] POST ${ApiConfig.classScheduleClosed} → ${response.statusCode}',
      );

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return CloseClassScheduleResult.failure(
          'Phản hồi không hợp lệ từ máy chủ',
        );
      }

      if (!_isSuccess(body)) {
        return CloseClassScheduleResult.failure(
          _extractErrorMessage(
            body,
            fallback: 'Không thể kết thúc phòng học',
          ),
        );
      }

      final data = body['data'];
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return CloseClassScheduleResult.success(message);
        }
      }

      return CloseClassScheduleResult.success('Đã thoát phòng học thành công');
    } catch (error, stack) {
      debugPrint('[ClassService] closeClassSchedule error: $error');
      debugPrint('$stack');
      return CloseClassScheduleResult.failure('Không thể kết thúc phòng học');
    }
  }

  Future<SpecialScheduleResult> createSpecialSchedule({
    required int classId,
    DateTime? startTime,
  }) async {
    final token = await _sessionManager.getAuthToken();
    if (token == null || token.isEmpty) {
      return SpecialScheduleResult.failure('Phiên đăng nhập không hợp lệ');
    }

    final scheduledAt = startTime ?? DateTime.now();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.classScheduleSpecial),
        headers: ApiClient.authHeaders(token),
        body: jsonEncode({
          'class_id': classId,
          'start_time': _formatApiDateTime(scheduledAt),
          'time_zone': _formatTimeZoneOffset(scheduledAt),
        }),
      );

      debugPrint(
        '[ClassService] POST ${ApiConfig.classScheduleSpecial} → ${response.statusCode}',
      );

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return SpecialScheduleResult.failure('Phản hồi không hợp lệ từ máy chủ');
      }

      if (!_isSuccess(body)) {
        return SpecialScheduleResult.failure(
          _extractErrorMessage(
            body,
            fallback: 'Không thể tạo phòng học',
          ),
        );
      }

      final data = body['data'];
      if (data is Map) {
        final roomCode = data['room_code'];
        if (roomCode is String && roomCode.isNotEmpty) {
          final scheduleId = data['class_schedule_id'] ?? data['classScheduleId'];
          int? classScheduleId;
          if (scheduleId is int) {
            classScheduleId = scheduleId;
          } else if (scheduleId is num) {
            classScheduleId = scheduleId.toInt();
          } else if (scheduleId is String) {
            classScheduleId = int.tryParse(scheduleId);
          }

          return SpecialScheduleResult.success(
            roomCode: roomCode,
            classScheduleId: classScheduleId,
          );
        }
      }

      return SpecialScheduleResult.failure('Phản hồi không hợp lệ từ máy chủ');
    } catch (error, stack) {
      debugPrint('[ClassService] createSpecialSchedule error: $error');
      debugPrint('$stack');
      return SpecialScheduleResult.failure('Không thể tạo phòng học');
    }
  }

  static String _formatApiDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  static String _formatTimeZoneOffset(DateTime value) {
    final offset = value.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final totalMinutes = offset.inMinutes.abs();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '$sign${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  bool _isSuccess(Map<String, dynamic> body) {
    final meta = body['meta'];
    if (meta is Map && meta.containsKey('success')) {
      return meta['success'] == true;
    }
    return true;
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map) {
      final nested = data['data'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  String _extractErrorMessage(
    Map<String, dynamic> body, {
    String fallback = 'Không thể tải danh sách lớp học',
  }) {
    final meta = body['meta'];
    if (meta is Map) {
      final external = meta['externalMessage'];
      if (external is String && external.isNotEmpty && external != 'Error') {
        return external;
      }
    }
    return fallback;
  }
}

class DailyScheduleListResult {
  const DailyScheduleListResult._({
    required this.isSuccess,
    this.schedules = const [],
    this.errorMessage,
  });

  factory DailyScheduleListResult.success(List<DailyClassSchedule> schedules) {
    return DailyScheduleListResult._(
      isSuccess: true,
      schedules: schedules,
    );
  }

  factory DailyScheduleListResult.failure(String message) {
    return DailyScheduleListResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  final bool isSuccess;
  final List<DailyClassSchedule> schedules;
  final String? errorMessage;
}

class ActiveScheduleListResult {
  const ActiveScheduleListResult._({
    required this.isSuccess,
    this.schedules = const [],
    this.errorMessage,
  });

  factory ActiveScheduleListResult.success(
    List<ActiveClassSchedule> schedules,
  ) {
    return ActiveScheduleListResult._(
      isSuccess: true,
      schedules: schedules,
    );
  }

  factory ActiveScheduleListResult.failure(String message) {
    return ActiveScheduleListResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  final bool isSuccess;
  final List<ActiveClassSchedule> schedules;
  final String? errorMessage;
}

class CloseClassScheduleResult {
  const CloseClassScheduleResult._({
    required this.isSuccess,
    this.message,
    this.errorMessage,
  });

  factory CloseClassScheduleResult.success(String message) {
    return CloseClassScheduleResult._(isSuccess: true, message: message);
  }

  factory CloseClassScheduleResult.failure(String message) {
    return CloseClassScheduleResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  final bool isSuccess;
  final String? message;
  final String? errorMessage;
}

class SpecialScheduleResult {
  const SpecialScheduleResult._({
    required this.isSuccess,
    this.roomCode,
    this.classScheduleId,
    this.errorMessage,
  });

  factory SpecialScheduleResult.success({
    required String roomCode,
    int? classScheduleId,
  }) {
    return SpecialScheduleResult._(
      isSuccess: true,
      roomCode: roomCode,
      classScheduleId: classScheduleId,
    );
  }

  factory SpecialScheduleResult.failure(String message) {
    return SpecialScheduleResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final String? roomCode;
  final int? classScheduleId;
  final String? errorMessage;
}

class DeleteClassResult {
  const DeleteClassResult._({
    required this.isSuccess,
    this.message,
    this.errorMessage,
  });

  factory DeleteClassResult.success(String message) {
    return DeleteClassResult._(isSuccess: true, message: message);
  }

  factory DeleteClassResult.failure(String message) {
    return DeleteClassResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final String? message;
  final String? errorMessage;
}

class CreateClassResult {
  const CreateClassResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory CreateClassResult.success(Map<String, dynamic> data) {
    return CreateClassResult._(isSuccess: true, data: data);
  }

  factory CreateClassResult.failure(String message) {
    return CreateClassResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? errorMessage;
}

class ClassListResult {
  const ClassListResult._({
    required this.isSuccess,
    this.classes = const [],
    this.errorMessage,
  });

  factory ClassListResult.success(List<EnrolledClass> classes) {
    return ClassListResult._(isSuccess: true, classes: classes);
  }

  factory ClassListResult.failure(String message) {
    return ClassListResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final List<EnrolledClass> classes;
  final String? errorMessage;
}
