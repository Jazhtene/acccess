import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';
import 'package:access_mobile/mobile_app/widgets/calendar_event_tile.dart';
import 'package:access_mobile/mobile_app/sheets/event_detail_sheet.dart';
import 'package:access_mobile/mobile_app/widgets/mobile_ui_kit.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  String _typeFilter = 'All';

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _typeFilters = ['All', 'Coverage', 'Meeting', 'Documentation'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  DateTime? _parseEventDate(String dateStr) {
    const monthMap = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    try {
      final parts = dateStr.split(', ');
      final dp = parts[0].split(' ');
      return DateTime(DateTime.now().year, monthMap[dp[0]] ?? 1, int.parse(dp[1]));
    } catch (_) {
      return null;
    }
  }

  bool _matchesType(CalendarEvent e) {
    if (_typeFilter == 'All') return true;
    final tag = e.tag.toLowerCase();
    if (_typeFilter == 'Coverage') return tag.contains('coverage') || tag.contains('event');
    if (_typeFilter == 'Meeting') return tag.contains('meeting');
    if (_typeFilter == 'Documentation') return tag.contains('doc') || tag.contains('media');
    return true;
  }

  List<CalendarEvent> _eventsForDay(DateTime day) => appState.events.where((e) {
        if (!_matchesType(e)) return false;
        final d = _parseEventDate(e.date);
        return d != null && d.year == day.year && d.month == day.month && d.day == day.day;
      }).toList();

  bool _hasEvent(DateTime day) => _eventsForDay(day).isNotEmpty;

  void _prevMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  void _nextMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final rows = ((startWeekday + daysInMonth) / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MobilePageTitle(
          title: 'Calendar',
          subtitle: 'Assigned events, coverage, and documentation schedules.',
        ),
        MobileFilterChips(
          filters: _typeFilters,
          selected: _typeFilter,
          onSelected: (f) => setState(() => _typeFilter = f),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([appState, memberDataController]),
            builder: (_, __) {
              if (memberDataController.isLoading && appState.events.isEmpty) {
                return const MobileLoadingView(message: 'Loading calendar…');
              }

              final events = _selectedDay != null
                  ? _eventsForDay(_selectedDay!)
                  : appState.events.where(_matchesType).toList();

              return RefreshIndicator(
                color: kAccent,
                onRefresh: () => memberDataController.refreshAll(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(kMobilePagePadding, 0, kMobilePagePadding, 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _navBtn(Icons.chevron_left, _prevMonth),
                                Column(
                                  children: [
                                    Text(
                                      _monthNames[_focusedMonth.month - 1],
                                      style: const TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${_focusedMonth.year}',
                                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                                _navBtn(Icons.chevron_right, _nextMonth),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: _weekdays
                                  .map((d) => Expanded(
                                        child: Center(
                                          child: Text(
                                            d,
                                            style: const TextStyle(
                                              color: kTextSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 6),
                            ...List.generate(rows, (row) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: List.generate(7, (col) {
                                      final dayNum = row * 7 + col - startWeekday + 1;
                                      if (dayNum < 1 || dayNum > daysInMonth) {
                                        return const Expanded(child: SizedBox(height: 48));
                                      }
                                      final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                                      final isSelected = _selectedDay != null &&
                                          _selectedDay!.year == date.year &&
                                          _selectedDay!.month == date.month &&
                                          _selectedDay!.day == date.day;
                                      final isToday = today.year == date.year &&
                                          today.month == date.month &&
                                          today.day == date.day;
                                      final hasEv = _hasEvent(date);
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _selectedDay = date),
                                          child: Container(
                                            height: 48,
                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? const LinearGradient(
                                                      colors: [kCyan, kPurple],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    )
                                                  : null,
                                              color: isSelected
                                                  ? null
                                                  : isToday
                                                      ? kCyanDim
                                                      : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              border: isToday && !isSelected
                                                  ? Border.all(color: kCyan.withValues(alpha: 0.65), width: 1.5)
                                                  : null,
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '$dayNum',
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : isToday
                                                            ? kCyan
                                                            : kTextPrimary,
                                                    fontSize: 13,
                                                    fontWeight: isSelected || isToday
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                if (hasEv)
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: List.generate(
                                                      2,
                                                      (_) => Container(
                                                        width: 4,
                                                        height: 4,
                                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                                        decoration: BoxDecoration(
                                                          color: isSelected ? Colors.white : kAccent,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  const SizedBox(height: 4),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                )),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _selectedDay != null
                                    ? '${_monthNames[_selectedDay!.month - 1]} ${_selectedDay!.day}, ${_selectedDay!.year}'
                                    : 'All Events',
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    if (events.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: MobileEmptyState(
                          icon: Icons.event_available,
                          title: 'No events',
                          subtitle: _typeFilter == 'All'
                              ? 'No events on this day.'
                              : 'No $_typeFilter events on this day.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(kMobilePagePadding, 0, kMobilePagePadding, 24),
                        sliver: SliverList.separated(
                          itemCount: events.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => CalendarEventTile(
                            event: events[i],
                            onTap: () => showEventDetail(context, events[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kSurfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: Icon(icon, color: kTextSecondary, size: 20),
        ),
      );
}
