import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/member_rankings/member_ranking_models.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class SkillLevelBadge extends StatelessWidget {
  const SkillLevelBadge({
    super.key,
    required this.tier,
    this.label,
    this.skillScore,
    this.showTooltip = true,
  });

  final SkillLevelTier tier;
  final String? label;
  final double? skillScore;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final (defaultLabel, color) = switch (tier) {
      SkillLevelTier.expert => ('Expert', const Color(0xFF7C3AED)),
      SkillLevelTier.advanced => ('Advanced', AdminTheme.accentBlue),
      SkillLevelTier.intermediate => ('Intermediate', AdminTheme.accentCyan),
      SkillLevelTier.beginner => ('Beginner', AdminTheme.textSecondary),
    };

    final displayLabel = label ?? defaultLabel;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayLabel,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
          if (skillScore != null) ...[
            const SizedBox(width: 6),
            Text(
              '${skillScore!.round()}%',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.85)),
            ),
          ],
        ],
      ),
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message: kSkillScoreTooltip,
      preferBelow: true,
      child: badge,
    );
  }
}
