import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/ai_detection/ai_detection_models.dart';

/// Colored badge for AI review workflow status.
class AiReviewStatusBadge extends StatelessWidget {
  const AiReviewStatusBadge({super.key, required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final color = reviewStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        reviewStatusLabel(status),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Backward-compatible alias.
typedef ReviewStatusBadge = AiReviewStatusBadge;
