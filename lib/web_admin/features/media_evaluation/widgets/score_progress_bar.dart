import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class ScoreProgressBar extends StatelessWidget {
  const ScoreProgressBar({
    super.key,
    required this.score,
    this.color,
    this.showLabel = true,
    this.height = 6,
  });

  final double score;
  final Color? color;
  final bool showLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pct = score.clamp(0.0, 1.0);
    final barColor = color ?? _colorForScore(pct);
    final label = '${(pct * 100).round()}%';

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: height,
              backgroundColor: AdminTheme.border,
              color: barColor,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AdminTheme.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _colorForScore(double s) {
    if (s >= 0.8) return AdminTheme.success;
    if (s >= 0.6) return AdminTheme.accentBlue;
    return AdminTheme.warning;
  }
}
