import 'package:flutter/material.dart';

/// Design tokens shared across the app (OFOCUS-2).
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF3525CD);
  static const primaryIndigo = Color(0xFF4F46E5);
  static const primaryDeep = Color(0xFF0F0069);
  static const primaryDark = Color(0xFF3323CC);
  static const lavender = Color(0xFFDAD7FF);

  // Background & surfaces
  static const background = Color(0xFFFAF8FF);
  static const backgroundAlt = Color(0xFFF8FAFF);
  static const surface = Color(0xFFF2F3FF);
  static const surfaceMuted = Color(0xFFEAEDFF);
  static const surfaceBorder = Color(0xFFE2E7FF);
  static const surfaceAccent = Color(0xFFE2DFFF);
  static const onDarkSurface = Color(0xFFEEF0FF);

  // Text
  static const textPrimary = Color(0xFF131B2E);
  static const textSecondary = Color(0xFF464555);
  static const textMuted = Color(0xFF777587);
  static const textHint = Color(0xFF94A3B8);
  static const textDisabled = Color(0xFFC7C4D8);

  // Semantic
  static const success = Color(0xFF006C49);
  static const successLight = Color(0xFF6CF8BB);
  static const successBadge = Color(0xFF6FFBBE);
  static const successOn = Color(0xFF00714D);
  static const successDark = Color(0xFF002113);

  static const error = Color(0xFFBA1A1A);
  static const errorSurface = Color(0xFFFFDAD6);

  static const warning = Color(0xFFFFDDB8);
  static const warningOn = Color(0xFF2A1700);

  // Classroom
  static const classroomBg = Color(0xFF283044);
  static const classroomBgDark = Color(0xFF1A202C);
  static const classroomTile = Color(0xFF3A4560);

  // Utility
  static const cardBorder = Color(0xFFF1F5F9);
  static const divider = Color(0xFFE2E8F0);
  static const shadow = Color(0x0D000000);
  static const shadowMedium = Color(0x1A000000);
}
