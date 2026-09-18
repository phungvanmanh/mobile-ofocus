import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/models/classroom_session.dart';
import 'package:ofocus/router/app_router.dart';
import 'package:ofocus/services/room_service.dart';
import 'package:ofocus/utils/app_toast.dart';
import 'package:ofocus/widgets/classroom/classroom_icons.dart';
import 'package:ofocus/widgets/classroom/classroom_widgets.dart';
import 'package:ofocus/theme/app_colors.dart';

class ClassroomWaitingScreen extends StatefulWidget {
  const ClassroomWaitingScreen({
    super.key,
    this.session = const ClassSession(),
  });

  final ClassSession session;

  @override
  State<ClassroomWaitingScreen> createState() => _ClassroomWaitingScreenState();
}

class _ClassroomWaitingScreenState extends State<ClassroomWaitingScreen> {
  late final RoomService _roomService;
  bool _micOn = true;
  bool _cameraOn = true;
  bool _aiNoiseOn = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _roomService = RoomService();
  }

  Future<void> _joinClass() async {
    if (_joining) return;

    final session = widget.session;
    final roomName = session.roomCode;
    final classId = session.classId;

    if (roomName == null || roomName.isEmpty || classId == null) {
      showAppToast(
        'Thiếu thông tin phòng học',
        status: AppToastStatus.error,
      );
      return;
    }

    setState(() => _joining = true);

    final result = await _roomService.fetchRoomToken(
      roomName: roomName,
      participantName: session.studentName,
      classId: classId,
    );

    if (!mounted) return;

    setState(() => _joining = false);

    if (!result.isSuccess || result.token == null) {
      showAppToast(
        result.errorMessage ?? 'Không thể tham gia phòng học',
        status: AppToastStatus.error,
      );
      return;
    }

    final shouldReload = await Navigator.of(context).push<bool>(
      AppRoutes.toClassroom(
        session: session.copyWith(
          liveKitToken: result.token,
          cameraEnabled: _cameraOn,
          microphoneEnabled: _micOn,
        ),
      ),
    );

    if (shouldReload == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 64,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ClassInfoCard(session: session),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _VideoPreview(studentName: session.studentName),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DeviceToggleCard(
                          title: 'Microphone',
                          device: 'AirPods Pro (Bluetooth)',
                          active: _micOn,
                          activeColor: AppColors.success,
                          asset: ClassroomIcons.micToggle,
                          onToggle: () => setState(() => _micOn = !_micOn),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DeviceToggleCard(
                          title: 'Camera',
                          device: 'FaceTime HD (Camera trước)',
                          active: _cameraOn,
                          activeColor: AppColors.primaryIndigo,
                          asset: ClassroomIcons.cameraToggle,
                          onToggle: () => setState(() => _cameraOn = !_cameraOn),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _AudioSettingsCard(
                    aiNoiseOn: _aiNoiseOn,
                    onAiToggle: () => setState(() => _aiNoiseOn = !_aiNoiseOn),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _joining ? null : _joinClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryIndigo,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0x334F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _joining
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Tham gia lớp học ngay',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClassroomHeader(
              title: 'Phòng Chờ',
              participantCount: session.participantCount,
              light: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassInfoCard extends StatelessWidget {
  const _ClassInfoCard({required this.session});

  final ClassSession session;

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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ĐANG DIỄN RA',
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
              const Spacer(),
              const ClassroomIcon(
                ClassroomIcons.people,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${session.participantCount} học viên đã vào',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.classTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              children: [
                const TextSpan(text: 'Giảng viên: '),
                TextSpan(
                  text: session.instructor,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (session.roomCode != null && session.roomCode!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Mã phòng: ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    session.roomCode!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ClassroomIcon(ClassroomIcons.shield, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kiểm tra camera & mic thật kỹ để có trải nghiệm học tập tốt nhất',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
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

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.studentName});

  final String studentName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 268,
      decoration: BoxDecoration(
        color: AppColors.classroomBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.classroomBg, AppColors.primary],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: const Color(0xBF283044),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'HD 1080p • 60fps',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onDarkSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                const _PreviewCircleIcon(asset: ClassroomIcons.cameraFlip),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const ClassroomIcon(
                        ClassroomIcons.backgroundWand,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Phông nền',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: const Color(0xCC283044),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$studentName (Học viên)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onDarkSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: const Color(0xCC283044),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [19, 12, 20, 6, 8].map((h) {
                          return Container(
                            width: 4,
                            height: h.toDouble(),
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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

class _PreviewCircleIcon extends StatelessWidget {
  const _PreviewCircleIcon({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: 36,
          height: 36,
          color: const Color(0xBF283044),
          alignment: Alignment.center,
          child: ClassroomIcon(asset, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _DeviceToggleCard extends StatelessWidget {
  const _DeviceToggleCard({
    required this.title,
    required this.device,
    required this.active,
    required this.activeColor,
    required this.asset,
    required this.onToggle,
  });

  final String title;
  final String device;
  final bool active;
  final Color activeColor;
  final String asset;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: active ? activeColor : AppColors.surfaceBorder,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: ClassroomIcon(
                    asset,
                    size: 18,
                    color: active ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              Text(
                active ? 'ĐANG BẬT' : 'ĐANG TẮT',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: active ? activeColor : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              device,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioSettingsCard extends StatelessWidget {
  const _AudioSettingsCard({
    required this.aiNoiseOn,
    required this.onAiToggle,
  });

  final bool aiNoiseOn;
  final VoidCallback onAiToggle;

  @override
  Widget build(BuildContext context) {
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
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const ClassroomIcon(ClassroomIcons.speaker, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kiểm tra loa & tai nghe',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Đảm bảo bạn nghe rõ tiếng giảng viên',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const ClassroomIcon(ClassroomIcons.play, size: 15),
                label: Text(
                  'Thử loa',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceBorder,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.surfaceMuted),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.successLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const ClassroomIcon(ClassroomIcons.aiNoise, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Khử ồn AI thông minh',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.successBadge,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.successDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Lọc tiếng quạt, tạp âm, tiếng bàn phím',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: aiNoiseOn,
                onChanged: (_) => onAiToggle(),
                activeTrackColor: AppColors.success,
                activeThumbColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
