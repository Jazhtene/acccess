import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/ai_detection/ai_detection_models.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/ai_detection_result_item.dart';

class AiDetectionResultList extends StatelessWidget {
  const AiDetectionResultList({
    super.key,
    required this.rows,
    required this.onViewDetails,
    required this.onReview,
    required this.onQuickAction,
    required this.onConfirm,
    this.onArchive,
  });

  final List<AiDetectionRow> rows;
  final AiRowAction onViewDetails;
  final AiRowAction onReview;
  final AiReviewAction onQuickAction;
  final AiConfirmAction onConfirm;
  final AiRowAction? onArchive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...rows.map(
          (r) => AiDetectionResultItem(
            row: r,
            onViewDetails: onViewDetails,
            onReview: onReview,
            onQuickAction: onQuickAction,
            onConfirm: onConfirm,
            onArchive: onArchive,
          ),
        ),
      ],
    );
  }
}
