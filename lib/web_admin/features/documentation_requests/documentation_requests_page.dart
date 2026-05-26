import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/config/admin_permissions.dart';
import 'package:access_mobile/web_admin/layout/admin_data_constants.dart';
import 'package:access_mobile/web_admin/layout/admin_feature_page.dart';
import 'package:access_mobile/web_admin/layout/admin_route_breadcrumbs.dart';
import 'package:access_mobile/web_admin/layout/admin_session_scope.dart';
import 'package:access_mobile/web_admin/layout/alert_banner.dart';
import 'package:access_mobile/web_admin/layout/confirm_dialog.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/data_table_card.dart';
import 'package:access_mobile/web_admin/layout/page_header.dart';
import 'package:access_mobile/web_admin/layout/pagination_state.dart';
import 'package:access_mobile/web_admin/layout/search_filter_card.dart';
import 'package:access_mobile/web_admin/layout/status_badge.dart';
import 'package:access_mobile/web_admin/layout/active_filter_chip_bar.dart';
import 'package:access_mobile/web_admin/navigation/admin_navigation_scope.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class DocumentationRequestsPage extends StatefulWidget {
  const DocumentationRequestsPage({super.key});

  @override
  State<DocumentationRequestsPage> createState() => _DocumentationRequestsPageState();
}

class _DocumentationRequestsPageState extends State<DocumentationRequestsPage> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String? _error;
  bool _showFilters = true;
  DateTime? _lastUpdated;
  final _pagination = PaginationState();
  String _search = '';
  String? _statusFilter;
  String? _cardFilterLabel;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyRouteIntent());
  }

  void _applyRouteIntent() {
    final params = AdminNavigationScope.consumeParams(context, AdminRoute.docRequests);
    if (params == null) return;
    final status = params['statusFilter'] as String?;
    if (status != null) {
      _applyStatusCardFilter(status);
    }
  }

  void _applyStatusCardFilter(String status) {
    setState(() {
      _statusFilter = status;
      _cardFilterLabel = 'Showing: $status Requests';
      _pagination.reset();
    });
  }

  void _clearCardFilter() {
    setState(() {
      _statusFilter = null;
      _cardFilterLabel = null;
      _search = '';
      _searchController.clear();
      _pagination.reset();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // PostgreSQL documentation_requests via GET /api/admin/service-requests
      final list = await adminApi.allServiceRequests();
      if (mounted) {
        setState(() {
          _all = list;
          _loading = false;
          _lastUpdated = DateTime.now();
          _pagination.reset();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _all = [];
          _loading = false;
          _lastUpdated = DateTime.now();
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _all.where((r) {
      final name = (r['event_name'] ?? r['title'] ?? '').toString().toLowerCase();
      final requester = (r['requester_name'] ?? '').toString().toLowerCase();
      if (_search.isNotEmpty &&
          !name.contains(_search.toLowerCase()) &&
          !requester.contains(_search.toLowerCase())) {
        return false;
      }
      if (_statusFilter != null && (r['status'] as String?) != _statusFilter) return false;
      return true;
    }).toList();
  }

  int get _pending => _all.where((r) => (r['status'] as String?) == 'Pending').length;
  Future<void> _update(int id, String status) async {
    final label = status == 'Approved' ? 'approve' : 'reject';
    final ok = await ConfirmDialog.show(
      context,
      title: '${status == 'Approved' ? 'Approve' : 'Reject'} this request?',
      message: 'Are you sure you want to $label this documentation request?',
      confirmLabel: status == 'Approved' ? 'Approve' : 'Reject',
      destructive: status == 'Rejected',
      icon: status == 'Approved' ? Icons.check_circle_outline : Icons.cancel_outlined,
    );
    if (ok != true) return;

    try {
      await adminApi.setRequestStatus(id, status);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update request')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AdminSessionScope.of(context);
    final canApprove = session.role.can(AdminCapability.approveMembers);
    final filtered = _filtered;
    final pageRows = _pagination.slice(filtered);

    return AdminFeaturePage(
      title: 'Documentation Requests',
      subtitle: 'Review, approve, or reject service and documentation requests.',
      breadcrumbs: breadcrumbsForRoute(AdminRoute.docRequests),
      lastUpdated: _lastUpdated,
      loading: _loading,
      error: _error,
      errorTitle: 'Unable to load documentation requests',
      onRetry: _load,
      alert: _pending > 0
          ? AlertBanner(
              message: '$_pending request${_pending == 1 ? '' : 's'} pending review.',
              type: AlertBannerType.warning,
            )
          : null,
      actions: [
        PageHeaderButton(
          label: _showFilters ? 'Hide filters' : 'Filter results',
          icon: _showFilters ? Icons.filter_list_off : Icons.filter_list,
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        PageHeaderIconButton(icon: Icons.refresh, onPressed: _load),
      ],
      activeFilter: _cardFilterLabel != null
          ? ActiveFilterChipBar(label: _cardFilterLabel!, onClear: _clearCardFilter)
          : null,
      filter: _showFilters
          ? SearchFilterCard(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search event or requester…',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        _search = v;
                        _pagination.reset();
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Status', isDense: true),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _statusFilter,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                            DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                          ],
                          onChanged: (v) {
                            _statusFilter = v;
                            _pagination.reset();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _search = '';
                        _statusFilter = null;
                        _pagination.reset();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            )
          : null,
      body: DataTableCard(
        title: 'Request queue',
        shownCount: pageRows.length,
        totalCount: filtered.length,
        pagination: _pagination,
        rangeLabel: _pagination.rangeLabel(filtered.length),
        onPageChanged: (p) => setState(() => _pagination.page = p),
        onPageSizeChanged: (size) => setState(() {
          _pagination.pageSize = size;
          _pagination.reset();
        }),
        emptyTitle: AdminDataConstants.emptyRecordsTitle,
        emptyMessage: AdminDataConstants.emptyRecordsMessage,
        emptyIcon: Icons.description_outlined,
        emptyActionLabel: 'Refresh',
        onEmptyAction: _load,
        minHeight: 280,
        child: AdminDataTableTheme(
          child: ResponsiveTableScroll(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Event')),
                DataColumn(label: Text('Requester')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Venue')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: pageRows.map((r) {
                final id = r['request_id'] as int;
                final status = r['status'] as String? ?? 'Pending';
                return DataRow(
                  cells: [
                    DataCell(Text(r['event_name'] as String? ?? r['title'] as String? ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(r['requester_name'] as String? ?? '—')),
                    DataCell(Text(r['type'] as String? ?? 'Documentation')),
                    DataCell(Text(r['venue'] as String? ?? '—')),
                    DataCell(switch (status) {
                      'Approved' => StatusBadge.approved(),
                      'Rejected' => StatusBadge.rejected(),
                      _ => StatusBadge.pending(),
                    }),
                    DataCell(
                      status == 'Pending' && canApprove
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton(
                                  onPressed: () => _update(id, 'Approved'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AdminTheme.success,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  child: const Text('Approve'),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton(
                                  onPressed: () => _update(id, 'Rejected'),
                                  child: const Text('Reject'),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
