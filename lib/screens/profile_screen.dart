import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/layouts/app_avatar.dart';
import 'package:ofocus/layouts/app_header.dart';
import 'package:ofocus/layouts/app_page_scaffold.dart';
import 'package:ofocus/layouts/app_version_footer.dart';
import 'package:ofocus/services/avatar_picker_service.dart';
import 'package:ofocus/services/avatar_service.dart';
import 'package:ofocus/services/session_manager.dart';
import 'package:ofocus/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userData,
    required this.sessionManager,
    required this.onLogout,
    this.onAvatarUpdated,
  });

  final dynamic userData;
  final SessionManager sessionManager;
  final Future<void> Function() onLogout;
  final ValueChanged<String>? onAvatarUpdated;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  String? _localAvatarPath;
  String? _avatarUrlOverride;
  final _avatarPicker = AvatarPickerService();
  late final AvatarService _avatarService;
  bool _pickingAvatar = false;

  @override
  void initState() {
    super.initState();
    _avatarService = AvatarService(sessionManager: widget.sessionManager);
  }

  String? _readString(List<String> keys) {
    if (widget.userData is! Map) return null;
    final map = widget.userData as Map;
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  String _membershipLabel(String? role) {
    switch (role?.toUpperCase()) {
      case 'TEACHER':
        return 'GIÁO VIÊN OFOCUS PRO';
      case 'STUDENT':
        return 'HỌC VIÊN OFOCUS PRO';
      default:
        return 'THÀNH VIÊN OFOCUS';
    }
  }

  Future<void> _pickAvatar() async {
    if (_pickingAvatar) return;
    setState(() => _pickingAvatar = true);

    final pick = await _avatarPicker.pickFromGallery();

    if (!mounted) return;

    switch (pick.result) {
      case AvatarPickResult.success:
        if (pick.path == null) {
          setState(() => _pickingAvatar = false);
          return;
        }

        setState(() => _localAvatarPath = pick.path);

        final upload = await _avatarService.uploadAndUpdateAvatar(pick.path!);

        if (!mounted) return;
        setState(() => _pickingAvatar = false);

        if (upload.isSuccess && upload.avatarUrl != null) {
          setState(() {
            _avatarUrlOverride = upload.avatarUrl;
            _localAvatarPath = null;
          });
          widget.onAvatarUpdated?.call(upload.avatarUrl!);
          _showSnackBar('Đã cập nhật ảnh đại diện');
          return;
        }

        setState(() => _localAvatarPath = null);
        _showSnackBar(upload.errorMessage ?? 'Không thể cập nhật ảnh đại diện');
      case AvatarPickResult.cancelled:
        setState(() => _pickingAvatar = false);
      case AvatarPickResult.permissionDenied:
        setState(() => _pickingAvatar = false);
        _showSnackBar('Cần quyền truy cập ảnh để cập nhật ảnh đại diện.');
      case AvatarPickResult.permissionPermanentlyDenied:
        setState(() => _pickingAvatar = false);
        await _showPermissionDialog();
      case AvatarPickResult.failed:
        setState(() => _pickingAvatar = false);
        _showSnackBar('Không thể mở thư viện ảnh. Vui lòng thử lại.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showPermissionDialog() async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cho phép truy cập ảnh',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'oFocus cần quyền truy cập thư viện ảnh để bạn chọn ảnh đại diện. '
          'Vui lòng bật quyền trong Cài đặt.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );

    if (openSettings == true) {
      await _avatarPicker.openSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _readString(['full_name', 'fullName', 'name']) ?? 'Người dùng';
    final email = _readString(['email']) ?? '';
    final role = _readString(['role']);
    final avatarUrl = _avatarUrlOverride ??
        _readString([
          'avatar_url',
          'avatarUrl',
          'photoUrl',
          'picture',
        ]);
    final membership = _membershipLabel(role);

    return AppPageScaffold(
      header: AppHeader.profile(),
      bodyPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProfileHeroSection(
            name: name,
            email: email,
            membership: membership,
            avatarUrl: avatarUrl,
            avatarFilePath: _localAvatarPath,
            onUploadTap: _pickAvatar,
            uploading: _pickingAvatar,
          ),
          const SizedBox(height: 24),
          const _StatsGrid(),
          const SizedBox(height: 24),
          _MenuSection(
            title: 'HỆ THỐNG & BẢO MẬT',
            items: [
              _MenuItemData(
                icon: '25e43',
                iconBg: AppColors.surfaceMuted,
                title: 'Thông báo & Lời nhắc vào lớp',
                subtitle: 'Báo trước giờ học 15 phút',
                trailing: _NotificationToggle(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
              ),
              const _MenuItemData(
                icon: '304b1',
                iconBg: AppColors.surfaceMuted,
                title: 'Bảo mật & Đổi mật khẩu',
                subtitle: '2FA đang bảo vệ',
                subtitleColor: AppColors.success,
                showStatusDot: true,
              ),
              const _MenuItemData(
                icon: 'cca16',
                iconBg: AppColors.surfaceMuted,
                title: 'Trung tâm trợ giúp & Hỗ trợ',
                subtitle: 'Hỗ trợ kỹ thuật 24/7 trực tiếp',
                subtitleColor: AppColors.primary,
              ),
              const _MenuItemData(
                icon: '7fb43',
                iconBg: AppColors.surfaceMuted,
                title: 'Điều khoản sử dụng & Quyền riêng tư',
                subtitle: 'Chính sách bảo mật dữ liệu OFocus',
              ),
            ],
          ),
          const SizedBox(height: 32),
          _LogoutSection(onPressed: widget.onLogout),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: const AppVersionFooter(),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroSection extends StatelessWidget {
  const _ProfileHeroSection({
    required this.name,
    required this.email,
    required this.membership,
    this.avatarUrl,
    this.avatarFilePath,
    this.onUploadTap,
    this.uploading = false,
  });

  final String name;
  final String email;
  final String membership;
  final String? avatarUrl;
  final String? avatarFilePath;
  final VoidCallback? onUploadTap;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.success,
                      AppColors.warning,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                ),
              ),
              Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: AppAvatar(
                  avatarUrl: avatarUrl,
                  avatarFilePath: avatarFilePath,
                  size: 96,
                  showBorder: false,
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: GestureDetector(
                  onTap: uploading ? null : onUploadTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: uploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : _ProfileSvgIcon('71e55', width: 13.33, height: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _ProfileSvgIcon('312f9', width: 18.33, height: 17.5),
          ],
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            email,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceBorder,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileSvgIcon('92c2a', width: 11.67, height: 11.67),
              const SizedBox(width: 4),
              Text(
                membership,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Nâng cấp gói',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: 'eb844',
                label: 'Chỉnh sửa hồ sơ',
                expanded: true,
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(icon: '18105'),
            const SizedBox(width: 8),
            _ActionButton(icon: '1f0fb', iconHeight: 16.67, iconWidth: 15),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.label,
    this.expanded = false,
    this.iconWidth = 15,
    this.iconHeight = 15,
  });

  final String icon;
  final String? label;
  final bool expanded;
  final double iconWidth;
  final double iconHeight;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProfileSvgIcon(icon, width: iconWidth, height: iconHeight),
        if (label != null) ...[
          const SizedBox(width: 6),
          Text(
            label!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.14,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );

    return Container(
      height: 40,
      width: expanded ? null : 40,
      padding: expanded
          ? const EdgeInsets.symmetric(horizontal: 12)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: expanded ? Center(child: child) : Center(child: child),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  static const _stats = [
    _StatData(
      label: 'Chuỗi học tập',
      value: '12',
      unit: 'ngày',
      unitColor: AppColors.error,
      subtitle: 'Đang đạt kỷ lục mới!',
      icon: '03f79',
      iconBg: AppColors.errorSurface,
      iconWidth: 10.67,
      iconHeight: 12,
    ),
    _StatData(
      label: 'Thời lượng học',
      value: '186',
      unit: 'giờ',
      unitColor: AppColors.primary,
      subtitle: '+14h trong tuần này',
      icon: 'a5712',
      iconBg: AppColors.surfaceAccent,
      iconWidth: 12,
      iconHeight: 14,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(data: _stats[0])),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(data: _stats[1])),
          ],
        ),
      ],
    );
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.unit,
    required this.unitColor,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconWidth,
    required this.iconHeight,
  });

  final String label;
  final String value;
  final String unit;
  final Color unitColor;
  final String subtitle;
  final String icon;
  final Color iconBg;
  final double iconWidth;
  final double iconHeight;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _ProfileSvgIcon(
                    data.icon,
                    width: data.iconWidth,
                    height: data.iconHeight,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.56,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                data.unit,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.24,
                  color: data.unitColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.showStatusDot = false,
    this.trailing,
  });

  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final bool showStatusDot;
  final Widget? trailing;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
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
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _MenuRow(item: items[i]),
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.surfaceMuted,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItemData item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _ProfileSvgIcon(item.icon, width: 15, height: 15),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (item.showStatusDot)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: item.subtitleColor ?? AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    item.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: item.subtitleColor != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: item.subtitleColor ?? AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          item.trailing ?? _ProfileSvgIcon('6fd09', width: 6.17, height: 10),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.surfaceBorder,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutSection extends StatefulWidget {
  const _LogoutSection({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  State<_LogoutSection> createState() => _LogoutSectionState();
}

class _LogoutSectionState extends State<_LogoutSection> {
  bool _isLoggingOut = false;

  Future<void> _handleTap() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _isLoggingOut ? null : _handleTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoggingOut)
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                else
                  _ProfileSvgIcon('6b9a9', width: 15, height: 15),
                const SizedBox(width: 8),
                Text(
                  _isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất tài khoản',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.14,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSvgIcon extends StatelessWidget {
  const _ProfileSvgIcon(this.name, {this.width, this.height});

  final String name;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/profile/icons/$name.svg',
      width: width,
      height: height,
    );
  }
}
