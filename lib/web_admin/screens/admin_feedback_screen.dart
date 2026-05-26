import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/layout/admin_data_constants.dart';
import 'package:access_mobile/web_admin/layout/admin_feature_page.dart';
import 'package:access_mobile/web_admin/layout/admin_route_breadcrumbs.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/data_table_card.dart';
import 'package:access_mobile/web_admin/layout/page_header.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads feedback rows from PostgreSQL via GET /api/admin/feedback.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await adminApi.allFeedback();
      if (mounted) {
        setState(() {
          _rows = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _rows = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFeaturePage(
      title: 'Feedback Reports',
      subtitle: 'Ratings and comments from event documentation feedback.',
      breadcrumbs: breadcrumbsForRoute(AdminRoute.feedbackReports),
      loading: _loading,
      error: _error,
      errorTitle: 'Unable to load feedback',
      onRetry: _load,
      actions: [PageHeaderIconButton(icon: Icons.refresh, onPressed: _load, tooltip: 'Refresh')],
      body: DataTableCard(
        title: 'Feedback records',
        shownCount: _rows.length,
        totalCount: _rows.length,
        emptyTitle: AdminDataConstants.emptyRecordsTitle,
        emptyMessage: AdminDataConstants.emptyRecordsMessage,
        child: ResponsiveTableScroll(
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 48,
            columns: const [
              DataColumn(label: Text('Event')),
              DataColumn(label: Text('Member')),
              DataColumn(label: Text('Rating')),
              DataColumn(label: Text('Comment')),
              DataColumn(label: Text('Submitted')),
            ],
            rows: _rows
                .map(
                  (r) => DataRow(
                    cells: [
                      DataCell(Text((r['event_title'] ?? r['event_name'] ?? '—').toString())),
                      DataCell(Text((r['member_name'] ?? r['user_name'] ?? '—').toString())),
                      DataCell(Text('${r['rating'] ?? '—'}')),
                      DataCell(Text((r['comment'] ?? r['feedback'] ?? '—').toString())),
                      DataCell(Text((r['created_at'] ?? '—').toString())),
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
