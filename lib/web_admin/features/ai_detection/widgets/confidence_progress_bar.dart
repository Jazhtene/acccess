import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/ai_detection/ai_detection_models.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class ConfidenceProgressBar extends StatelessWidget {
  const ConfidenceProgressBar({
    super.key,
    required this.score,
    required this.label,
    this.confidenceLevel,
  });

  final double score;
  final String label;
  final ConfidenceLevel? confidenceLevel;

  @override
  Widget build(BuildContext context) {
    final pct = score.clamp(0.0, 1.0);
    final level = confidenceLevel ?? confidenceLevelForScore(pct);
    final barColor = switch (level) {
      ConfidenceLevel.high => AdminTheme.success,
      ConfidenceLevel.medium => AdminTheme.accentBlue,
      ConfidenceLevel.low => AdminTheme.warning,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary),
              ),
            ),
            ConfidenceLevelBadge(level: level),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct > 0 ? pct : null,
            minHeight: 8,
            backgroundColor: AdminTheme.border,
            color: barColor,
          ),
        ),
      ],
    );
  }
}

class ConfidenceLevelBadge extends StatelessWidget {
  const ConfidenceLevelBadge({super.key, required this.level});
  final ConfidenceLevel level;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (level) {
      ConfidenceLevel.high => ('High', AdminTheme.success),
      ConfidenceLevel.medium => ('Medium', AdminTheme.accentBlue),
      ConfidenceLevel.low => ('Low', AdminTheme.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
