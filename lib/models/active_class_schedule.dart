/// Lớp đang live — map từ `GET class-schedule/active`.
///
/// Response mẫu:
/// ```json
/// {
///   "class_id": 30,
///   "class_name": "trádas",
///   "teacher_name": "Văn Mạnh Phùng",
///   "time_zone": "+07:00",
///   "room_code": "LHEPV5H7",
///   "class_schedule_id": 805
/// }
/// ```
class ActiveClassSchedule {
  const ActiveClassSchedule({
    required this.classId,
    required this.title,
    required this.instructor,
    required this.roomCode,
    this.classScheduleId,
    this.timeZone,
    this.category = '',
    this.sessionLabel = '',
    this.onlineLabel = '',
    this.onlineCount,
    this.maxCapacity,
  });

  final int classId;
  final int? classScheduleId;
  final String title;
  final String instructor;
  final String roomCode;
  final String? timeZone;
  final String category;
  final String sessionLabel;
  final String onlineLabel;
  final int? onlineCount;
  final int? maxCapacity;

  factory ActiveClassSchedule.fromJson(Map<String, dynamic> json) {
    final classId = _readInt(json, ['class_id', 'classId']);
    final title = _readString(json, ['class_name', 'className', 'title', 'name']);
    final instructor = _readString(json, [
      'teacher_name',
      'teacherName',
      'teacher',
      'instructor_name',
      'instructorName',
      'instructor',
    ]);
    final roomCode = _readString(json, [
      'room_code',
      'roomCode',
      'room_name',
      'roomName',
    ]);
    final timeZone = _readString(json, ['time_zone', 'timeZone']);

    final category = _readString(json, [
      'category',
      'category_name',
      'subject',
      'subject_name',
    ]);

    final currentSession = _readInt(json, [
      'session_number',
      'current_session',
      'session_index',
    ]);
    final totalSessions = _readInt(json, [
      'total_sessions',
      'session_count',
      'quantity',
    ]);

    final onlineCount = _readInt(json, [
      'online_count',
      'participant_count',
      'participants_online',
    ]);
    final maxCapacity = _readInt(json, [
      'max_participants',
      'max_capacity',
      'capacity',
    ]);

    return ActiveClassSchedule(
      classId: classId ?? 0,
      classScheduleId: _readInt(json, [
        'class_schedule_id',
        'classScheduleId',
        'schedule_id',
        'scheduleId',
      ]),
      title: title ?? 'Lớp học',
      instructor: instructor ?? '',
      roomCode: roomCode ?? '',
      timeZone: timeZone,
      category: (category ?? '').toUpperCase(),
      sessionLabel: _readString(json, ['session_label']) ??
          _formatSessionLabel(currentSession, totalSessions),
      onlineLabel: _readString(json, ['online_label']) ??
          _formatOnlineLabel(onlineCount, maxCapacity),
      onlineCount: onlineCount,
      maxCapacity: maxCapacity,
    );
  }

  static String _formatSessionLabel(int? current, int? total) {
    if (current != null && total != null && total > 0) {
      return 'BUỔI $current/$total';
    }
    if (current != null) return 'BUỔI $current';
    return '';
  }

  static String _formatOnlineLabel(int? online, int? max) {
    if (online != null && max != null && max > 0) {
      return '$online/$max online';
    }
    if (online != null) return '$online online';
    return '';
  }

  static int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
