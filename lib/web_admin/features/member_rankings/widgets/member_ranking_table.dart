import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/member_rankings/member_ranking_models.dart';
import 'package:access_mobile/web_admin/features/member_rankings/widgets/participation_status_badge.dart';
import 'package:access_mobile/web_admin/features/member_rankings/widgets/rank_badge.dart';
import 'package:access_mobile/web_admin/features/member_rankings/widgets/ranking_progress_bar.dart';
import 'package:access_mobile/web_admin/features/member_rankings/widgets/skill_level_badge.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/data_table_card.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

typedef RankingRowAction = void Function(MemberRankingRow row);

class MemberRankingTable extends StatelessWidget {
  const MemberRankingTable({
    super.key,
    required this.rows,
    required this.maxPoints,
    required this.maxUploads,
    required this.onViewDetails,
  });

  final List<MemberRankingRow> rows;
  final int maxPoints;
  final int maxUploads;
  final RankingRowAction onViewDetails;

  @override
  Widget build(BuildContext context) {
    return AdminDataTableTheme(
      child: ResponsiveTableScroll(
        child: DataTable(
            columns: const [
              DataColumn(label: Text('Rank')),
              DataColumn(label: Text('Member Name')),
              DataColumn(label: Text('Skill Level')),
              DataColumn(label: Text('Skill Score')),
              DataColumn(label: Text('Points')),
              DataColumn(label: Text('Uploads')),
              DataColumn(label: Text('Avg Quality')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Last Activity')),
              DataColumn(label: Text('Actions')),
            ],
            rows: rows.map((r) => _row(r)).toList(),
        ),
      ),
    );
  }

  DataRow _row(MemberRankingRow r) {
    return DataRow(
      cells: [
        DataCell(RankBadge(rank: r.rank)),
        DataCell(
          Text(r.memberName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        DataCell(SkillLevelBadge(tier: r.skillTier, label: r.skillLevel)),
        DataCell(
          Tooltip(
            message: kSkillScoreTooltip,
            child: Text(
              r.skillScorePercent,
              style: const TextStyle(fontWeight: FontWeight.w800, color: AdminTheme.accentBlue, fontSize: 13),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 90,
            child: RankingProgressBar(
              value: r.points,
              max: maxPoints,
              label: 'Participation points',
              color: AdminTheme.accentBlue,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 80,
            child: RankingProgressBar(
              value: r.uploads,
              max: maxUploads,
              label: '${r.approvedUploads} approved of ${r.totalUploads} total',
              color: AdminTheme.accentCyan,
            ),
          ),
        ),
        DataCell(Text(r.qualityPercent, style: const TextStyle(fontWeight: FontWeight.w700))),
        DataCell(ParticipationStatusBadge(status: r.participationStatus)),
        DataCell(Text(formatLastActivity(r.lastActivity), style: const TextStyle(fontSize: 11))),
        DataCell(
          IconButton(
            onPressed: () => onViewDetails(r),
            icon: const Icon(Icons.info_outline, size: 20),
            tooltip: 'View member details and score breakdown',
          ),
        ),
      ],
    );
  }
}
