import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/ai_detection/ai_detection_models.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/ai_review_status_badge.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class ReviewHistoryTimeline extends StatelessWidget {
  const ReviewHistoryTimeline({
    super.key,
    required this.entries,
  });

  final List<AiReviewHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No review history yet.',
          style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review history', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 10),
        ...entries.map((e) => _HistoryTile(entry: e)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final AiReviewHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final status = reviewStatusFromString(entry.newStatus);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: reviewStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AiReviewStatusBadge(status: status),
                    if (entry.reviewedByName != null)
                      Text(
                        'by ${entry.reviewedByName}',
                        style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                      ),
                  ],
                ),
                if (entry.previousStatus != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'From ${entry.previousStatus!.replaceAll('_', ' ')}',
                    style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                  ),
                ],
                if (entry.adminRemarks != null && entry.adminRemarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(entry.adminRemarks!, style: const TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 2),
                Text(
                  formatScannedDate(entry.reviewedAt),
                  style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
