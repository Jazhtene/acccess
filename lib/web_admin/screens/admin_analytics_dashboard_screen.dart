import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/layout/admin_data_constants.dart';
import 'package:access_mobile/web_admin/layout/admin_feature_page.dart';
import 'package:access_mobile/web_admin/layout/admin_route_breadcrumbs.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/data_table_card.dart';
import 'package:access_mobile/web_admin/layout/page_header.dart';
import 'package:access_mobile/web_admin/layout/status_badge.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class AdminAnalyticsDashboardScreen extends StatefulWidget {
  const AdminAnalyticsDashboardScreen({super.key});

  @override
  State<AdminAnalyticsDashboardScreen> createState() => _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState extends State<AdminAnalyticsDashboardScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads analytics report snapshots from PostgreSQL `analytics_reports`.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await adminApi.allAnalyticsReports();
      if (mounted) {
        setState(() {
          _reports = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _reports = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFeaturePage(
      title: 'Analytics Dashboard',
      subtitle: 'Overview of generated reports, exports, and analytics modules.',
      breadcrumbs: breadcrumbsForRoute(AdminRoute.analyticsDashboard),
      loading: _loading,
      error: _error,
      errorTitle: 'Unable to load analytics reports',
      onRetry: _load,
      actions: [PageHeaderIconButton(icon: Icons.refresh, onPressed: _load, tooltip: 'Refresh')],
      body: DataTableCard(
        title: 'Report catalog',
        shownCount: _reports.length,
        totalCount: _reports.length,
        emptyTitle: AdminDataConstants.emptyRecordsTitle,
        emptyMessage: AdminDataConstants.emptyRecordsMessage,
        child: ResponsiveTableScroll(
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 48,
            columns: const [
              DataColumn(label: Text('Report')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Exported')),
              DataColumn(label: Text('Generated')),
            ],
            rows: _reports
                .map(
                  (r) => DataRow(
                    cells: [
                      DataCell(Text((r['title'] ?? '—').toString())),
                      DataCell(Text((r['category'] ?? '—').toString())),
                      DataCell(StatusBadge.active((r['status'] ?? '—').toString())),
                      DataCell(Text(r['exported'] == true ? 'Yes' : 'No')),
                      DataCell(Text((r['generated_at'] ?? '—').toString())),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
