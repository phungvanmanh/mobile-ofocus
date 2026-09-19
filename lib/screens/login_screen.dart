import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ofocus/utils/no_stretch_scroll_behavior.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/screens/forgot_password_screen.dart';
import 'package:ofocus/screens/home_screen.dart';
import 'package:ofocus/services/auth_service.dart';
import 'package:ofocus/services/google_auth_service.dart';
import 'package:ofocus/services/session_manager.dart';
import 'package:ofocus/layouts/terms_footer.dart';
import 'package:ofocus/utils/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.successMessage,
    this.initialToastMessage,
    this.initialToastStatus = AppToastStatus.success,
  });

  final String? successMessage;
  final String? initialToastMessage;
  final AppToastStatus initialToastStatus;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _sessionManager = SessionManager();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final successMessage = widget.successMessage;
    final initialToast = widget.initialToastMessage;
    if (successMessage != null || initialToast != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (successMessage != null) {
          _showMessage(successMessage, status: AppToastStatus.success);
        } else if (initialToast != null) {
          _showMessage(initialToast, status: widget.initialToastStatus);
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Vui lòng nhập email và mật khẩu',
        status: AppToastStatus.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(email: email, password: password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      await _completeLogin(result.data);
      return;
    }

    _showMessage(result.errorMessage ?? 'Đăng nhập thất bại');
  }

  Future<void> _handleGoogleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final googleResult = await GoogleAuthService.instance.signIn();
    if (!mounted) return;

    if (googleResult.isCancelled) {
      setState(() => _isLoading = false);
      return;
    }

    if (!googleResult.isSuccess) {
      setState(() => _isLoading = false);
      _showMessage(googleResult.errorMessage ?? 'Đăng nhập Google thất bại');
      return;
    }

    final result = await _authService.googleLogin(
      credential: googleResult.credential!,
    );
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      await _completeLogin(result.data);
      return;
    }

    _showMessage(result.errorMessage ?? 'Đăng nhập thất bại');
  }

  Future<void> _completeLogin(dynamic data) async {
    final session = await _sessionManager.saveSessionFromLoginData(data);
    if (!mounted) return;

    if (session == null) {
      _showMessage(
        'Đăng nhập không thành công',
        status: AppToastStatus.warning,
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          userData: session.userData ?? data,
          sessionManager: _sessionManager,
        ),
      ),
    );
  }

  void _showMessage(
    String message, {
    AppToastStatus status = AppToastStatus.error,
  }) {
    showAppToast(message, status: status);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: const NoStretchScrollBehavior(),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: keyboardVisible
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: keyboardVisible
                          ? const SizedBox.shrink()
                          : const _HeroCard(),
                    ),
                    _SignInCard(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      onLogin: _handleLogin,
                      onGoogleLogin: _handleGoogleLogin,
                      enabled: !_isLoading,
                    ),
                    if (!keyboardVisible) ...[
                      const SizedBox(height: 16),
                      const TermsFooter(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1E1B4B),
                blurRadius: 15,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x0D1E1B4B),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -64,
                right: -64,
                child: _GlowOrb(
                  size: 176,
                  color: const Color(0x4022D3EE),
                  blur: 32,
                ),
              ),
              Positioned(
                bottom: -40,
                left: -40,
                child: _GlowOrb(
                  size: 160,
                  color: const Color(0x4D6366F1),
                  blur: 20,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(21),
                child: Column(
                  children: [
                    // const _LiveBadge(),
                    const SizedBox(height: 10),
                    const _AppLogo(),
                    const SizedBox(height: 12),
                    Text(
                      'NỀN TẢNG HỌC TRỰC TUYẾN 4.0',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: const Color(0xFF67E8F9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kết nối giảng viên đầu ngành, tương tác realtime &\nkho bài giảng bản quyền chất lượng cao.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.63,
                        color: const Color(0xCCE0E7FF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0x1AFFFFFF), height: 1),
                    const SizedBox(height: 13),
                    const _SocialProofRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color, required this.blur});

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur / 4, sigmaY: blur / 4),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF43F5E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '1,420+ lớp học đang phát trực tiếp',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF22D3EE), Color(0xFF818CF8), Color(0xFFC084FC)],
            ),
          ),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF22D3EE),
                    Color(0xFF818CF8),
                    Color(0xFFC084FC),
                  ],
                ),
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialProofRow extends StatelessWidget {
  const _SocialProofRow();

  @override
  Widget build(BuildContext context) {
    const avatars = [
      'assets/images/student_1.png',
      'assets/images/student_2.png',
      'assets/images/student_3.png',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 20,
          child: Stack(
            children: [
              for (var i = 0; i < avatars.length; i++)
                Positioned(
                  left: i * 14.0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(avatars[i], fit: BoxFit.cover),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFC7D2FE),
            ),
            children: [
              const TextSpan(text: 'Hơn '),
              TextSpan(
                text: '50.000+',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const TextSpan(text: ' học viên tin dùng'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignInCard extends StatefulWidget {
  const _SignInCard({
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.enabled,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final bool enabled;

  @override
  State<_SignInCard> createState() => _SignInCardState();
}

class _SignInCardState extends State<_SignInCard> {
  bool _rememberSession = true;
  bool _obscurePassword = true;

  void _openForgotPassword() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: widget.emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
          _GoogleButton(
            onPressed: widget.enabled ? widget.onGoogleLogin : null,
          ),
          const SizedBox(height: 16),
          const _OrDivider(),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Email',
            controller: widget.emailController,
            iconPath: 'assets/icons/email.svg',
            iconWidth: 16,
            iconHeight: 16,
            hint: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            enabled: widget.enabled,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: 'Mật khẩu',
            controller: widget.passwordController,
            iconPath: 'assets/icons/lock.svg',
            iconWidth: 12,
            iconHeight: 17,
            hint: '••••••••',
            obscureText: _obscurePassword,
            enabled: widget.enabled,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => widget.onLogin(),
            suffix: IconButton(
              onPressed: widget.enabled
                  ? () => setState(() => _obscurePassword = !_obscurePassword)
                  : null,
              icon: SvgPicture.asset(
                'assets/icons/eye.svg',
                width: 18,
                height: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Spacer(),
              TextButton(
                onPressed: widget.enabled ? _openForgotPassword : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Quên mật khẩu?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PrimaryButton(onPressed: widget.enabled ? widget.onLogin : null),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: const Color(0x0A0F172A),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/google.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tiếp tục với Google',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'hoặc sử dụng tài khoản',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.iconPath,
    required this.iconWidth,
    required this.iconHeight,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String iconPath;
  final double iconWidth;
  final double iconHeight;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 15.5,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                left: iconPath.contains('lock') ? 18 : 16,
                right: 12,
              ),
              child: SvgPicture.asset(
                iconPath,
                width: iconWidth,
                height: iconHeight,
                fit: BoxFit.scaleDown,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5)),
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF0891B2)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D4F46E5),
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x4D4F46E5),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Đăng nhập',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
