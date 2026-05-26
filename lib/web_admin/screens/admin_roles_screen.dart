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

/// Roles & permissions — data from PostgreSQL `roles` via GET /api/admin/roles.
class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await adminApi.allRoles();
      if (mounted) {
        setState(() {
          _roles = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _roles = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFeaturePage(
      title: 'Roles & Permissions',
      subtitle: 'Manage Admin, Member, and Organization roles from the database.',
      breadcrumbs: breadcrumbsForRoute(AdminRoute.roles),
      loading: _loading,
      error: _error,
      errorTitle: 'Unable to load roles',
      onRetry: _load,
      actions: [
        PageHeaderIconButton(icon: Icons.refresh, onPressed: _load, tooltip: 'Refresh'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataTableCard(
            title: 'System roles',
            shownCount: _roles.length,
            totalCount: _roles.length,
            emptyTitle: AdminDataConstants.emptyRecordsTitle,
            emptyMessage: AdminDataConstants.emptyRecordsMessage,
            child: AdminDataTableTheme(
              child: ResponsiveTableScroll(
                child: DataTable(
                  headingRowHeight: 44,
                  columns: const [
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Users')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Permissions')),
                  ],
                  rows: _roles.map(_row).toList(),
                ),
              ),
            ),
          ),
          if (_roles.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'RBAC overview',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            ..._roles.map(_permissionCard),
          ],
        ],
      ),
    );
  }

  DataRow _row(Map<String, dynamic> r) {
    final perms = (r['permissions'] as List?)?.cast<String>() ?? [];
    return DataRow(
      cells: [
        DataCell(
          Text(
            (r['role_name'] ?? r['name'] ?? '—').toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(
          SizedBox(
            width: 280,
            child: Text(
              (r['description'] ?? '—').toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(Text('${r['user_count'] ?? 0}')),
        DataCell(Text((r['status'] ?? 'active').toString())),
        DataCell(Text(perms.isEmpty ? '—' : perms.join(', '))),
      ],
    );
  }

  Widget _permissionCard(Map<String, dynamic> r) {
    final name = (r['role_name'] ?? r['name'] ?? 'Role').toString();
    final perms = (r['permissions'] as List?)?.cast<String>() ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AdminTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: perms
                .map(
                  (p) => Chip(
                    label: Text(p, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AdminTheme.accentBlue.withValues(alpha: 0.08),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
