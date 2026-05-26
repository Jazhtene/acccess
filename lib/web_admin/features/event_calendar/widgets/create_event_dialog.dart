import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/event_calendar/event_calendar_models.dart';
import 'package:access_mobile/web_admin/features/event_calendar/widgets/event_form.dart';

class CreateEventDialog extends StatelessWidget {
  const CreateEventDialog({
    super.key,
    required this.onCreate,
    this.members = const [],
  });

  final Future<void> Function(CalendarEventItem item) onCreate;
  final List<(int id, String name)> members;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(CalendarEventItem item) onCreate,
    List<(int id, String name)> members = const [],
  }) {
    return showDialog(
      context: context,
      builder: (_) => CreateEventDialog(onCreate: onCreate, members: members),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Create Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: EventForm(
                    members: members,
                    submitLabel: 'Create event',
                    onSubmit: (item) async {
                      await onCreate(item);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
