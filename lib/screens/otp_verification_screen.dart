import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/screens/login_screen.dart';
import 'package:ofocus/screens/reset_password_screen.dart';
import 'package:ofocus/services/auth_service.dart';
import 'package:ofocus/utils/app_toast.dart';
import 'package:ofocus/widgets/password_recovery/recovery_shared.dart';
import 'package:ofocus/theme/app_colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.expiresInMinutes = 5,
  });

  final String email;
  final int expiresInMinutes;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _otpLength = 6;

  final _authService = AuthService();
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _timer;
  late int _secondsRemaining;
  String? _otpError;
  bool _isLoading = false;
  bool _isResending = false;
  bool _expiredHandled = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (index) {
      final node = FocusNode();
      node.addListener(() => setState(() {}));
      return node;
    });
    _secondsRemaining = widget.expiresInMinutes * 60;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  String get _formattedCountdown {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _onOtpExpired();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _resetTimer(int expiresInMinutes) {
    setState(() => _secondsRemaining = expiresInMinutes * 60);
    _startTimer();
  }

  void _onOtpExpired() {
    if (_expiredHandled || !mounted) return;
    _expiredHandled = true;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          initialToastMessage:
              'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới để đặt lại mật khẩu.',
          initialToastStatus: AppToastStatus.warning,
        ),
      ),
      (_) => false,
    );
  }

  void _clearOtpError() {
    if (_otpError != null) {
      setState(() => _otpError = null);
    }
  }

  void _focusFirstEmptyOtpBox() {
    for (var i = 0; i < _otpLength; i++) {
      if (_controllers[i].text.isEmpty) {
        _focusNodes[i].requestFocus();
        return;
      }
    }
    _focusNodes.first.requestFocus();
  }

  void _onDigitChanged(int index, String value) {
    _clearOtpError();

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 1) {
      _fillOtpFrom(index, digitsOnly);
      setState(() {});
      return;
    }

    if (digitsOnly.isNotEmpty) {
      _controllers[index].text = digitsOnly;
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
      if (index < _otpLength - 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _focusNodes[index + 1].requestFocus();
        });
      }
    }

    setState(() {});
  }

  void _fillOtpFrom(int startIndex, String digits) {
    for (var i = 0; i < digits.length && startIndex + i < _otpLength; i++) {
      _controllers[startIndex + i].text = digits[i];
    }

    final focusIndex = (startIndex + digits.length).clamp(0, _otpLength - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNodes[focusIndex].requestFocus();
    });
  }

  void _onBackspaceOnEmpty(int index) {
    if (index <= 0) return;

    _clearOtpError();
    final previous = index - 1;
    _controllers[previous].clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNodes[previous].requestFocus();
    });
    setState(() {});
  }

  Future<void> _submit() async {
    if (_secondsRemaining <= 0) {
      _onOtpExpired();
      return;
    }

    FocusScope.of(context).unfocus();

    if (_otp.length != _otpLength) {
      setState(() => _otpError = 'Vui lòng nhập đủ 6 chữ số OTP');
      _focusFirstEmptyOtpBox();
      return;
    }

    setState(() {
      _otpError = null;
      _isLoading = true;
    });

    final result = await _authService.verifyOtp(email: widget.email, otp: _otp);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      setState(() => _otpError = result.errorMessage ?? 'Mã OTP không hợp lệ');
      _focusFirstEmptyOtpBox();
      return;
    }

    final data = result.data!;
    if (data.resetToken.isEmpty) {
      setState(() => _otpError = 'Không nhận được mã đặt lại mật khẩu');
      return;
    }

    _timer?.cancel();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(resetToken: data.resetToken),
      ),
    );
  }

  Future<void> _resendOtp() async {
    if (_isResending || _isLoading || _secondsRemaining <= 0) return;

    setState(() => _isResending = true);

    final result = await _authService.forgotPassword(email: widget.email);

    if (!mounted) return;

    setState(() => _isResending = false);

    if (!result.isSuccess) {
      showAppToast(
        result.errorMessage ?? 'Không thể gửi lại OTP',
        status: AppToastStatus.error,
      );
      return;
    }

    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    _resetTimer(result.data!.expiresInMinutes);
    _clearOtpError();
    showAppToast(result.data!.message, status: AppToastStatus.success);
  }

  @override
  Widget build(BuildContext context) {
    final expired = _secondsRemaining <= 0;

    return Stack(
      children: [
        RecoveryScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RecoveryStepHeader(
                step: 2,
                variant: RecoveryStepperVariant.bar,
              ),
              const SizedBox(height: 16),
              RecoverySectionTitle(
                title: 'Xác thực mã OTP',
                titleSize: 28,
                subtitle: 'Mã số gồm 6 chữ số vừa được gửi an toàn đến\nhòm thư học viên:',
              ),
              const SizedBox(height: 8),
              _EmailChip(
                email: widget.email,
                onChange: _isLoading ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 8),
              _OtpCountdownBanner(
                countdown: _formattedCountdown,
                expired: expired,
              ),
              const SizedBox(height: 8),
              _OtpFormCard(
                controllers: _controllers,
                focusNodes: _focusNodes,
                errorText: _otpError,
                onDigitChanged: _onDigitChanged,
                onBackspaceOnEmpty: _onBackspaceOnEmpty,
                onSubmit: expired ? null : _submit,
                onResend: _resendOtp,
                isResending: _isResending,
                canResend: !expired && !_isLoading,
              ),
              const SizedBox(height: 16),
              const StudentSupportCard(),
            ],
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            ),
          ),
      ],
    );
  }
}

