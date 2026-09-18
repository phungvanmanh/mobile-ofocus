import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/config/livekit_config.dart';
import 'package:ofocus/models/classroom_session.dart';
import 'package:ofocus/services/class_service.dart';
import 'package:ofocus/services/livekit_room_service.dart';
import 'package:ofocus/utils/app_toast.dart';
import 'package:ofocus/widgets/classroom/classroom_icons.dart';
import 'package:ofocus/widgets/classroom/classroom_widgets.dart';
import 'package:ofocus/widgets/classroom/livekit_participant_grid.dart';
import 'package:ofocus/theme/app_colors.dart';

enum _ClassroomOverlay { none, chat, more }

class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({
    super.key,
    this.session = const ClassSession(),
  });

  final ClassSession session;

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  late final LiveKitRoomService _liveKit;
  late final ClassService _classService;
  _ClassroomOverlay _overlay = _ClassroomOverlay.none;
  bool _connecting = true;
  bool _leaving = false;
  String? _connectError;

  @override
  void initState() {
    super.initState();
    _liveKit = LiveKitRoomService(onRoomChanged: _onLiveKitChanged);
    _classService = ClassService();
    _connectRoom();
  }

  void _onLiveKitChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _connectRoom() async {
    final session = widget.session;
    final token = session.liveKitToken;

    if (token == null || token.isEmpty) {
      setState(() {
        _connecting = false;
        _connectError = 'Thiếu token phòng học';
      });
      return;
    }

    if (!LiveKitConfig.isConfigured) {
      setState(() {
        _connecting = false;
        _connectError = 'Chưa cấu hình LIVEKIT_URL';
      });
      return;
    }

    try {
      final warnings = await _liveKit.connect(
        url: LiveKitConfig.url,
        token: token,
        cameraEnabled: session.cameraEnabled,
        microphoneEnabled: session.microphoneEnabled,
      );
      if (warnings.isNotEmpty && mounted) {
        showAppToast(
          '${warnings.join('. ')}. Vào Cài đặt > Ofocus để cấp quyền.',
          status: AppToastStatus.error,
        );
      }
    } catch (error) {
      final message = error.toString();
      _connectError = message.contains('MissingPluginException')
          ? 'Plugin LiveKit chưa sẵn sàng. Dừng app và chạy lại bằng flutter run.'
          : message;
      if (mounted) {
        showAppToast(
          'Không thể kết nối phòng học',
          status: AppToastStatus.error,
        );
      }
    }

    if (mounted) {
      setState(() => _connecting = false);
    }
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;

    final scheduleId = widget.session.classScheduleId;
    if (scheduleId == null || scheduleId <= 0) {
      showAppToast(
        'Thiếu thông tin buổi học',
        status: AppToastStatus.error,
      );
      return;
    }

    setState(() => _leaving = true);

    try {
      final result = await _classService.closeClassSchedule(
        classScheduleId: scheduleId,
      );

      await _liveKit.disconnect();

      if (!mounted) return;

      if (!result.isSuccess) {
        showAppToast(
          result.errorMessage ?? 'Không thể kết thúc phòng học',
          status: AppToastStatus.error,
        );
        return;
      }

      showAppToast(
        result.message ?? 'Đã thoát phòng học thành công',
        status: AppToastStatus.success,
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      showAppToast(
        'Không thể kết thúc phòng học',
        status: AppToastStatus.error,
      );
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  Future<void> _toggleMic() async {
    try {
      await _liveKit.toggleMicrophone();
    } catch (error) {
      if (!mounted) return;
      showAppToast(
        'Không thể bật/tắt microphone',
        status: AppToastStatus.error,
      );
    }
  }

  Future<void> _toggleCamera() async {
    try {
      await _liveKit.toggleCamera();
    } catch (error) {
      if (!mounted) return;
      showAppToast(
        'Không thể bật/tắt camera',
        status: AppToastStatus.error,
      );
    }
  }

  Future<void> _toggleScreenShare() async {
    if (!_liveKit.isConnected) {
      showAppToast(
        'Chưa kết nối phòng học',
        status: AppToastStatus.error,
      );
      return;
    }

    try {
      final wasEnabled = _liveKit.isScreenShareEnabled;

      if (!wasEnabled && lkPlatformIs(PlatformType.iOS)) {
        showAppToast(
          'Chọn Ofocus trong hộp thoại hệ thống, rồi bấm Bắt đầu phát sóng',
        );
      }

      await _liveKit.toggleScreenShare();
      if (!mounted) return;

      if (_liveKit.isScreenShareEnabled) {
        _closeOverlay();
      }
    } catch (error) {
      if (!mounted) return;
      showAppToast(
        'Không thể chia sẻ màn hình',
        status: AppToastStatus.error,
      );
    }
  }

  @override
  void dispose() {
    _liveKit.dispose();
    super.dispose();
  }

  void _openOverlay(_ClassroomOverlay overlay) {
    setState(() => _overlay = overlay);
  }

  void _closeOverlay() {
    setState(() => _overlay = _ClassroomOverlay.none);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final hasOverlay = _overlay != _ClassroomOverlay.none;
    final participantCount = _liveKit.isConnected
        ? _liveKit.participantCount
        : session.participantCount;

    return Scaffold(
      backgroundColor: AppColors.classroomBg,
      body: Stack(
        children: [
          Column(
            children: [
              ClassroomHeader(
                title: session.shortTitle,
                participantCount: participantCount,
                light: false,
              ),
              Expanded(
                child: _connecting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.onDarkSurface,
                        ),
                      )
                    : _connectError != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _connectError!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.onDarkSurface,
                                ),
                              ),
                            ),
                          )
                        : LiveKitParticipantGrid(
                            participants: _liveKit.participants,
                            dimmed: hasOverlay,
                          ),
              ),
              if (!hasOverlay && !_connecting && _connectError == null)
                ClassroomControlBar(
                  unreadChat: session.unreadChat,
                  micEnabled: _liveKit.isMicrophoneEnabled,
                  cameraEnabled: _liveKit.isCameraEnabled,
                  screenShareEnabled: _liveKit.isScreenShareEnabled,
                  endDisabled: _leaving,
                  onToggleMic: _toggleMic,
                  onToggleCamera: _toggleCamera,
                  onToggleScreenShare: _toggleScreenShare,
                  onChat: () => _openOverlay(_ClassroomOverlay.chat),
                  onMore: () => _openOverlay(_ClassroomOverlay.more),
                  onEnd: _leaveRoom,
                ),
            ],
          ),
          if (hasOverlay) ...[
            GestureDetector(
              onTap: _closeOverlay,
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _overlay == _ClassroomOverlay.chat
                  ? _ChatPanel(
                      session: session,
                      onClose: _closeOverlay,
                    )
                  : _MorePanel(
                      onClose: _closeOverlay,
                      screenShareEnabled: _liveKit.isScreenShareEnabled,
                      onToggleScreenShare: _toggleScreenShare,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.session,
    required this.onClose,
  });

  final ClassSession session;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.68;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const ClassroomIcon(
                    ClassroomIcons.chat,
                    size: 14,
                    color: AppColors.primary,
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
                            'Trò chuyện trong lớp',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBorder,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${session.participantCount}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tin nhắn công khai cho cả lớp',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const ClassroomIcon(ClassroomIcons.close, size: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceMuted),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const ClassroomIcon(
                    ClassroomIcons.pin,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIN GHIM TỪ GIẢNG VIÊN',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        'Các bạn mở bài tập thực hành phần Redux Toolkit',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                _IncomingMessage(
                  author: 'Tuấn Kiệt',
                  time: '19:44',
                  text: 'Em đã clone repo rồi thầy ơi, code chạy\nngon lành ạ! 👍',
                ),
                _OutgoingMessage(
                  time: '19:45',
                  text: 'Thầy cho em hỏi phần dispatch\npayload và catch lỗi API với ạ?',
                ),
                _TaMessage(),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _QuickChip('👍 Đã hiểu bài'),
                _QuickChip('🙋 Xin phát biểu'),
                _QuickChip('📄 Xin tài liệu'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 11, 10, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFC7C4D8).withValues(alpha: 0.3),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC7C4D8).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const ClassroomIcon(
                      ClassroomIcons.emoji,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhập tin nhắn vào lớp...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const ClassroomIcon(
                      ClassroomIcons.attach,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const ClassroomIcon(
                        ClassroomIcons.send,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _IncomingMessage extends StatelessWidget {
  const _IncomingMessage({
    required this.author,
    required this.time,
    required this.text,
  });

  final String author;
  final String time;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceBorder,
            child: Text(
              author[0],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textPrimary,
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

class _OutgoingMessage extends StatelessWidget {
  const _OutgoingMessage({required this.time, required this.text});

  final String time;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Bạn',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(2),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              'B',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaMessage extends StatelessWidget {
  const _TaMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'H',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.successOn,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Trợ giảng Hải',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x26006C49),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TA',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '19:46',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: '@Minh Anh',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const TextSpan(text: ': xem cú pháp '),
                        WidgetSpan(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'rejectWithValue',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ),
                        const TextSpan(text: ' trong createAsyncThunk nhé em!'),
                      ],
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

class _MorePanel extends StatelessWidget {
  const _MorePanel({
    required this.onClose,
    this.screenShareEnabled = false,
    this.onToggleScreenShare,
  });

  final VoidCallback onClose;
  final bool screenShareEnabled;
  final VoidCallback? onToggleScreenShare;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.67;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const ClassroomIcon(
                    ClassroomIcons.apps,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tùy chọn lớp học',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Công cụ và tính năng mở rộng',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const ClassroomIcon(ClassroomIcons.close, size: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceMuted),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: const [
                    Expanded(child: _FeatureCard(
                      title: 'Phòng thảo luận',
                      subtitle: 'Phòng 2 • 4 thành viên',
                      live: true,
                      asset: ClassroomIcons.groups,
                    )),
                    SizedBox(width: 10),
                    Expanded(child: _FeatureCard(
                      title: 'Thành viên',
                      subtitle: '28 đang online',
                      asset: ClassroomIcons.people,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                _MoreMenuItem(
                  asset: ClassroomIcons.screenShare,
                  title: screenShareEnabled
                      ? 'Dừng chia sẻ màn hình'
                      : 'Chia sẻ màn hình',
                  subtitle: screenShareEnabled
                      ? 'Đang trình chiếu màn hình của bạn'
                      : 'Trình chiếu slide hoặc demo code',
                  onTap: onToggleScreenShare,
                ),
                const _MoreMenuItem(
                  asset: ClassroomIcons.record,
                  title: 'Ghi hình buổi học',
                  subtitle: 'Lưu lại để xem lại sau',
                ),
                const _MoreMenuItem(
                  asset: ClassroomIcons.whiteboard,
                  title: 'Bảng trắng tương tác',
                  subtitle: 'Vẽ và ghi chú cùng lớp',
                  trailing: true,
                ),
                const SizedBox(height: 12),
                const _MoreMenuItem(
                  asset: ClassroomIcons.poll,
                  title: 'Khảo sát nhanh',
                  subtitle: 'Tạo poll kiểm tra hiểu bài',
                  trailing: true,
                ),
                const _MoreMenuItem(
                  asset: ClassroomIcons.settings,
                  title: 'Cài đặt phòng học',
                  subtitle: 'Chất lượng video, ngôn ngữ phụ đề',
                  trailing: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    this.live = false,
  });

  final String title;
  final String subtitle;
  final String asset;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: ClassroomIcon(asset, size: 18, color: Colors.white),
              ),
              const Spacer(),
              if (live)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
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

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.asset,
    required this.title,
    required this.subtitle,
    this.trailing = false,
    this.onTap,
  });

  final String asset;
  final String title;
  final String subtitle;
  final bool trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: ClassroomIcon(asset, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing)
            const ClassroomIcon(
              ClassroomIcons.chevronRight,
              size: 12,
              color: AppColors.textMuted,
            ),
        ],
      ),
      ),
    );
  }
}
