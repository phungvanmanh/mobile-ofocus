import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/screens/otp_verification_screen.dart';
import 'package:ofocus/widgets/password_recovery/recovery_shared.dart';
import 'package:ofocus/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  final _emailCardKey = GlobalKey<_EmailMethodCardState>();
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _clearEmailError() {
    if (_emailError != null) {
      setState(() => _emailError = null);
    }
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập địa chỉ email');
      _emailCardKey.currentState?.focusEmail();
      return;
    }

    setState(() => _emailError = null);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RecoveryScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RecoveryStepHeader(step: 1),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: const RecoverySectionTitle(title: 'Quên mật khẩu?'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _EmailMethodCard(
            key: _emailCardKey,
            emailController: _emailController,
            errorText: _emailError,
            onEmailChanged: _clearEmailError,
          ),
          const SizedBox(height: 16),
          _SecurityNoticeBanner(),
          const SizedBox(height: 16),
          RecoveryPrimaryButton(
            label: 'Gửi mã xác thực OTP',
            onPressed: _submit,
          ),
          const SizedBox(height: 24),
          Center(
            child: RecoveryBackToLoginButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 16),
          const StudentSupportCard(),
        ],
      ),
    );
  }
}

class _EmailMethodCard extends StatefulWidget {
  const _EmailMethodCard({
    super.key,
    required this.emailController,
    this.errorText,
    this.onEmailChanged,
  });

  final TextEditingController emailController;
  final String? errorText;
  final VoidCallback? onEmailChanged;

  @override
  State<_EmailMethodCard> createState() => _EmailMethodCardState();
}

class _EmailMethodCardState extends State<_EmailMethodCard> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFieldChanged);
    widget.emailController.addListener(_onFieldChanged);
  }

  void focusEmail() => _focusNode.requestFocus();

  void _onFieldChanged() {
    widget.onEmailChanged?.call();
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFieldChanged);
    _focusNode.dispose();
    widget.emailController.removeListener(_onFieldChanged);
    super.dispose();
  }

  bool get _showValidIcon {
    if (widget.errorText != null) return false;
    final email = widget.emailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  InputBorder _inputBorder({bool focused = false, bool error = false}) {
    if (error) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      );
    }

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: focused
          ? const BorderSide(color: RecoveryColors.primary, width: 2)
          : BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final hasError = widget.errorText != null;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const RecoverySvgIcon(
                  '153c0',
                  width: 18.33,
                  height: 14.67,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Email học viên',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.14,
                            color: RecoveryColors.title,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Khuyên dùng',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.successOn,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Mã OTP 6 số sẽ được gửi tới hòm thư',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: RecoveryColors.body,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: RecoveryColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const RecoverySvgIcon(
                  '09465',
                  width: 10.87,
                  height: 8.02,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ĐỊA CHỈ EMAIL LIÊN KẾT',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: RecoveryColors.body,
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: widget.emailController,
                focusNode: _focusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                showCursor: true,
                cursorColor: RecoveryColors.primary,
                cursorWidth: 2,
                cursorHeight: 20,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.25,
                  color: RecoveryColors.title,
                ),
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.25,
                    color: RecoveryColors.muted,
                  ),
                  filled: true,
                  fillColor: hasError
                      ? AppColors.errorSurface.withValues(alpha: 0.25)
                      : focused
                          ? Colors.white
                          : RecoveryColors.inputBg,
                  contentPadding: EdgeInsets.fromLTRB(
                    16,
                    15.5,
                    _showValidIcon ? 40 : 16,
                    15.5,
                  ),
                  border: _inputBorder(error: hasError),
                  enabledBorder: _inputBorder(error: hasError),
                  focusedBorder: _inputBorder(
                    focused: true,
                    error: hasError,
                  ),
                  errorBorder: _inputBorder(error: true),
                  focusedErrorBorder: _inputBorder(error: true),
                ),
              ),
              if (_showValidIcon && !focused)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SvgPicture.asset(
                    'assets/icons/check.svg',
                    width: 16.67,
                    height: 16.67,
                    fit: BoxFit.scaleDown,
                  ),
                ),
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Text(
              widget.errorText!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecurityNoticeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RecoveryColors.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const RecoverySvgIcon('c5e8c', width: 15, height: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lưu ý an toàn tài khoản',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.24,
                    color: RecoveryColors.title,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.625,
                      color: RecoveryColors.body,
                    ),
                    children: const [
                      TextSpan(text: 'Mã OTP có hiệu lực trong '),
                      TextSpan(
                        text: '5 phút',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: RecoveryColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: '. Vui lòng kiểm tra kỹ cả hòm thư Spam hoặc Thư rác nếu không nhận được email sau 1 phút.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
