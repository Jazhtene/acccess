import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/member_rankings/member_ranking_models.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class ParticipationStatusBadge extends StatelessWidget {
  const ParticipationStatusBadge({super.key, required this.status});

  final ParticipationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ParticipationStatus.active => ('Active', AdminTheme.success),
      ParticipationStatus.inactive => ('Inactive', AdminTheme.textSecondary),
      ParticipationStatus.needsTraining => ('Needs Training', AdminTheme.warning),
      ParticipationStatus.underReview => ('Under Review', const Color(0xFFEA580C)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
