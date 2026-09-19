import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/services/auth_service.dart';
import 'package:ofocus/services/session_manager.dart';
import 'package:ofocus/theme/app_colors.dart';
import 'package:ofocus/widgets/password_recovery/recovery_shared.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.sessionManager});

  final SessionManager sessionManager;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _authService = AuthService();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _currentFocusNode = FocusNode();
  final _newFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _currentError;
  String? _newError;
  String? _confirmError;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _currentFocusNode.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _newController.text.length >= 8;
  bool get _hasCaseMix =>
      _newController.text.contains(RegExp(r'[a-z]')) &&
      _newController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasDigit => _newController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _newController.text.contains(RegExp(r'[@#$!%&*?^()_\-+=]'));

  int get _strengthScore => [
    _hasMinLength,
    _hasCaseMix,
    _hasDigit,
    _hasSpecial,
  ].where((v) => v).length;

  bool get _passwordsMatch =>
      _newController.text.isNotEmpty &&
      _newController.text == _confirmController.text;

  void _onFieldChanged() {
    setState(() {
      _currentError = null;
      _newError = null;
      _confirmError = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final current = _currentController.text;
    final password = _newController.text;
    final confirm = _confirmController.text;

    String? currentError;
    String? newError;
    String? confirmError;

    if (current.isEmpty) {
      currentError = 'Vui lòng nhập mật khẩu hiện tại';
    }

    if (password.isEmpty) {
      newError = 'Vui lòng nhập mật khẩu mới';
    } else if (_strengthScore < 4) {
      newError = 'Mật khẩu chưa đủ mạnh';
    } else if (password == current) {
      newError = 'Mật khẩu mới phải khác mật khẩu hiện tại';
    }

    if (confirm.isEmpty) {
      confirmError = 'Vui lòng xác nhận mật khẩu mới';
    } else if (password != confirm) {
      confirmError = 'Mật khẩu xác nhận không khớp';
    }

    if (currentError != null || newError != null || confirmError != null) {
      setState(() {
        _currentError = currentError;
        _newError = newError;
        _confirmError = confirmError;
      });
      if (currentError != null) {
        _currentFocusNode.requestFocus();
      } else if (newError != null) {
        _newFocusNode.requestFocus();
      } else {
        _confirmFocusNode.requestFocus();
      }
      return;
    }

    final token = await widget.sessionManager.getAuthToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _currentError = 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.';
      });
      return;
    }

    setState(() {
      _currentError = null;
      _newError = null;
      _confirmError = null;
      _isLoading = true;
    });

    final result = await _authService.changePassword(
      token: token,
      currentPassword: current,
      newPassword: password,
      confirmPassword: confirm,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      setState(() {
        _currentError = result.errorMessage ?? 'Không thể đổi mật khẩu';
      });
      _currentFocusNode.requestFocus();
      return;
    }

    Navigator.of(context)
        .pop(result.data?.message ?? 'Đổi mật khẩu thành công');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ChangePasswordHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PasswordField(
                                label: 'Mật khẩu hiện tại',
                                controller: _currentController,
                                focusNode: _currentFocusNode,
                                errorText: _currentError,
                                obscure: _obscureCurrent,
                                onToggle: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent,
                                ),
                                onChanged: (_) => _onFieldChanged(),
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              _PasswordField(
                                label: 'Mật khẩu mới',
                                controller: _newController,
                                focusNode: _newFocusNode,
                                errorText: _newError,
                                obscure: _obscureNew,
                                onToggle: () =>
                                    setState(() => _obscureNew = !_obscureNew),
                                onChanged: (_) => _onFieldChanged(),
                                textInputAction: TextInputAction.next,
                                required: true,
                              ),
                              const SizedBox(height: 8),
                              _StrengthMeter(score: _strengthScore),
                              const SizedBox(height: 16),
                              _PasswordField(
                                label: 'Xác nhận mật khẩu mới',
                                controller: _confirmController,
                                focusNode: _confirmFocusNode,
                                errorText: _confirmError,
                                obscure: _obscureConfirm,
                                onToggle: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                onChanged: (_) => _onFieldChanged(),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                              ),
                              if (_passwordsMatch && _confirmError == null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Mật khẩu hoàn toàn trùng khớp',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              RecoveryPrimaryButton(
                                label: 'Lưu mật khẩu mới',
                                showArrow: false,
                                onPressed: _isLoading ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChangePasswordHeader extends StatelessWidget {
  const _ChangePasswordHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              'Đổi mật khẩu',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    this.focusNode,
    this.errorText,
    this.required = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorText;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final bool required;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (required) ...[
              const Spacer(),
              Text(
                'Bắt buộc',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          onChanged: onChanged,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: hasError
                ? AppColors.errorSurface.withValues(alpha: 0.5)
                : AppColors.surface,
            contentPadding: const EdgeInsets.fromLTRB(44, 14, 44, 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: SvgPicture.asset(
                'assets/icons/lock.svg',
                width: 12,
                height: 17,
                colorFilter: const ColorFilter.mode(
                  AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: SvgPicture.asset(
                'assets/icons/eye.svg',
                width: 18,
                height: 12,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        if (errorText != null) RecoveryInlineError(errorText!),
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.score});

  final int score;

  String get _label {
    switch (score) {
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

  Color get _color {
    if (score >= 4) return AppColors.success;
    if (score >= 2) return AppColors.primary;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Độ mạnh mật khẩu',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              _label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: score / 4,
            minHeight: 6,
            backgroundColor: AppColors.surfaceBorder,
            color: _color,
          ),
        ),
      ],
    );
  }
}
