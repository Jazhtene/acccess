import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/event_calendar/event_calendar_models.dart';
import 'package:access_mobile/web_admin/features/event_calendar/widgets/event_status_badge.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class UpcomingEventList extends StatelessWidget {
  const UpcomingEventList({
    super.key,
    required this.events,
    required this.onEventTap,
    this.title = 'Upcoming events',
  });

  final List<CalendarEventItem> events;
  final ValueChanged<CalendarEventItem> onEventTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No upcoming events in this view.',
                  style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...events.take(8).map((e) => _EventTile(event: e, onTap: () => onEventTap(e))),
        ],
      ),
    );
  }
}

class _EventTile extends StatefulWidget {
  const _EventTile({required this.event, required this.onTap});
  final CalendarEventItem event;
  final VoidCallback onTap;

  @override
  State<_EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<_EventTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Material(
          color: _hovered ? AdminTheme.contentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hovered ? AdminTheme.accentCyan.withValues(alpha: 0.45) : AdminTheme.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      EventStatusBadge(status: e.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${e.dateLabel} · ${e.timeLabel}',
                    style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                  ),
                  if (e.location != null && e.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      e.location!,
                      style: const TextStyle(fontSize: 12, color: AdminTheme.textPrimary),
                    ),
                  ],
                  if (e.assignedMemberName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Team: ${e.assignedMemberName}',
                      style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                    ),
                  ],
                  if (e.requestStatus != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Request: ${e.requestStatus}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AdminTheme.accentBlue.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
