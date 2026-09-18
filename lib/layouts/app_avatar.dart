import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ofocus/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.avatarUrl,
    this.avatarFilePath,
    this.size = 32,
    this.showBorder = true,
    this.onTap,
  });

  final String? avatarUrl;
  final String? avatarFilePath;
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (!showBorder) {
      avatar = SizedBox(
        width: size,
        height: size,
        child: ClipOval(child: _buildImage()),
      );
    } else {
      avatar = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: ClipOval(child: _buildImage()),
      );
    }

    if (onTap == null) return avatar;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }

  Widget _buildImage() {
    if (avatarFilePath != null && avatarFilePath!.isNotEmpty) {
      return Image.file(
        File(avatarFilePath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        key: ValueKey(avatarUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Image.asset(
      'assets/home/images/profile.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
