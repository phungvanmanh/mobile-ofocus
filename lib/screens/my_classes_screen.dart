import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/layouts/app_header.dart';
import 'package:ofocus/layouts/app_page_scaffold.dart';
import 'package:ofocus/models/active_class_schedule.dart';
import 'package:ofocus/models/classroom_session.dart';
import 'package:ofocus/models/enrolled_class.dart';
import 'package:ofocus/router/app_router.dart';
import 'package:ofocus/services/class_service.dart';
import 'package:ofocus/services/session_manager.dart';
import 'package:ofocus/theme/app_colors.dart';
import 'package:ofocus/utils/app_toast.dart';

class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({
    super.key,
    this.greetingName = 'bạn',
    this.sessionManager,
    this.userData,
    this.refreshToken,
  });

  final String greetingName;
  final SessionManager? sessionManager;
  final dynamic userData;
  final int? refreshToken;

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  int _filterIndex = 0;
  late final ClassService _classService;
  final _searchController = TextEditingController();
  List<EnrolledClass> _classes = [];
  List<ActiveClassSchedule> _activeSchedules = [];
  bool _loadingClasses = false;
  bool _loadingActiveSchedules = false;
  String? _classesError;
  int? _creatingRoomClassId;
  int _lastLoadedRefreshToken = 0;

  int get _refreshToken => widget.refreshToken ?? 0;

  @override
  void initState() {
    super.initState();
    _classService = ClassService(sessionManager: widget.sessionManager);
    _searchController.addListener(() => setState(() {}));
    _maybeLoadForRefreshToken();
  }

  @override
  void didUpdateWidget(MyClassesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeLoadForRefreshToken();
  }

  void _maybeLoadForRefreshToken() {
    final token = _refreshToken;
    if (token <= 0 || token == _lastLoadedRefreshToken) return;
    _lastLoadedRefreshToken = token;
    _loadMyClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _searchQuery => _searchController.text.trim();

  List<EnrolledClass> get _visibleClasses {
    if (_searchQuery.isEmpty) return _classes;
    return _classes.where((item) => item.matchesQuery(_searchQuery)).toList();
  }

  String get _classCountLabel {
    if (_searchQuery.isEmpty) return '${_classes.length} lớp';
    return '${_visibleClasses.length}/${_classes.length} lớp';
  }

  bool get _isStudent {
    if (widget.userData is! Map) return false;
    final role = (widget.userData as Map)['role'];
    return role?.toString().toUpperCase() == 'STUDENT';
  }

  String _studentName() {
    if (widget.userData is Map) {
      final map = widget.userData as Map;
      for (final key in ['full_name', 'fullName', 'name']) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    return widget.greetingName;
  }

  Future<void> _createQuickRoom(EnrolledClass item) async {
    final classId = item.classId;
    if (classId == null) {
      showAppToast('Không xác định được lớp học', status: AppToastStatus.error);
      return;
    }

    if (_creatingRoomClassId != null) return;

    setState(() => _creatingRoomClassId = classId);

    final result = await _classService.createSpecialSchedule(classId: classId);

    if (!mounted) return;

    setState(() => _creatingRoomClassId = null);

    if (!result.isSuccess || result.roomCode == null) {
      showAppToast(
        result.errorMessage ?? 'Không thể tạo phòng học',
        status: AppToastStatus.error,
      );
      return;
    }

    final shouldReload = await Navigator.of(context).push<bool>(
      AppRoutes.toClassroomWaiting(
        session: ClassSession(
          classTitle: item.title,
          shortTitle: item.title,
          instructor: item.instructor.isNotEmpty ? item.instructor : '—',
          studentName: _studentName(),
          roomCode: result.roomCode,
          classId: classId,
          classScheduleId: result.classScheduleId,
        ),
      ),
    );

    if (shouldReload == true && mounted) {
      await _loadMyClasses();
    }
  }

  Future<void> _confirmDeleteClass(EnrolledClass item) async {
    final classId = item.classId;
    if (classId == null) {
      showAppToast(
        'Không xác định được lớp học cần xóa',
        status: AppToastStatus.error,
      );
      return;
    }

    final message = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteClassDialog(
        className: item.title,
        classService: _classService,
        classId: classId,
      ),
    );

    if (!mounted || message == null) return;

    showAppToast(message, status: AppToastStatus.success);
    await _loadMyClasses();
  }

  Future<void> _showAddClassDialog() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AddClassDialog(
        classService: _classService,
        onCreated: () async {
          if (mounted) await _loadMyClasses();
        },
      ),
    );

    if (!mounted || created != true) return;

    showAppToast('Tạo lớp học thành công', status: AppToastStatus.success);
  }

  Future<void> _loadMyClasses() async {
    setState(() {
      _loadingClasses = true;
      _loadingActiveSchedules = true;
      _classesError = null;
    });

    final results = await Future.wait([
      _classService.fetchMyClasses(),
      _classService.fetchActiveSchedules(),
    ]);

    if (!mounted) return;

    final classesResult = results[0] as ClassListResult;
    final activeResult = results[1] as ActiveScheduleListResult;

    setState(() {
      _loadingClasses = false;
      _loadingActiveSchedules = false;
      if (classesResult.isSuccess) {
        _classes = classesResult.classes;
      } else {
        _classes = [];
        _classesError = classesResult.errorMessage;
      }
      if (activeResult.isSuccess) {
        _activeSchedules = activeResult.schedules;
      } else {
        _activeSchedules = [];
      }
    });
  }

  Future<void> _joinLiveClass(ActiveClassSchedule item) async {
    if (item.roomCode.isEmpty || item.classId <= 0) {
      showAppToast(
        'Thiếu thông tin phòng học',
        status: AppToastStatus.error,
      );
      return;
    }

    final shouldReload = await Navigator.of(context).push<bool>(
      AppRoutes.toClassroomWaiting(
        session: ClassSession(
          classTitle: item.title,
          shortTitle: item.category.isNotEmpty ? item.category : item.title,
          instructor: item.instructor.isNotEmpty ? item.instructor : '—',
          studentName: _studentName(),
          roomCode: item.roomCode,
          classId: item.classId,
          classScheduleId: item.classScheduleId,
          participantCount: item.onlineCount ?? 0,
        ),
      ),
    );

    if (shouldReload == true && mounted) {
      await _loadMyClasses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      header: AppHeader.page(subtitle: 'Lớp Học Của Tôi'),
      bodyPadding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Tìm kiếm theo tên lớp...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                textInputAction: TextInputAction.search,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: _searchController.clear,
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showAddClassDialog,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 24,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LiveClassSection(
              schedules: _activeSchedules,
              isLoading: _loadingActiveSchedules,
              onJoin: _joinLiveClass,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lớp học của bạn',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        _classCountLabel,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loadingClasses)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_classesError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          _classesError!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadMyClasses,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                else if (_classes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Chưa có lớp học nào',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else if (_visibleClasses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Không tìm thấy lớp học phù hợp',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ..._visibleClasses.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _EnrolledClassCard(
                        title: item.title,
                        instructor: item.instructor,
                        progressLabel: item.progressLabel,
                        progressValue: item.progressValue,
                        progressColor: item.progressColor,
                        footerNote: item.footerNote,
                        onDelete: () => _confirmDeleteClass(item),
                        onQuickCreateRoom: () => _createQuickRoom(item),
                        isCreatingRoom: _creatingRoomClassId == item.classId,
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

class _LiveClassSection extends StatelessWidget {
  const _LiveClassSection({
    required this.schedules,
    required this.isLoading,
    required this.onJoin,
  });

  final List<ActiveClassSchedule> schedules;
  final bool isLoading;
  final ValueChanged<ActiveClassSchedule> onJoin;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (schedules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4EDEA3).withValues(alpha: 0.75),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LỚP ĐANG DIỄN RA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.45,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/home/icons/92226.svg',
                    width: 10,
                    height: 8,
                    colorFilter: const ColorFilter.mode(
                      AppColors.successOn,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'TRỰC TIẾP',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.successOn,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...schedules.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LiveClassCard(
              schedule: item,
              onJoin: () => onJoin(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveClassCard extends StatelessWidget {
  const _LiveClassCard({
    required this.schedule,
    required this.onJoin,
  });

  final ActiveClassSchedule schedule;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 176,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1F35), AppColors.primary],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.textPrimary.withValues(alpha: 0.9),
                        AppColors.textPrimary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
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
                            const SizedBox(width: 6),
                            Text(
                              'ĐANG PHÁT TRỰC TIẾP',
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
                      if (schedule.onlineLabel.isNotEmpty ||
                          schedule.roomCode.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.classroomBg.withValues(
                              alpha: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            schedule.onlineLabel.isNotEmpty
                                ? schedule.onlineLabel
                                : schedule.roomCode,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.onDarkSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (schedule.category.isNotEmpty ||
                    schedule.sessionLabel.isNotEmpty)
                  Row(
                    children: [
                      if (schedule.category.isNotEmpty)
                        Text(
                          schedule.category,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.primary,
                          ),
                        ),
                      if (schedule.category.isNotEmpty &&
                          schedule.sessionLabel.isNotEmpty)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC7C4D8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (schedule.sessionLabel.isNotEmpty)
                        Text(
                          schedule.sessionLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                if (schedule.category.isNotEmpty ||
                    schedule.sessionLabel.isNotEmpty)
                  const SizedBox(height: 6),
                Text(
                  schedule.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (schedule.instructor.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.surfaceBorder,
                            child: Icon(
                              Icons.person,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          schedule.instructor,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.24,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryIndigo,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Vào lớp ngay',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.asset(
                            'assets/home/icons/3b264.svg',
                            width: 12,
                            height: 12,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
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

class _EnrolledClassCard extends StatelessWidget {
  const _EnrolledClassCard({
    required this.title,
    required this.instructor,
    required this.progressLabel,
    required this.progressValue,
    required this.progressColor,
    required this.footerNote,
    this.onDelete,
    this.onQuickCreateRoom,
    this.isCreatingRoom = false,
  });

  final String title;
  final String instructor;
  final String progressLabel;
  final double progressValue;
  final Color progressColor;
  final String footerNote;
  final VoidCallback? onDelete;
  final VoidCallback? onQuickCreateRoom;
  final bool isCreatingRoom;

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
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  instructor,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ khóa học',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (progressValue > 0) ...{
                Text(
                  progressLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
              } else ...{
                // const Text('Chưa có tiến độ'),
              },
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: const Color(0xFFDAE2FD),
              color: progressColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  footerNote,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isCreatingRoom ? null : onQuickCreateRoom,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isCreatingRoom
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Tạo phòng nhanh',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeleteClassDialog extends StatefulWidget {
  const _DeleteClassDialog({
    required this.className,
    required this.classService,
    required this.classId,
  });

  final String className;
  final ClassService classService;
  final int classId;

  @override
  State<_DeleteClassDialog> createState() => _DeleteClassDialogState();
}

class _DeleteClassDialogState extends State<_DeleteClassDialog> {
  bool _deleting = false;

  Future<void> _onConfirmDelete() async {
    if (_deleting) return;

    setState(() => _deleting = true);

    final result = await widget.classService.deleteClass(widget.classId);

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _deleting = false);
      showAppToast(
        result.errorMessage ?? 'Không thể xóa lớp học',
        status: AppToastStatus.error,
      );
      return;
    }

    Navigator.of(context).pop(result.message ?? 'Xóa lớp thành công');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Xóa lớp học',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Bạn có chắc muốn xóa lớp "${widget.className}"?',
        style: GoogleFonts.inter(fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _deleting ? null : _onConfirmDelete,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Xóa'),
        ),
      ],
    );
  }
}

class _AddClassDialog extends StatefulWidget {
  const _AddClassDialog({required this.classService, required this.onCreated});

  final ClassService classService;
  final Future<void> Function() onCreated;

  @override
  State<_AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<_AddClassDialog> {
  final _nameController = TextEditingController();
  int _maxCapacity = 100;
  bool _submitting = false;

  static const _capacityOptions = [50, 100];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (_submitting) return;

    final className = _nameController.text.trim();
    if (className.isEmpty) {
      showAppToast('Vui lòng nhập tên lớp học', status: AppToastStatus.warning);
      return;
    }

    setState(() => _submitting = true);

    final result = await widget.classService.createClass(
      className: className,
      quantity: _maxCapacity,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _submitting = false);
      showAppToast(
        result.errorMessage ?? 'Không thể tạo lớp học',
        status: AppToastStatus.error,
      );
      return;
    }

    await widget.onCreated();

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thêm mới lớp học',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.45,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tên Lớp học',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            Text(
              'Sĩ số tối đa',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _maxCapacity,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  dropdownColor: Colors.white,
                  items: _capacityOptions
                      .map(
                        (capacity) => DropdownMenuItem<int>(
                          value: capacity,
                          child: Text('$capacity'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _maxCapacity = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Hủy',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Xác nhận',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
