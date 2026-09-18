import 'package:flutter/material.dart';
import 'package:ofocus/theme/app_colors.dart';
import 'package:ofocus/utils/text_search.dart';

class EnrolledClass {
  const EnrolledClass({
    required this.title,
    required this.instructor,
    required this.progressLabel,
    required this.progressValue,
    required this.progressColor,
    required this.footerNote,
    this.classId,
  });

  final int? classId;
  final String title;
  final String instructor;
  final String progressLabel;
  final double progressValue;
  final Color progressColor;
  final String footerNote;

  bool matchesQuery(String query) => textMatchesQuery(title, query);

  factory EnrolledClass.fromJson(Map<String, dynamic> json) {
    final title = _readString(json, [
      'title',
      'name',
      'class_name',
      'className',
      'class_title',
      'classTitle',
      'course_name',
      'courseName',
      'ten_lop',
      'tenLop',
      'mon_hoc',
      'monHoc',
      'subject',
      'subject_name',
      'subjectName',
    ]);

    final instructor = _readString(json, [
      'instructor',
      'instructor_name',
      'instructorName',
      'teacher_name',
      'teacherName',
      'teacher',
      'giang_vien',
      'giangVien',
      'ten_giang_vien',
      'tenGiangVien',
    ]) ??
        _readNestedString(json, ['instructor', 'teacher', 'giang_vien'], [
          'name',
          'full_name',
          'fullName',
          'title',
        ]);

    final completed = _readNum(json, [
      'completed_sessions',
      'completedSessions',
      'completed_lessons',
      'completedLessons',
      'attended_sessions',
      'so_buoi_hoan_thanh',
    ]);

    final total = _readNum(json, [
      'total_sessions',
      'totalSessions',
      'total_lessons',
      'totalLessons',
      'session_count',
      'tong_buoi',
    ]);

    var progress = _readDouble(json, [
      'progress',
      'progress_value',
      'progressValue',
      'progress_percent',
      'progressPercent',
      'tien_do',
    ]);

    if (progress <= 0 && total > 0) {
      progress = completed / total;
    } else if (progress > 1) {
      progress = progress / 100;
    }

    progress = progress.clamp(0.0, 1.0);

    final progressLabel = _readString(json, [
      'progress_label',
      'progressLabel',
    ]) ??
        (total > 0
            ? '${completed.toInt()}/${total.toInt()} buổi (${(progress * 100).round()}%)'
            : '${(progress * 100).round()}%');

    final footerNote = _readString(json, [
      'footer_note',
      'footerNote',
      'schedule',
      'schedule_note',
      'scheduleNote',
      'note',
      'lich_hoc',
      'lichHoc',
      'description',
      'mo_ta',
    ]);

    final resolvedTitle = title ?? 'Lớp học';
    final resolvedInstructor = instructor ?? '';
    final resolvedFooter = footerNote ?? '';

    return EnrolledClass(
      classId: _readInt(json, ['class_id', 'classId', 'id']),
      title: resolvedTitle,
      instructor: resolvedInstructor,
      progressLabel: progressLabel,
      progressValue: progress,
      progressColor: progress >= 0.6 ? AppColors.success : AppColors.primary,
      footerNote: resolvedFooter,
    );
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

  static String? _readNestedString(
    Map<String, dynamic> map,
    List<String> objectKeys,
    List<String> valueKeys,
  ) {
    for (final objectKey in objectKeys) {
      final nested = map[objectKey];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        final value = _readString(nestedMap, valueKeys);
        if (value != null) return value;
      }
    }
    return null;
  }

  static num _readNum(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value;
    }
    return 0;
  }

  static double _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
    }
    return 0;
  }
}
