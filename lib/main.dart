import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ofocus/config/api_config.dart';
import 'package:ofocus/router/auth_gate.dart';
import 'package:ofocus/theme/app_theme.dart';
import 'package:ofocus/utils/no_stretch_scroll_behavior.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('[ApiConfig] ${ApiConfig.label}');
    debugPrint('[ApiConfig] login → ${ApiConfig.login}');
  }
  runApp(const OFocusApp());
}

class OFocusApp extends StatelessWidget {
  const OFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'oFocus',
      scrollBehavior: const NoStretchScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
