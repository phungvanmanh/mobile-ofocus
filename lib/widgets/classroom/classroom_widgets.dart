import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/models/classroom_session.dart';
import 'package:ofocus/widgets/classroom/classroom_icons.dart';
import 'package:ofocus/theme/app_colors.dart';

class ClassroomHeader extends StatelessWidget {
  const ClassroomHeader({
    super.key,
    required this.title,
    required this.participantCount,
    this.onBack,
    this.light = true,
  });

  final String title;
  final int participantCount;
  final VoidCallback? onBack;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final bg = light
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: bg,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack ?? () => Navigator.of(context).pop(),
                icon: const ClassroomIcon(ClassroomIcons.back, size: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: light ? 18 : 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!light)
                      Row(
                        children: [
                          const ClassroomIcon(
                            ClassroomIcons.people,
                            size: 13,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$participantCount',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (!light) ...[
                const _RoundIconButton(asset: ClassroomIcons.speaker),
                const SizedBox(width: 4),
                const _RoundIconButton(asset: ClassroomIcons.cameraFlip),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ClassroomIcon(asset, size: 16),
    );
  }
}

class ParticipantVideoGrid extends StatelessWidget {
  const ParticipantVideoGrid({
    super.key,
    required this.participants,
    this.dimmed = false,
  });

  final List<ClassroomParticipant> participants;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 174 / 130.5,
        ),
        itemCount: participants.length + 1,
        itemBuilder: (context, index) {
          if (index == participants.length) {
            return _MoreParticipantsTile();
          }
          return _ParticipantTile(participant: participants[index]);
        },
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});

  final ClassroomParticipant participant;

  @override
  Widget build(BuildContext context) {
    final border = participant.borderColor != null
        ? Border.all(color: Color(participant.borderColor!), width: 2)
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: border,
        color: const Color(0x1AEAEDFF),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.classroomTile,
                  Color(
                    participant.role == ParticipantRole.instructor
                        ? 0xFF006C49
                        : 0xFF3525CD,
                  ).withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          if (participant.role == ParticipantRole.instructor)
            Positioned(
              top: 8,
              left: 8,
              child: _Badge(
                label: 'GIẢNG VIÊN',
                color: AppColors.success,
                dotColor: AppColors.successLight,
              ),
            ),
          if (participant.role == ParticipantRole.self)
            Positioned(
              top: 8,
              left: 8,
              child: _Badge(label: 'BẠN', color: AppColors.primary),
            ),
          if (participant.handRaised)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const ClassroomIcon(ClassroomIcons.handRaised, size: 12),
              ),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xBF283044),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      participant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: AppColors.onDarkSurface,
                      ),
                    ),
                  ),
                  if (participant.micOn)
                    const ClassroomIcon(
                      ClassroomIcons.mic,
                      size: 12,
                      color: AppColors.successLight,
                    )
                  else
                    const ClassroomIcon(ClassroomIcons.micMuted, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreParticipantsTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x1AEAEDFF),
      ),
      child: Container(
        color: const Color(0xBF283044),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const ClassroomIcon(
                ClassroomIcons.groups,
                size: 20,
                color: AppColors.onDarkSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '+16 bạn khác',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.onDarkSurface,
              ),
            ),
            Text(
              'Chạm để mở rộng',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFFC7C4D8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.dotColor});

  final String label;
  final Color color;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class ClassroomControlBar extends StatelessWidget {
  const ClassroomControlBar({
    super.key,
    required this.unreadChat,
    this.micEnabled = true,
    this.cameraEnabled = true,
    this.screenShareEnabled = false,
    this.onToggleMic,
    this.onToggleCamera,
    this.onToggleScreenShare,
    this.onChat,
    this.onMore,
    this.onEnd,
    this.endDisabled = false,
  });

  final int unreadChat;
  final bool micEnabled;
  final bool cameraEnabled;
  final bool screenShareEnabled;
  final bool endDisabled;
  final VoidCallback? onToggleMic;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleScreenShare;
  final VoidCallback? onChat;
  final VoidCallback? onMore;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0x1AEAEDFF),
        border: Border(
          top: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ControlItem(
              label: micEnabled ? 'Mic' : 'Mic tắt',
              asset: micEnabled ? ClassroomIcons.mic : ClassroomIcons.micMuted,
              background: micEnabled ? AppColors.primary : AppColors.error,
              onTap: onToggleMic,
            ),
            _ControlItem(
              label: cameraEnabled ? 'Camera' : 'Camera tắt',
              asset: cameraEnabled
                  ? ClassroomIcons.camera
                  : ClassroomIcons.cameraToggle,
              background: cameraEnabled
                  ? const Color(0x33E2E7FF)
                  : AppColors.error,
              onTap: onToggleCamera,
            ),
            _ControlItem(
              label: screenShareEnabled ? 'Dừng chia sẻ' : 'Chia sẻ',
              asset: ClassroomIcons.screenShare,
              background: screenShareEnabled
                  ? AppColors.primaryIndigo
                  : const Color(0x33E2E7FF),
              onTap: onToggleScreenShare,
            ),
            _ControlItem(
              label: 'Trò chuyện',
              asset: ClassroomIcons.chat,
              background: const Color(0x33E2E7FF),
              badge: unreadChat > 0 ? '$unreadChat' : null,
              onTap: onChat,
            ),
            _ControlItem(
              label: 'Thêm',
              asset: ClassroomIcons.more,
              background: const Color(0x33E2E7FF),
              onTap: onMore,
            ),
            _ControlItem(
              label: 'Kết thúc',
              asset: ClassroomIcons.endCall,
              background: AppColors.error,
              labelColor: AppColors.error,
              onTap: endDisabled
                  ? null
                  : onEnd ?? () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlItem extends StatelessWidget {
  const _ControlItem({
    required this.label,
    required this.asset,
    required this.background,
    this.labelColor,
    this.badge,
    this.onTap,
  });

  static const _iconSize = 16.0;
  static const _lightButtonBg = Color(0x33E2E7FF);

  final String label;
  final String asset;
  final Color background;
  final Color? labelColor;
  final String? badge;
  final VoidCallback? onTap;

  Color get _iconColor =>
      background == _lightButtonBg ? AppColors.primary : Colors.white;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: ClassroomIcon(asset, size: _iconSize, color: _iconColor),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.classroomBg,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: labelColor ?? AppColors.onDarkSurface,
            ),
          ),
        ],
      ),
    );
  }
}
