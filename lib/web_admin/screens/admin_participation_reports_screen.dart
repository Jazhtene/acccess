import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/layout/admin_data_constants.dart';
import 'package:access_mobile/web_admin/layout/admin_feature_page.dart';
import 'package:access_mobile/web_admin/layout/admin_route_breadcrumbs.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/data_table_card.dart';
import 'package:access_mobile/web_admin/layout/page_header.dart';
import 'package:access_mobile/web_admin/navigation/admin_navigation_scope.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class AdminParticipationReportsScreen extends StatefulWidget {
  const AdminParticipationReportsScreen({super.key});

  @override
  State<AdminParticipationReportsScreen> createState() => _AdminParticipationReportsScreenState();
}

class _AdminParticipationReportsScreenState extends State<AdminParticipationReportsScreen> {
  List<List<String>> _allRows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Builds participation table rows from PostgreSQL member rankings (GET /api/rankings).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await adminApi.rankings();
      final rows = list.map(_rowFromRanking).toList();
      if (mounted) {
        setState(() {
          _allRows = rows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _allRows = [];
          _loading = false;
        });
      }
    }
  }

  List<String> _rowFromRanking(Map<String, dynamic> r) {
    final status = (r['participation_status'] as String? ?? 'active').replaceAll('_', ' ');
    final label = status.isEmpty
        ? 'Active'
        : '${status[0].toUpperCase()}${status.substring(1)}';
    final displayStatus = label.contains('needs') ? 'Needs improvement' : label;
    return [
      (r['member_name'] ?? r['name'] ?? '—').toString(),
      '${r['completed_tasks'] ?? 0}',
      '${r['uploads'] ?? r['total_uploads'] ?? 0}',
      '${((r['task_participation_score'] as num? ?? 0) * 100).round()}%',
      (r['avg_score'] ?? r['average_quality_score'] ?? '—').toString(),
      displayStatus,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdminFeaturePage(
      title: 'Participation Reports',
      subtitle: 'Member event participation, uploads, and engagement metrics.',
      breadcrumbs: breadcrumbsForRoute(AdminRoute.participationReports),
      loading: _loading,
      error: _error,
      errorTitle: 'Unable to load participation data',
      onRetry: _load,
      actions: [
        PageHeaderButton(
          label: 'Open rankings',
          icon: Icons.leaderboard_outlined,
          onPressed: () => AdminNavigationScope.go(context, AdminRoute.rankings),
        ),
        PageHeaderIconButton(icon: Icons.refresh, onPressed: _load, tooltip: 'Refresh'),
      ],
      body: DataTableCard(
        title: 'Member participation',
        shownCount: _allRows.length,
        totalCount: _allRows.length,
        emptyTitle: AdminDataConstants.emptyRecordsTitle,
        emptyMessage: AdminDataConstants.emptyRecordsMessage,
        child: ResponsiveTableScroll(
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 48,
            columns: const [
              DataColumn(label: Text('Member')),
              DataColumn(label: Text('Tasks completed')),
              DataColumn(label: Text('Uploads')),
              DataColumn(label: Text('Task participation')),
              DataColumn(label: Text('Avg quality')),
              DataColumn(label: Text('Status')),
            ],
            rows: _allRows
                .map(
                  (row) => DataRow(
                    cells: row.map((cell) => DataCell(Text(cell))).toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
