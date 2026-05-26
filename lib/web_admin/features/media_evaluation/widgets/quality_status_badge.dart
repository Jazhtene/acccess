import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/media_evaluation/media_evaluation_models.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class QualityStatusBadge extends StatelessWidget {
  const QualityStatusBadge({super.key, required this.status});

  final QualityStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      QualityStatus.excellent => ('Excellent', AdminTheme.success),
      QualityStatus.good => ('Good', AdminTheme.accentBlue),
      QualityStatus.fair => ('Fair', AdminTheme.warning),
      QualityStatus.needsImprovement => ('Needs Improvement', AdminTheme.danger),
    };

    return _Badge(label: label, color: color);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
