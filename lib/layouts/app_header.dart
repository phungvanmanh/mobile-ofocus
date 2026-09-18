import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/layouts/app_avatar.dart';
import 'package:ofocus/layouts/frosted_surface.dart';
import 'package:ofocus/theme/app_colors.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.logoSize,
    required this.title,
    this.actions = const [],
  });

  factory AppHeader.explore({
    String? avatarUrl,
    VoidCallback? onAvatarTap,
  }) {
    return AppHeader(
      logoSize: 28,
      title: const _ExploreTitle(),
      actions: [
        AppAvatar(avatarUrl: avatarUrl, onTap: onAvatarTap),
      ],
    );
  }

  factory AppHeader.profile() {
    return const AppHeader(
      logoSize: 32,
      title: _ProfileTitle(),
      actions: [
        _NotificationBell(),
      ],
    );
  }

  factory AppHeader.tab(
    String title, {
    String? avatarUrl,
    VoidCallback? onAvatarTap,
  }) {
    return AppHeader(
      logoSize: 28,
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        AppAvatar(avatarUrl: avatarUrl, onTap: onAvatarTap),
      ],
    );
  }

  factory AppHeader.section({
    required String title,
    required String subtitle,
    String? avatarUrl,
    VoidCallback? onAvatarTap,
  }) {
    return AppHeader(
      logoSize: 28,
      title: _SectionTitle(title: title, subtitle: subtitle),
      actions: [
        AppAvatar(avatarUrl: avatarUrl, onTap: onAvatarTap),
      ],
    );
  }

  factory AppHeader.page({required String subtitle}) {
    return AppHeader(
      logoSize: 28,
      title: _SectionTitle(title: 'OFocus', subtitle: subtitle),
      actions: const [_NotificationBell()],
    );
  }

  final double logoSize;
  final Widget title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return FrostedSurface(
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/home/images/edulive_logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: title,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: -0.45,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ExploreTitle extends StatelessWidget {
  const _ExploreTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Khám phá',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ProfileTitle extends StatelessWidget {
  const _ProfileTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OFocus',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: -0.45,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Cá Nhân',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/profile/icons/449ca.svg',
            width: 16,
            height: 20,
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
