import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/screens/reset_password_screen.dart';
import 'package:ofocus/widgets/password_recovery/recovery_shared.dart';
import 'package:ofocus/theme/app_colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _otpLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (index) {
      final node = FocusNode();
      node.addListener(() => setState(() {}));
      return node;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

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
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = TextSelection.collapsed(
        offset: _controllers[index].text.length,
      );
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _submit() {
    if (_otp.length != _otpLength) {
      setState(() => _otpError = 'Vui lòng nhập đủ 6 chữ số OTP');
      _focusFirstEmptyOtpBox();
      return;
    }

    setState(() => _otpError = null);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(email: widget.email, otp: _otp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RecoveryScaffold(
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
            onChange: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
          _OtpFormCard(
            controllers: _controllers,
            focusNodes: _focusNodes,
            errorText: _otpError,
            onDigitChanged: _onDigitChanged,
            onSubmit: _submit,
          ),
          const SizedBox(height: 16),
          const StudentSupportCard(),
        ],
      ),
    );
  }
}

class _EmailChip extends StatelessWidget {
  const _EmailChip({required this.email, required this.onChange});

  final String email;
  final VoidCallback onChange;

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
                  color: RecoveryColors.success,
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
    required this.onSubmit,
    this.errorText,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onDigitChanged;
  final VoidCallback onSubmit;
  final String? errorText;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const RecoverySvgIcon('0371b', width: 10.67, height: 10.67),
                  const SizedBox(width: 4),
                  Text(
                    'Gửi lại ngay',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.24,
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

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasFocus,
    required this.hasValue,
    required this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasFocus;
  final bool hasValue;
  final ValueChanged<String> onChanged;
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
          TextField(
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
          if (hasFocus && !hasValue)
            Container(width: 2, height: 24, color: RecoveryColors.primary),
        ],
      ),
    );
  }
}
