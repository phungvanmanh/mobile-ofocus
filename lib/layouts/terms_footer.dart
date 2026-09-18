import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsFooter extends StatelessWidget {
  const TermsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.inter(
      fontSize: 11,
      height: 1.5,
      color: const Color(0xFF94A3B8),
    );
    final linkStyle = baseStyle.copyWith(
      color: const Color(0xFF475569),
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(text: 'Bằng việc tiếp tục, bạn đồng ý với '),
            TextSpan(text: 'Điều khoản dịch vụ', style: linkStyle),
            const TextSpan(text: ' và '),
            TextSpan(text: 'Chính sách bảo mật', style: linkStyle),
            const TextSpan(text: ' của OFocus.'),
          ],
        ),
      ),
    );
  }
}
