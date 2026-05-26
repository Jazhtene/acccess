import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/features/ai_detection/ai_detection_models.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/ai_result_badge.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/ai_review_status_badge.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/confidence_progress_bar.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

typedef AiRowAction = void Function(AiDetectionRow row);
typedef AiReviewAction = Future<void> Function(AiDetectionRow row, ReviewStatus status, String remarks);
typedef AiConfirmAction = Future<bool?> Function(String title, String message, {IconData icon});

class AiDetectionResultItem extends StatefulWidget {
  const AiDetectionResultItem({
    super.key,
    required this.row,
    required this.onViewDetails,
    required this.onReview,
    required this.onQuickAction,
    required this.onConfirm,
    this.onArchive,
  });

  final AiDetectionRow row;
  final AiRowAction onViewDetails;
  final AiRowAction onReview;
  final AiReviewAction onQuickAction;
  final AiConfirmAction onConfirm;
  final AiRowAction? onArchive;

  @override
  State<AiDetectionResultItem> createState() => _AiDetectionResultItemState();
}

class _AiDetectionResultItemState extends State<AiDetectionResultItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final thumbUrl = AdminApiService.mediaUrl(row.mediaUrl.isNotEmpty ? row.mediaUrl : null);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: AdminTheme.cardDecoration().copyWith(
          border: Border.all(
            color: _hovered ? AdminTheme.accentCyan.withValues(alpha: 0.4) : AdminTheme.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: thumbUrl.isNotEmpty
                  ? Image.network(
                      thumbUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.mediaName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      AiResultBadge(label: row.aiLabel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    row.memberName,
                    style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ConfidenceProgressBar(
                    score: row.confidenceScore,
                    label: row.confidenceText,
                    confidenceLevel: row.confidenceLevel,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AiReviewStatusBadge(status: row.reviewStatus),
                      Text(
                        'Scanned ${formatScannedDate(row.scannedAt)}',
                        style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  onPressed: () => widget.onViewDetails(row),
                  icon: const Icon(Icons.info_outline, size: 20),
                  tooltip: 'View details',
                ),
                IconButton(
                  onPressed: () => widget.onReview(row),
                  icon: const Icon(Icons.open_in_new, size: 20),
                  tooltip: 'Open media',
                ),
                if (widget.onArchive != null)
                  IconButton(
                    onPressed: () => widget.onArchive!(row),
                    icon: const Icon(Icons.archive_outlined, size: 20),
                    tooltip: 'Archive',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: AdminTheme.contentBg,
      child: const Icon(Icons.image_outlined, color: AdminTheme.textSecondary, size: 32),
    );
  }
}
