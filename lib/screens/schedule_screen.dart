import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ofocus/layouts/app_header.dart';
import 'package:ofocus/layouts/app_page_scaffold.dart';
import 'package:ofocus/models/daily_class_schedule.dart';
import 'package:ofocus/services/class_service.dart';
import 'package:ofocus/services/session_manager.dart';
import 'package:ofocus/theme/app_colors.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    required this.sessionManager,
    this.refreshToken,
  });

  final SessionManager sessionManager;
  final int? refreshToken;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _weekStart = _mondayOfWeek(DateTime.now());
  int? _manualDayIndex;
  late final ClassService _classService;

  List<DailyClassSchedule> _schedules = const [];
  String? _loadedDateKey;
  String? _loadingDateKey;
  String? _scheduleError;
  int _lastLoadedRefreshToken = 0;

  final Map<String, List<DailyClassSchedule>> _scheduleCache = {};

  static const _weekDayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _weekendIndices = {5, 6};

  static DateTime _mondayOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static int? _todayIndexInWeek(DateTime weekStart) {
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (day.year == now.year &&
          day.month == now.month &&
          day.day == now.day) {
        return i;
      }
    }
    return null;
  }

  int get _refreshToken => widget.refreshToken ?? 0;

  int get _activeDayIndex =>
      _manualDayIndex ?? _todayIndexInWeek(_weekStart) ?? 0;

  DateTime get _selectedDate {
    final day = _weekStart.add(Duration(days: _activeDayIndex));
    return DateTime(day.year, day.month, day.day);
  }

  String get _selectedDateKey => ClassService.formatApiDate(_selectedDate);

  bool get _isSelectedToday => _isSameDay(_selectedDate, DateTime.now());

  String get _sessionCountLabel {
    if (_loadingDateKey == _selectedDateKey) {
      return 'Đang tải...';
    }
    final count = _schedules.length;
    if (count == 0) {
      return _isSelectedToday ? 'Không có buổi hôm nay' : 'Không có buổi';
    }
    return _isSelectedToday ? '$count buổi hôm nay' : '$count buổi';
  }

  @override
  void initState() {
    super.initState();
    _classService = ClassService(sessionManager: widget.sessionManager);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLoadForRefreshToken();
      _loadSchedulesForSelectedDate();
    });
  }

  @override
  void didUpdateWidget(ScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeLoadForRefreshToken();
  }

  void _maybeLoadForRefreshToken() {
    final token = _refreshToken;
    if (token <= 0 || token == _lastLoadedRefreshToken) return;
    _lastLoadedRefreshToken = token;
    _scheduleCache.remove(_selectedDateKey);
    _loadSchedulesForSelectedDate(force: true);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadSchedulesForSelectedDate({bool force = false}) async {
    final dateKey = _selectedDateKey;
    if (_loadingDateKey == dateKey) return;

    if (!force && _loadedDateKey == dateKey) return;

    final cached = _scheduleCache[dateKey];
    if (!force && cached != null) {
      setState(() {
        _loadedDateKey = dateKey;
        _schedules = cached;
        _scheduleError = null;
      });
      return;
    }

    setState(() {
      _loadingDateKey = dateKey;
      _scheduleError = null;
    });

    final result = await _classService.fetchMySchedulesByDate(_selectedDate);
    if (!mounted || _selectedDateKey != dateKey) return;

    setState(() {
      _loadingDateKey = null;
      if (result.isSuccess) {
        _loadedDateKey = dateKey;
        _schedules = result.schedules;
        _scheduleCache[dateKey] = result.schedules;
        _scheduleError = null;
      } else {
        _scheduleError = result.errorMessage ?? 'Không thể tải lịch học';
        _schedules = const [];
      }
    });
  }

  void _selectDay(int index) {
    final nextDay = _weekStart.add(Duration(days: index));
    final nextDateKey = ClassService.formatApiDate(
      DateTime(nextDay.year, nextDay.month, nextDay.day),
    );
    if (_loadedDateKey == nextDateKey && _loadingDateKey != nextDateKey) {
      if (_manualDayIndex != index) {
        setState(() => _manualDayIndex = index);
      }
      return;
    }
    setState(() => _manualDayIndex = index);
    _loadSchedulesForSelectedDate();
  }

  static int _isoWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final jan4 = DateTime(thursday.year, 1, 4);
    final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
    return ((thursday.difference(week1Monday).inDays) / 7).floor() + 1;
  }

  static String _formatDayMonth(DateTime date) => '${date.day}/${date.month}';

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  List<String> get _weekDates => List.generate(
    7,
    (index) => '${_weekStart.add(Duration(days: index)).day}',
  );

  String get _currentMonthYear =>
      'Tháng ${_weekStart.month}, ${_weekStart.year}';

  String get _weekRangeLabel {
    final weekNumber = _isoWeekNumber(_weekStart);
    return 'Tuần $weekNumber: ${_formatDayMonth(_weekStart)} - '
        '${_formatDayMonth(_weekEnd)}';
  }

  void _shiftWeek(int deltaWeeks) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks));
      _manualDayIndex = null;
    });
    _loadSchedulesForSelectedDate();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      header: AppHeader.page(subtitle: 'Lịch Học'),
      bodyPadding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch học của tôi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _currentMonthYear,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _IconCircleButton(
                      backgroundColor: AppColors.surfaceBorder,
                      child: SvgPicture.asset(
                        'assets/home/icons/76a8d.svg',
                        width: 12,
                        height: 12,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // _ModeSwitcher(
                //   selectedIndex: _modeIndex,
                //   onChanged: (index) => setState(() => _modeIndex = index),
                // ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/home/icons/e327b.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _weekRangeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _shiftWeek(-1),
                      child: _IconCircleButton(
                        size: 32,
                        backgroundColor: AppColors.surface,
                        child: Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _shiftWeek(1),
                      child: _IconCircleButton(
                        size: 32,
                        backgroundColor: AppColors.surface,
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _WeekStrip(
                  weekDays: _weekDayLabels,
                  dates: _weekDates,
                  weekendIndices: _weekendIndices,
                  selectedIndex: _activeDayIndex,
                  onSelected: _selectDay,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/home/icons/e327b.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lịch học trực tuyến',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _sessionCountLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.24,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ScheduleTimeline(
                  loading: _loadingDateKey == _selectedDateKey,
                  error: _scheduleError,
                  schedules: _schedules,
                  onRetry: () =>
                      _loadSchedulesForSelectedDate(force: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// class _ModeSwitcher extends StatelessWidget {
//   const _ModeSwitcher({required this.selectedIndex, required this.onChanged});

//   final int selectedIndex;
//   final ValueChanged<int> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           _ModeTab(
//             label: 'Theo tuần',
//             iconAsset: 'assets/home/icons/7d99d.svg',
//             active: selectedIndex == 0,
//             onTap: () => onChanged(0),
//           ),
//           _ModeTab(
//             label: 'Theo ngày',
//             iconAsset: 'assets/home/icons/e327b.svg',
//             active: selectedIndex == 1,
//             onTap: () => onChanged(1),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.iconAsset,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 12,
                height: 12,
                colorFilter: ColorFilter.mode(
                  active ? AppColors.primary : AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.24,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.weekDays,
    required this.dates,
    required this.weekendIndices,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> weekDays;
  final List<String> dates;
  final Set<int> weekendIndices;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      child: Row(
        children: List.generate(weekDays.length, (index) {
          final active = index == selectedIndex;
          final weekend = weekendIndices.contains(index);
          final dayColor = active
              ? AppColors.surfaceAccent
              : (weekend ? AppColors.error : AppColors.textSecondary);
          final dateColor = active
              ? Colors.white
              : (weekend ? AppColors.error : AppColors.textPrimary);

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekDays[index],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: 0.5,
                        color: dayColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dates[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                        height: 1.1,
                        color: dateColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: active
                          ? const BoxDecoration(
                              color: AppColors.successLight,
                              shape: BoxShape.circle,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ScheduleTimeline extends StatelessWidget {
  const _ScheduleTimeline({
    required this.loading,
    required this.schedules,
    this.error,
    this.onRetry,
  });

  final bool loading;
  final String? error;
  final List<DailyClassSchedule> schedules;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (schedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Không có lịch học trong ngày này',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();

    return Stack(
      children: [
        Positioned(
          left: 11,
          top: 16,
          bottom: 16,
          child: Container(width: 2, color: AppColors.surfaceBorder),
        ),
        Column(
          children: [
            for (var i = 0; i < schedules.length; i++) ...[
              _ScheduleTimelineItem(
                schedule: schedules[i],
                status: schedules[i].statusAt(now),
              ),
              if (i < schedules.length - 1) const SizedBox(height: 24),
            ],
          ],
        ),
      ],
    );
  }
}

class _ScheduleTimelineItem extends StatelessWidget {
  const _ScheduleTimelineItem({
    required this.schedule,
    required this.status,
  });

  final DailyClassSchedule schedule;
  final DailyScheduleStatus status;

  @override
  Widget build(BuildContext context) {
    final isLive = status == DailyScheduleStatus.live;
    final isUpcoming = status == DailyScheduleStatus.upcoming;

    final dotColor = isLive
        ? AppColors.success
        : (isUpcoming ? AppColors.primaryIndigo : AppColors.surfaceBorder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: isLive
                    ? const [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: Center(
                child: isLive
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : Icon(
                        isUpcoming
                            ? Icons.schedule
                            : Icons.calendar_today_outlined,
                        size: 12,
                        color: isUpcoming
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                schedule.timeRange,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ĐANG DIỄN RA',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.success,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isLive
                      ? AppColors.shadowMedium
                      : AppColors.shadow,
                  blurRadius: isLive ? 6 : 1,
                  offset: Offset(0, isLive ? 2 : 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.className,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (schedule.instructorName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _MetaPill(label: schedule.instructorName),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
    required this.icon,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 14, color: foregroundColor),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.backgroundColor,
    required this.child,
    this.size = 36,
  });

  final Color backgroundColor;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