class _OtpCountdownBanner extends StatelessWidget {
  const _OtpCountdownBanner({required this.countdown, required this.expired});

  final String countdown;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: expired ? RecoveryColors.errorFill : RecoveryColors.inputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RecoverySvgIcon(expired ? 'c5e8c' : '0371b', width: 14, height: 14),
          const SizedBox(width: 8),
          Text(
            expired ? 'Mã OTP đã hết hạn' : 'Mã OTP hết hạn sau $countdown',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: expired ? RecoveryColors.error : RecoveryColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailChip extends StatelessWidget {
  const _EmailChip({required this.email, this.onChange});

  final String email;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: RecoveryColors.inputBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RecoverySvgIcon('bbc22', width: 15, height: 15),
            const SizedBox(width: 4),
            Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.24,
                color: RecoveryColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onChange,
              child: Text(
                'Thay đổi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.24,
                  color: onChange == null
                      ? RecoveryColors.muted
                      : RecoveryColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpFormCard extends StatelessWidget {
  const _OtpFormCard({
    required this.controllers,
    required this.focusNodes,
    required this.onDigitChanged,
    required this.onBackspaceOnEmpty,
    this.onSubmit,
    this.onResend,
    this.errorText,
    this.isResending = false,
    this.canResend = true,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onDigitChanged;
  final void Function(int index) onBackspaceOnEmpty;
  final VoidCallback? onSubmit;
  final VoidCallback? onResend;
  final String? errorText;
  final bool isResending;
  final bool canResend;

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
          Text(
            'Mã 6 chữ số',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.24,
              color: RecoveryColors.body,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(6, (index) {
              final hasFocus = focusNodes[index].hasFocus;
              final hasValue = controllers[index].text.isNotEmpty;
              final hasError = errorText != null;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == 5 ? 0 : 4,
                  ),
                  child: _OtpBox(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    hasFocus: hasFocus,
                    hasValue: hasValue,
                    hasError: hasError,
                    onChanged: (value) => onDigitChanged(index, value),
                    onBackspaceOnEmpty: () => onBackspaceOnEmpty(index),
                  ),
                ),
              );
            }),
          ),
          if (errorText != null) RecoveryInlineError(errorText!),
          const SizedBox(height: 16),
          RecoveryPrimaryButton(
            label: 'Xác nhận & Tiếp tục',
            onPressed: onSubmit,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                'Chưa nhận được mã qua hòm thư?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: RecoveryColors.body,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: canResend && !isResending ? onResend : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const RecoverySvgIcon('0371b', width: 10.67, height: 10.67),
                    const SizedBox(width: 4),
                    Text(
                      isResending ? 'Đang gửi lại...' : 'Gửi lại ngay',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.24,
                        color: canResend && !isResending
                            ? RecoveryColors.primary
                            : RecoveryColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasFocus,
    required this.hasValue,
    required this.onChanged,
    this.onBackspaceOnEmpty,
    this.hasError = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasFocus;
  final bool hasValue;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBackspaceOnEmpty;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: hasError
                  ? RecoveryColors.errorFill
                  : hasFocus
                  ? Colors.white
                  : RecoveryColors.inputBg,
              borderRadius: BorderRadius.circular(8),
              border: hasError
                  ? Border.all(color: RecoveryColors.error, width: 2)
                  : hasFocus
                  ? Border.all(color: RecoveryColors.primary, width: 2)
                  : null,
              boxShadow: hasValue && !hasFocus
                  ? const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
          ),
          Focus(
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey != LogicalKeyboardKey.backspace) {
                return KeyEventResult.ignored;
              }
              if (controller.text.isEmpty && onBackspaceOnEmpty != null) {
                onBackspaceOnEmpty!();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.56,
                color: hasValue
                    ? RecoveryColors.primary
                    : const Color(0xFFC7C4D8),
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
