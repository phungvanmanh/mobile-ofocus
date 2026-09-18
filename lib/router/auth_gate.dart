import 'package:flutter/material.dart';
import 'package:ofocus/screens/home_screen.dart';
import 'package:ofocus/screens/login_screen.dart';
import 'package:ofocus/services/session_manager.dart';
import 'package:ofocus/theme/app_colors.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _sessionManager = SessionManager();
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    final session = await _sessionManager.loadSession();

    if (!mounted) return;

    if (session != null && session.isValid) {
      _sessionManager.logSessionExpiry(session);
      setState(
        () => _screen = HomeScreen(
          userData: session.userData,
          sessionManager: _sessionManager,
        ),
      );
      return;
    }

    if (session != null) {
      debugPrint('[Auth] Token đã hết hạn, yêu cầu đăng nhập lại');
      await _sessionManager.clearSession();
    }

    setState(() => _screen = const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return _screen ??
        const Scaffold(
          backgroundColor: Color(0xFFF8FAFF),
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryIndigo),
          ),
        );
  }
}
