import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/media_evaluation/media_evaluation_models.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class AiResultBadge extends StatelessWidget {
  const AiResultBadge({super.key, required this.label});

  final AiResultLabel label;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (label) {
      AiResultLabel.human => ('Human', AdminTheme.success),
      AiResultLabel.aiGenerated => ('AI-Generated', const Color(0xFFEA580C)),
      AiResultLabel.suspicious => ('Suspicious', AdminTheme.warning),
      AiResultLabel.pending => ('Pending', AdminTheme.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
