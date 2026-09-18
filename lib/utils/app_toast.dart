import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ofocus/theme/app_colors.dart';

enum AppToastStatus { success, error, warning, info }

void showAppToast(
  String message, {
  AppToastStatus status = AppToastStatus.info,
}) {
  final (backgroundColor, textColor) = switch (status) {
    AppToastStatus.success => (AppColors.success, Colors.white),
    AppToastStatus.error => (AppColors.error, Colors.white),
    AppToastStatus.warning => (AppColors.warning, AppColors.warningOn),
    AppToastStatus.info => (AppColors.textPrimary, Colors.white),
  };

  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    backgroundColor: backgroundColor,
    textColor: textColor,
  );
}
