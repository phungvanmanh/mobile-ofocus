import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/router/auth_gate.dart';
import 'package:ofocus/screens/my_classes_screen.dart';
import 'package:ofocus/screens/profile_screen.dart';
import 'package:ofocus/screens/schedule_screen.dart';
import 'package:ofocus/services/google_auth_service.dart';
import 'package:ofocus/services/session_manager.dart';
import 'package:ofocus/layouts/app_header.dart';
import 'package:ofocus/layouts/app_page_scaffold.dart';
import 'package:ofocus/layouts/main_bottom_nav.dart';
import 'package:ofocus/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.userData,
    required this.sessionManager,
  });

  final dynamic userData;
  final SessionManager sessionManager;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _profileTabIndex = 3;

  Timer? _expiryTimer;
  int _navIndex = 0;
  Map<String, dynamic>? _userData;
  final Map<int, int> _tabRefreshToken = {0: 0, 1: 0, 2: 0, 3: 0};

  @override
  void initState() {
    super.initState();
    _userData = _copyUserData(widget.userData);
    WidgetsBinding.instance.addObserver(this);
    _scheduleAutoLogout();
  }

  Map<String, dynamic>? _copyUserData(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  void _onAvatarUpdated(String avatarUrl) {
    setState(() {
      _userData ??= {};
      _userData!['avatar_url'] = avatarUrl;
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateSession();
    }
  }

  Future<void> _scheduleAutoLogout() async {
    _expiryTimer?.cancel();

    final session = await widget.sessionManager.loadSession();
    if (session == null || !session.isValid) {
      await _logout(showExpiredMessage: true);
      return;
    }

    widget.sessionManager.logSessionExpiry(session);

    final remaining = session.remaining;
    if (remaining <= Duration.zero) {
      await _logout(showExpiredMessage: true);
      return;
    }

    _expiryTimer = Timer(remaining, () => _logout(showExpiredMessage: true));
  }

  Future<void> _validateSession() async {
    final valid = await widget.sessionManager.isSessionValid();
    if (!valid) {
      await _logout(showExpiredMessage: true);
      return;
    }
    await _scheduleAutoLogout();
  }

  Future<void> _handleLogout() => _logout(showExpiredMessage: false);

  Future<void> _logout({bool showExpiredMessage = false}) async {
    _expiryTimer?.cancel();
    await widget.sessionManager.clearSession();
    await GoogleAuthService.instance.signOut();

    if (!mounted) return;

    if (showExpiredMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập đã hết hạn')),
      );
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  String? _readUserString(List<String> keys) {
    if (_userData == null) return null;
    final data = _userData!;
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value.trim();
    }
    return null;
  }

  String _greetingName() {
    return _readUserString([
      'full_name',
      'fullName',
      'firstName',
      'name',
      'username',
      'email',
    ]) ??
        'bạn';
  }

  String? _avatarUrl() {
    return _readUserString(['avatar_url', 'avatarUrl', 'photoUrl', 'picture']);
  }

  void _goToProfileTab() => _onNavTap(_profileTabIndex);

  Future<void> _refreshUserData() async {
    final session = await widget.sessionManager.loadSession();
    if (!mounted || session?.userData == null) return;
    setState(() => _userData = Map<String, dynamic>.from(session!.userData!));
  }

  void _onNavTap(int index) {
    setState(() {
      _navIndex = index;
      _tabRefreshToken[index] = (_tabRefreshToken[index] ?? 0) + 1;
    });

    if (index == _profileTabIndex) {
      unawaited(_refreshUserData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _ExploreTab(
            greetingName: _greetingName(),
            avatarUrl: _avatarUrl(),
            onAvatarTap: _goToProfileTab,
          ),
          MyClassesScreen(
            greetingName: _greetingName(),
            sessionManager: widget.sessionManager,
            userData: _userData,
            refreshToken: _tabRefreshToken[1] ?? 0,
          ),
          ScheduleScreen(
            sessionManager: widget.sessionManager,
            refreshToken: _tabRefreshToken[2] ?? 0,
          ),
          ProfileScreen(
            userData: _userData,
            sessionManager: widget.sessionManager,
            onLogout: _handleLogout,
            onAvatarUpdated: _onAvatarUpdated,
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab({
    required this.greetingName,
    this.avatarUrl,
    this.onAvatarTap,
  });

  final String greetingName;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      header: AppHeader.explore(
        avatarUrl: avatarUrl,
        onAvatarTap: onAvatarTap,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GreetingSection(name: greetingName),
          const _SearchSection(),
          const _CategorySection(),
          const _WorkshopBanner(),
          const _ContinueLearningSection(),
        ],
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Chào $name',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Hôm nay bạn muốn học gì mới?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/home/icons/64464.svg',
                  width: 12,
                  height: 13.5,
                ),
                const SizedBox(width: 6),
                Text(
                  '5 ngày liền',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.24,
                    color: AppColors.warningOn,
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

class _SearchSection extends StatelessWidget {
  const _SearchSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/home/icons/69f7c.svg',
                    width: 15,
                    height: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tìm khóa học, giảng viên, môn học...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/home/icons/08835.svg',
                width: 15,
                height: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection();

  static const _categories = [
    _CategoryItem('Tất cả', 'dfa70.svg', active: true),
    _CategoryItem('Lập trình & CNTT', '76a8d.svg'),
    _CategoryItem('Ngoại ngữ', '0f180.svg'),
    _CategoryItem('Thiết kế UI/UX', 'fb17a.svg'),
    _CategoryItem('Marketing', '02109.svg'),
    _CategoryItem('Kỹ năng mềm', 'b39ba.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _categories.length,
        separatorBuilder: (context, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = _categories[index];
          return _CategoryChip(item: item);
        },
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.label, this.icon, {this.active = false});

  final String label;
  final String icon;
  final bool active;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.item});

  final _CategoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: item.active ? AppColors.primary : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        boxShadow: item.active
            ? const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/home/icons/${item.icon}',
            width: 12,
            height: 12,
            colorFilter: item.active
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : const ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.24,
              color: item.active ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopBanner extends StatelessWidget {
  const _WorkshopBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryIndigo, AppColors.primary, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 15,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -32,
                bottom: -32,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: SvgPicture.asset(
                  'assets/home/icons/a2cab.svg',
                  width: 72,
                  height: 72,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.successLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE TỐI NAY • 20:00',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Miễn phí 100 vé',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AI & Tương lai Kỹ sư Lập trình\n2025',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thực chiến xây dựng Agentic AI & Ứng dụng LLM cùng\nchuyên gia từ Silicon Valley.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.33,
                        color: AppColors.lavender,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/home/images/instructor.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TS. Hoàng Long',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'AI Research Lead',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: AppColors.lavender,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowMedium,
                                blurRadius: 6,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tham gia ngay',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SvgPicture.asset(
                                'assets/home/icons/3b264.svg',
                                width: 12,
                                height: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _ContinueLearningSection extends StatelessWidget {
  const _ContinueLearningSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/home/icons/72a46.svg',
                width: 16.67,
                height: 16.67,
              ),
              const SizedBox(width: 6),
              Text(
                'Tiếp tục bài học',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Lịch sử học',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.24,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/home/images/course_thumb.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0x33131B2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/home/icons/92226.svg',
                                  width: 9.17,
                                  height: 11.67,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceBorder,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Bài 9/16',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SvgPicture.asset(
                                'assets/home/icons/4c674.svg',
                                width: 11.67,
                                height: 11.67,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '24 phút còn lại',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lập trình React Native & UI Nâng cao',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.33,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Chủ đề: State Management với Redux Toolkit',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ tổng thể',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '56% hoàn thành',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.56,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceMuted,
                    color: AppColors.primaryIndigo,
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
