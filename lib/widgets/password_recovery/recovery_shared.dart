import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/theme/app_colors.dart';

/// Password-recovery aliases — prefer [AppColors] in new code.
abstract final class RecoveryColors {
  static const background = AppColors.background;
  static const primary = AppColors.primary;
  static const success = AppColors.success;
  static const title = AppColors.textPrimary;
  static const body = AppColors.textSecondary;
  static const muted = AppColors.textHint;
  static const inputBg = AppColors.surface;
  static const cardBorder = AppColors.cardBorder;
  static const error = AppColors.error;
  static const errorFill = Color(0x40FFDAD6);
}

class RecoveryInlineError extends StatelessWidget {
  const RecoveryInlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: RecoveryColors.error,
        ),
      ),
    );
  }
}

class RecoveryScaffold extends StatelessWidget {
  const RecoveryScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecoveryColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 30, 16, 24),
          child: child,
        ),
      ),
    );
  }
}

class RecoverySvgIcon extends StatelessWidget {
  const RecoverySvgIcon(this.name, {this.width, this.height, super.key});

  final String name;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/password_reset/icons/$name.svg',
      width: width,
      height: height,
    );
  }
}

class RecoveryStepHeader extends StatelessWidget {
  const RecoveryStepHeader({
    super.key,
    required this.step,
    this.variant = RecoveryStepperVariant.bar,
  });

  final int step;
  final RecoveryStepperVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          variant == RecoveryStepperVariant.circles ? 16 : 12,
        ),
        border: variant == RecoveryStepperVariant.circles
            ? Border.all(color: RecoveryColors.cardBorder)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BƯỚC $step / 3',
                style: GoogleFonts.inter(
                  fontSize: variant == RecoveryStepperVariant.circles ? 12 : 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: variant == RecoveryStepperVariant.circles
                      ? 0.6
                      : 0.5,
                  color: RecoveryColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (variant == RecoveryStepperVariant.circles)
            _CircleStepper(activeStep: step)
          else
            _BarStepper(activeStep: step),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StepLabel(
                  'Gửi mã',
                  color: step == 1
                      ? RecoveryColors.primary
                      : step > 1
                      ? RecoveryColors.success
                      : RecoveryColors.muted,
                  align: TextAlign.start,
                ),
              ),
              Expanded(
                child: _StepLabel(
                  'Xác thực OTP',
                  color: step == 2
                      ? RecoveryColors.primary
                      : step > 2
                      ? RecoveryColors.success
                      : RecoveryColors.muted,
                  align: TextAlign.center,
                ),
              ),
              Expanded(
                child: _StepLabel(
                  'Đổi mật khẩu',
                  color: step == 3
                      ? RecoveryColors.primary
                      : RecoveryColors.muted,
                  align: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum RecoveryStepperVariant { circles, bar }

class _StepLabel extends StatelessWidget {
  const _StepLabel(this.text, {required this.color, required this.align});

  final String text;
  final Color color;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: color == RecoveryColors.primary
            ? FontWeight.w700
            : FontWeight.w500,
        color: color,
      ),
    );
  }
}

class _CircleStepper extends StatelessWidget {
  const _CircleStepper({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 36,
            right: 176,
            top: 16,
            child: Container(height: 4, color: const Color(0xFFE2E8F0)),
          ),
          Positioned(
            left: 176,
            right: 36,
            top: 16,
            child: Container(height: 4, color: const Color(0xFFE2E8F0)),
          ),
          Positioned(
            left: 8,
            child: _StepCircle(number: 1, activeStep: activeStep),
          ),
          Positioned(
            left: 148,
            child: _StepCircle(number: 2, activeStep: activeStep),
          ),
          Positioned(
            left: 288,
            child: _StepCircle(number: 3, activeStep: activeStep),
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.number, required this.activeStep});

  final int number;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final filled = number == activeStep;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: filled ? RecoveryColors.primary : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: RecoveryColors.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : RecoveryColors.muted,
        ),
      ),
    );
  }
}

class _BarStepper extends StatelessWidget {
  const _BarStepper({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _BarStepSegment(step: 1, activeStep: activeStep)),
        const SizedBox(width: 4),
        Expanded(child: _BarStepSegment(step: 2, activeStep: activeStep)),
        const SizedBox(width: 4),
        Expanded(child: _BarStepSegment(step: 3, activeStep: activeStep)),
      ],
    );
  }
}

class _BarStepSegment extends StatelessWidget {
  const _BarStepSegment({required this.step, required this.activeStep});

  final int step;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final completed = step < activeStep;
    final active = step == activeStep;
    final upcoming = step > activeStep;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: completed
                ? RecoveryColors.success
                : active
                ? RecoveryColors.primary
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: upcoming
                ? Border.all(color: const Color(0xFFE2E8F0))
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: completed
              ? const RecoverySvgIcon('09465', width: 10.87, height: 8.02)
              : Text(
                  '$step',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : RecoveryColors.muted,
                  ),
                ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              color: const Color(0xFFE2E8F0),
              child: completed || active
                  ? Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: completed ? 1 : 0.5,
                      child: Container(
                        color: completed
                            ? RecoveryColors.success
                            : RecoveryColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class RecoveryPrimaryButton extends StatelessWidget {
  const RecoveryPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: RecoveryColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: RecoveryColors.primary.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.14,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              const RecoverySvgIcon('03d99', width: 12, height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class RecoveryBackToLoginButton extends StatelessWidget {
  const RecoveryBackToLoginButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFEAEDFF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RecoverySvgIcon('a5c32', width: 12, height: 12),
          const SizedBox(width: 4),
          Text(
            'Quay lại trang Đăng nhập',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.24,
              color: RecoveryColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentSupportCard extends StatelessWidget {
  const StudentSupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const RecoverySvgIcon('46eb7', width: 15, height: 13.5),
                  const SizedBox(width: 6),
                  Text(
                    'Hỗ trợ học viên 24/7',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.24,
                      color: RecoveryColors.title,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FFBBE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Đang trực tuyến',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF002113),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Gặp khó khăn khi nhận mã khôi phục hoặc mất quyền\ntruy cập email?',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.625,
              color: RecoveryColors.body,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const RecoverySvgIcon('3ecc3', width: 12, height: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Tổng đài: 1900 6868',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: RecoveryColors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const RecoverySvgIcon('76b1e', width: 13.33, height: 13.33),
                  const SizedBox(width: 4),
                  Text(
                    'Chat với Trợ giảng',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: RecoveryColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecoverySectionTitle extends StatelessWidget {
  const RecoverySectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.titleSize = 24,
    this.subtitleFontSize = 14,
  });

  final String title;
  final String? subtitle;
  final double titleSize;
  final double subtitleFontSize;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle?.trim();

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: titleSize >= 28 ? -0.7 : -0.36,
            color: RecoveryColors.title,
            height: titleSize >= 28 ? 36 / 28 : 32 / 24,
          ),
        ),
        if (subtitleText != null && subtitleText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitleText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: subtitleFontSize,
              height: subtitleFontSize >= 14 ? 22.75 / 14 : 19.5 / 12,
              color: RecoveryColors.body,
            ),
          ),
        ],
      ],
    );
  }
}
