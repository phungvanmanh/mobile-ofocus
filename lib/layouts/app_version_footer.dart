import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/theme/app_colors.dart';

class AppVersionFooter extends StatelessWidget {
  const AppVersionFooter({super.key, this.version = 'v2.4.1 (Build 8902)'});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Phiên bản OFocus $version',
      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
    );
  }
}
