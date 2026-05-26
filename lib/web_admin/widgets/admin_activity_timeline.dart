import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class AdminActivityItem {
  const AdminActivityItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.time,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final String status;
  final String time;
  final String kind;

  factory AdminActivityItem.fromMap(Map<String, dynamic> m) => AdminActivityItem(
        title: m['title'] as String? ?? '',
        subtitle: m['subtitle'] as String? ?? '',
        status: m['status'] as String? ?? '',
        time: m['time'] as String? ?? '',
        kind: m['kind'] as String? ?? 'request',
      );
}

class AdminActivityTimeline extends StatelessWidget {
  const AdminActivityTimeline({super.key, required this.items});

  final List<AdminActivityItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No recent activity yet.',
          style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _ActivityRow(item: items[i], isLast: i == items.length - 1),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.isLast});
  final AdminActivityItem item;
  final bool isLast;

  IconData get _icon {
    switch (item.kind) {
      case 'member':
        return Icons.person_add_alt_1_outlined;
      case 'media':
        return Icons.photo_library_outlined;
      case 'task':
        return Icons.assignment_outlined;
      case 'feedback':
        return Icons.rate_review_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Color get _statusColor {
    final s = item.status.toLowerCase();
    if (s.contains('pending')) return AdminTheme.warning;
    if (s.contains('reject')) return AdminTheme.danger;
    if (s.contains('approv') || s.contains('assign') || s.contains('open')) {
      return AdminTheme.success;
    }
    return AdminTheme.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AdminTheme.accentCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon, size: 18, color: AdminTheme.accentBlue),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AdminTheme.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AdminTheme.textPrimary,
                          ),
                        ),
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.time,
                        style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
