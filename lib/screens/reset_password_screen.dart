import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/screens/login_screen.dart';
import 'package:ofocus/widgets/password_recovery/recovery_shared.dart';
import 'package:ofocus/theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasCaseMix =>
      _passwordController.text.contains(RegExp(r'[a-z]')) &&
      _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasDigit => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _passwordController.text.contains(RegExp(r'[@#$!%&*?^()_\-+=]'));

  int get _strengthScore => [
    _hasMinLength,
    _hasCaseMix,
    _hasDigit,
    _hasSpecial,
  ].where((v) => v).length;

  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmController.text;

  void _onPasswordChanged(String _) {
    setState(() {
      _passwordError = null;
    });
  }

  void _onConfirmChanged(String _) {
    setState(() {
      _confirmError = null;
    });
  }

  void _submit() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    String? passwordError;
    String? confirmError;

    if (password.isEmpty) {
      passwordError = 'Vui lòng nhập mật khẩu mới';
    } else if (_strengthScore < 4) {
      passwordError = 'Mật khẩu chưa đủ mạnh';
    }

    if (confirm.isEmpty) {
      confirmError = 'Vui lòng xác nhận mật khẩu mới';
    } else if (password != confirm) {
      confirmError = 'Mật khẩu xác nhận không khớp';
    }

    if (passwordError != null || confirmError != null) {
      setState(() {
        _passwordError = passwordError;
        _confirmError = confirmError;
      });
      if (passwordError != null) {
        _passwordFocusNode.requestFocus();
      } else {
        _confirmFocusNode.requestFocus();
      }
      return;
    }

    setState(() {
      _passwordError = null;
      _confirmError = null;
    });

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          successMessage: 'Đặt lại mật khẩu thành công. Vui lòng đăng nhập.',
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RecoveryScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RecoveryStepHeader(
            step: 3,
            variant: RecoveryStepperVariant.bar,
          ),
          const SizedBox(height: 24),
          RecoverySectionTitle(
            title: 'Đặt lại mật khẩu mới',
            subtitle: 'Mã xác thực đã được kiểm tra thành công. Vui lòng tạo mật\nkhẩu mới an toàn để bảo vệ tài khoản học tập của bạn.',
            subtitleFontSize: 12,
          ),
          const SizedBox(height: 24),
          _ResetFormCard(
            passwordController: _passwordController,
            confirmController: _confirmController,
            passwordFocusNode: _passwordFocusNode,
            confirmFocusNode: _confirmFocusNode,
            passwordError: _passwordError,
            confirmError: _confirmError,
            obscurePassword: _obscurePassword,
            obscureConfirm: _obscureConfirm,
            onTogglePassword: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onToggleConfirm: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            onPasswordChanged: _onPasswordChanged,
            onConfirmChanged: _onConfirmChanged,
            strengthScore: _strengthScore,
            hasMinLength: _hasMinLength,
            hasCaseMix: _hasCaseMix,
            hasDigit: _hasDigit,
            hasSpecial: _hasSpecial,
            passwordsMatch: _passwordsMatch,
            onSubmit: _submit,
          ),
          const SizedBox(height: 12),
          const StudentSupportCard(),
        ],
      ),
    );
  }
}

