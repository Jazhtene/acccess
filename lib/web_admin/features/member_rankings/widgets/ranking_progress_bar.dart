import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class RankingProgressBar extends StatelessWidget {
  const RankingProgressBar({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    this.color,
  });

  final num value;
  final num max;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final barColor = color ?? AdminTheme.accentCyan;

    return Tooltip(
      message: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$value',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              const Spacer(),
              if (max > 0)
                Text(
                  '${(pct * 100).round()}%',
                  style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct > 0 ? pct : null,
              minHeight: 5,
              backgroundColor: AdminTheme.border,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}
