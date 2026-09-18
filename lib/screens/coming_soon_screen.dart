import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/layouts/app_header.dart';
import 'package:ofocus/layouts/app_page_scaffold.dart';
import 'package:ofocus/theme/app_colors.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    this.avatarUrl,
    this.onAvatarTap,
  });

  final String title;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      header: AppHeader.tab(
        title,
        avatarUrl: avatarUrl,
        onAvatarTap: onAvatarTap,
      ),
      body: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.5,
        child: Center(
          child: Text(
            '$title\n(Đang phát triển)',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