class _ResetFormCard extends StatelessWidget {
  const _ResetFormCard({
    required this.passwordController,
    required this.confirmController,
    required this.passwordFocusNode,
    required this.confirmFocusNode,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onPasswordChanged,
    required this.onConfirmChanged,
    required this.strengthScore,
    required this.hasMinLength,
    required this.hasCaseMix,
    required this.hasDigit,
    required this.hasSpecial,
    required this.passwordsMatch,
    required this.onSubmit,
    this.passwordError,
    this.confirmError,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final FocusNode passwordFocusNode;
  final FocusNode confirmFocusNode;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmChanged;
  final int strengthScore;
  final bool hasMinLength;
  final bool hasCaseMix;
  final bool hasDigit;
  final bool hasSpecial;
  final bool passwordsMatch;
  final VoidCallback onSubmit;
  final String? passwordError;
  final String? confirmError;

  String get _strengthLabel {
    switch (strengthScore) {
      case 4:
        return 'Rất mạnh';
      case 3:
        return 'Khá mạnh';
      case 2:
        return 'Trung bình';
      case 1:
        return 'Yếu';
      default:
        return 'Chưa đủ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordFieldSection(
            label: 'Mật khẩu mới',
            required: true,
            controller: passwordController,
            focusNode: passwordFocusNode,
            errorText: passwordError,
            obscure: obscurePassword,
            onToggle: onTogglePassword,
            onChanged: onPasswordChanged,
            lockIcon: '18b40',
          ),
          const SizedBox(height: 8),
          _StrengthMeter(score: strengthScore, label: _strengthLabel),
          const SizedBox(height: 8),
          _CriteriaList(
            hasMinLength: hasMinLength,
            hasCaseMix: hasCaseMix,
            hasDigit: hasDigit,
            hasSpecial: hasSpecial,
          ),
          const Divider(height: 33, color: AppColors.surfaceBorder),
          _PasswordFieldSection(
            label: 'Xác nhận mật khẩu mới',
            controller: confirmController,
            focusNode: confirmFocusNode,
            errorText: confirmError,
            obscure: obscureConfirm,
            onToggle: onToggleConfirm,
            onChanged: onConfirmChanged,
            lockIcon: 'c113b',
          ),
          if (passwordsMatch && confirmError == null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const RecoverySvgIcon('ce344', width: 14.47, height: 14.47),
                const SizedBox(width: 6),
                Text(
                  'Mật khẩu hoàn toàn trùng khớp',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.24,
                    color: RecoveryColors.success,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          RecoveryPrimaryButton(
            label: 'Lưu mật khẩu & Đăng nhập ngay',
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _PasswordFieldSection extends StatelessWidget {
  const _PasswordFieldSection({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    required this.lockIcon,
    this.focusNode,
    this.errorText,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorText;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final String lockIcon;
  final bool required;

  InputBorder _border({bool focused = false, bool error = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: error || focused
          ? BorderSide(
              color: error ? RecoveryColors.error : RecoveryColors.primary,
              width: 2,
            )
          : BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.14,
                color: RecoveryColors.title,
              ),
            ),
            if (required)
              Text(
                'Bắt buộc',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: RecoveryColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscure,
              onChanged: onChanged,
              showCursor: true,
              cursorColor: RecoveryColors.primary,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.25,
                color: RecoveryColors.title,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: hasError
                    ? RecoveryColors.errorFill
                    : RecoveryColors.inputBg,
                contentPadding: const EdgeInsets.fromLTRB(44, 15.5, 44, 15.5),
                border: _border(error: hasError),
                enabledBorder: _border(error: hasError),
                focusedBorder: _border(focused: true, error: hasError),
                errorBorder: _border(error: true),
                focusedErrorBorder: _border(error: true),
              ),
            ),
            Positioned(
              left: 16,
              child: RecoverySvgIcon(lockIcon, width: 13.33, height: 17.5),
            ),
            Positioned(
              right: 12,
              child: IconButton(
                onPressed: onToggle,
                icon: SvgPicture.asset(
                  'assets/icons/eye.svg',
                  width: 18.33,
                  height: 12.5,
                ),
              ),
            ),
          ],
        ),
        if (hasError) RecoveryInlineError(errorText!),
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.score, required this.label});

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final activeColor = score >= 3
        ? RecoveryColors.success
        : RecoveryColors.primary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RecoveryColors.inputBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Độ mạnh mật khẩu:',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: RecoveryColors.body,
                ),
              ),
              Row(
                children: [
                  const RecoverySvgIcon('dd875', width: 9.33, height: 11.67),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: score >= 3
                          ? RecoveryColors.success
                          : RecoveryColors.body,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: index == 0 ? 0 : 3),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index < score
                        ? activeColor
                        : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CriteriaList extends StatelessWidget {
  const _CriteriaList({
    required this.hasMinLength,
    required this.hasCaseMix,
    required this.hasDigit,
    required this.hasSpecial,
  });

  final bool hasMinLength;
  final bool hasCaseMix;
  final bool hasDigit;
  final bool hasSpecial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yêu cầu tiêu chuẩn an toàn:',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: RecoveryColors.body,
          ),
        ),
        const SizedBox(height: 6),
        _CriterionRow(
          met: hasMinLength,
          text: 'Tối thiểu 8 ký tự${hasMinLength ? ' (đã đạt)' : ''}',
        ),
        _CriterionRow(met: hasCaseMix, text: 'Chứa chữ in hoa và chữ thường'),
        _CriterionRow(met: hasDigit, text: 'Bao gồm ít nhất một chữ số (0-9)'),
        _CriterionRow(
          met: hasSpecial,
          text: r'Ký tự đặc biệt (@, #, $, !, %...)',
        ),
      ],
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.met, required this.text});

  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: met
                  ? RecoveryColors.success.withValues(alpha: 0.15)
                  : AppColors.surfaceBorder,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: met
                ? const RecoverySvgIcon('132aa', width: 9.7, height: 7.4)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: RecoveryColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
