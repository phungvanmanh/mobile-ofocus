enum DailyScheduleStatus { live, upcoming, past }

/// Item from `GET class-schedule/mine?date=YYYY-MM-DD`.
class DailyClassSchedule {
  const DailyClassSchedule({
    required this.startTime,
    required this.endTime,
    required this.className,
    required this.instructorName,
  });

  final DateTime startTime;
  final DateTime endTime;
  final String className;
  final String instructorName;

  factory DailyClassSchedule.fromJson(Map<String, dynamic> json) {
    return DailyClassSchedule(
      startTime: _parseDateTime(json['start_time'] ?? json['startTime']),
      endTime: _parseDateTime(json['end_time'] ?? json['endTime']),
      className: _readString(json, ['class_name', 'className', 'title']),
      instructorName: _readString(json, [
        'full_name',
        'fullName',
        'teacher_name',
        'teacherName',
        'instructor',
      ]),
    );
  }

  String get timeRange =>
      '${_formatClock(startTime)} - ${_formatClock(endTime)}';

  DailyScheduleStatus statusAt(DateTime now) {
    if (now.isAfter(endTime)) return DailyScheduleStatus.past;
    if (now.isBefore(startTime)) return DailyScheduleStatus.upcoming;
    return DailyScheduleStatus.live;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized) ??
        DateTime.tryParse('$normalized:00') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static String _formatClock(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
