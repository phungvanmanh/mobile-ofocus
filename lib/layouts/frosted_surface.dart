import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ofocus/theme/app_colors.dart';

class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.background,
    this.backgroundOpacity = 0.85,
    this.boxShadow = const [
      BoxShadow(
        color: Color(0x08000000),
        blurRadius: 8,
        offset: Offset(0, 1),
      ),
    ],
    this.blurSigma = 12,
  });

  final Widget child;
  final Color backgroundColor;
  final double backgroundOpacity;
  final List<BoxShadow> boxShadow;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: backgroundOpacity),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
