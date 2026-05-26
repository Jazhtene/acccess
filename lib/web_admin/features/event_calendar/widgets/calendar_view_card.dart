import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:access_mobile/web_admin/features/event_calendar/event_calendar_models.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

enum CalendarViewMode { month, week, day }

class CalendarViewCard extends StatelessWidget {
  const CalendarViewCard({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.viewMode,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onViewModeChanged,
    required this.onToday,
    required this.onEventTap,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarViewMode viewMode;
  final List<CalendarEventItem> events;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final ValueChanged<CalendarViewMode> onViewModeChanged;
  final VoidCallback onToday;
  final ValueChanged<CalendarEventItem> onEventTap;

  CalendarFormat get _format => switch (viewMode) {
        CalendarViewMode.month => CalendarFormat.month,
        CalendarViewMode.week => CalendarFormat.week,
        CalendarViewMode.day => CalendarFormat.week,
      };

  List<CalendarEventItem> _forDay(DateTime day) =>
      events.where((e) => e.occursOn(day)).toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Calendar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              SegmentedButton<CalendarViewMode>(
                segments: const [
                  ButtonSegment(value: CalendarViewMode.month, label: Text('Month')),
                  ButtonSegment(value: CalendarViewMode.week, label: Text('Week')),
                  ButtonSegment(value: CalendarViewMode.day, label: Text('Day')),
                ],
                selected: {viewMode},
                onSelectionChanged: (s) => onViewModeChanged(s.first),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onToday, child: const Text('Today')),
            ],
          ),
          const SizedBox(height: 12),
          TableCalendar<CalendarEventItem>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            calendarFormat: _format,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week',
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            eventLoader: _forDay,
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AdminTheme.accentCyan.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: AdminTheme.accentCyan, width: 1.5),
              ),
              selectedDecoration: const BoxDecoration(
                color: AdminTheme.accentBlue,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AdminTheme.accentCyan,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, dayEvents) {
                if (dayEvents.isEmpty) return null;
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      dayEvents.length.clamp(0, 3),
                      (_) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: eventStatusColor(dayEvents.first.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (viewMode == CalendarViewMode.day) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Events on ${selectedDay.month}/${selectedDay.day}/${selectedDay.year}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ..._forDay(selectedDay).map(
              (e) => ListTile(
                dense: true,
                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${e.timeLabel} · ${e.location ?? 'TBA'}'),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => onEventTap(e),
              ),
            ),
            if (_forDay(selectedDay).isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('No events on this day.', style: TextStyle(color: AdminTheme.textSecondary)),
              ),
          ],
        ],
      ),
    );
  }
}
