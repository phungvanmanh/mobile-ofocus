import 'package:flutter/material.dart';
import 'package:ofocus/models/classroom_session.dart';
import 'package:ofocus/screens/classroom/classroom_screen.dart';
import 'package:ofocus/screens/classroom/classroom_waiting_screen.dart';

/// Route names and navigation helpers for the app.
abstract final class AppRoutes {
  static const auth = '/';
  static const login = '/login';
  static const home = '/home';
  static const forgotPassword = '/forgot-password';
  static const classroomWaiting = '/classroom/waiting';
  static const classroom = '/classroom';

  static Route<bool> toClassroomWaiting({
    ClassSession session = const ClassSession(),
  }) {
    return MaterialPageRoute<bool>(
      builder: (_) => ClassroomWaitingScreen(session: session),
    );
  }

  static Route<bool> toClassroom({ClassSession session = const ClassSession()}) {
    return MaterialPageRoute<bool>(
      builder: (_) => ClassroomScreen(session: session),
    );
  }
}
