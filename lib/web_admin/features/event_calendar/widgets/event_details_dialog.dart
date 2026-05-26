import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/event_calendar/event_calendar_models.dart';
import 'package:access_mobile/web_admin/features/event_calendar/widgets/event_form.dart';
import 'package:access_mobile/web_admin/features/event_calendar/widgets/event_status_badge.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class EventDetailsDialog extends StatefulWidget {
  const EventDetailsDialog({
    super.key,
    required this.event,
    required this.onUpdate,
    required this.onDelete,
    this.members = const [],
  });

  final CalendarEventItem event;
  final Future<void> Function(CalendarEventItem item) onUpdate;
  final Future<void> Function(CalendarEventItem event) onDelete;
  final List<(int id, String name)> members;

  static Future<void> show(
    BuildContext context, {
    required CalendarEventItem event,
    required Future<void> Function(CalendarEventItem item) onUpdate,
    required Future<void> Function(CalendarEventItem event) onDelete,
    List<(int id, String name)> members = const [],
  }) {
    return showDialog(
      context: context,
      builder: (_) => EventDetailsDialog(
        event: event,
        onUpdate: onUpdate,
        onDelete: onDelete,
        members: members,
      ),
    );
  }

  @override
  State<EventDetailsDialog> createState() => _EventDetailsDialogState();
}

class _EventDetailsDialogState extends State<EventDetailsDialog> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing ? 'Edit Event' : e.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (!_editing) EventStatusBadge(status: e.status),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: _editing
                      ? EventForm(
                          initial: e,
                          members: widget.members,
                          submitLabel: 'Save changes',
                          onSubmit: (item) async {
                            await widget.onUpdate(item);
                            if (mounted) {
                              setState(() => _editing = false);
                              Navigator.pop(context);
                            }
                          },
                        )
                      : _detailsView(e),
                ),
              ),
              if (!_editing) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete event?'),
                            content: Text('Remove "${e.title}" from the calendar?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await widget.onDelete(e);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _editing = true),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailsView(CalendarEventItem e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Date', e.dateLabel),
        _row('Time', e.timeLabel),
        _row('Location', e.location ?? 'TBA'),
        if (e.description != null && e.description!.isNotEmpty) _row('Description', e.description!),
        if (e.assignedMemberName != null) _row('Assigned team', e.assignedMemberName!),
        if (e.documentationRequestId != null)
          _row('Documentation request', '#${e.documentationRequestId}'),
        if (e.requestStatus != null) _row('Request status', e.requestStatus!),
        if (e.adminRemarks != null && e.adminRemarks!.isNotEmpty) _row('Admin remarks', e.adminRemarks!),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
