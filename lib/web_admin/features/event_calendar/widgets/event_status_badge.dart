import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/event_calendar/event_calendar_models.dart';

/// Colored pill for calendar event status.
class EventStatusBadge extends StatelessWidget {
  const EventStatusBadge({super.key, required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final color = eventStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        eventStatusLabel(status),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
