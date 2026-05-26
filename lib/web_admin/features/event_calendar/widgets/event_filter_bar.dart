import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/event_calendar/event_calendar_models.dart';

class EventFilterBar extends StatelessWidget {
  const EventFilterBar({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.memberFilter,
    required this.members,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onMemberChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final EventStatus? statusFilter;
  final String? memberFilter;
  final List<String> members;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<EventStatus?> onStatusChanged;
  final ValueChanged<String?> onMemberChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by event title…',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear filters'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 180,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Status', isDense: true),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EventStatus?>(
                    value: statusFilter,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All statuses')),
                      ...EventStatus.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(eventStatusLabel(s))),
                      ),
                    ],
                    onChanged: onStatusChanged,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Assigned member', isDense: true),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: memberFilter,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All members')),
                      ...members.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                    ],
                    onChanged: onMemberChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
