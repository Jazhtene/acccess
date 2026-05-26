import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/navigation/admin_navigation_scope.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';
import 'package:access_mobile/web_admin/widgets/admin_activity_timeline.dart';
import 'package:access_mobile/web_admin/layout/admin_data_constants.dart';
import 'package:access_mobile/web_admin/layout/admin_feature_page.dart';
import 'package:access_mobile/web_admin/layout/admin_route_breadcrumbs.dart';
import 'package:access_mobile/web_admin/layout/page_header.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/clickable_summary_card.dart';
import 'package:access_mobile/web_admin/widgets/admin_empty_state.dart';
import 'package:access_mobile/web_admin/widgets/admin_section_header.dart';

/// Admin home — summary counts and activity from PostgreSQL via [adminApi].
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<AdminActivityItem> _activity = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches dashboard aggregates and recent requests from the API (PostgreSQL).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await adminApi.dashboardStats();
      final requests = await adminApi.allServiceRequests();
      final activity = _buildActivityFromApi(requests);

      if (mounted) {
        setState(() {
          _stats = stats;
          _activity = activity;
          _loading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _stats = {};
          _activity = [];
          _loading = false;
          _lastUpdated = DateTime.now();
        });
      }
    }
  }

  List<AdminActivityItem> _buildActivityFromApi(List<Map<String, dynamic>> requests) {
    final items = <AdminActivityItem>[];
    for (final r in requests.take(8)) {
      items.add(
        AdminActivityItem(
          kind: 'request',
          title: r['event_name'] as String? ?? r['title'] as String? ?? 'Documentation request',
          subtitle: r['requester_name'] as String? ?? '',
          status: (r['status'] as String? ?? 'pending').toString(),
          time: r['created_at'] as String? ?? 'Recent',
        ),
      );
    }
    return items;
  }

  void _navigate(AdminRoute route, {Map<String, dynamic>? params}) =>
      AdminNavigationScope.go(context, route, params: params);

  @override
  Widget build(BuildContext context) {
    final s = _stats;

    return AdminFeaturePage(
      title: 'Dashboard',
      subtitle: 'Overview of documentation requests, members, media, and system activity.',
      breadcrumbs: breadcrumbsForRoute(AdminRoute.dashboard),
      lastUpdated: _lastUpdated,
      loading: _loading,
      error: _error,
      errorTitle: 'Unable to load dashboard',
      onRetry: _load,
      actions: [PageHeaderIconButton(icon: Icons.refresh, onPressed: _load, tooltip: 'Refresh')],
      summary: SummaryCardGrid(
        children: [
          ClickableSummaryCard(
            icon: Icons.people_outline,
            value: '${s['total_members'] ?? 0}',
            label: 'Total Members',
            description: 'All member accounts in the database',
            color: const Color(0xFF7C3AED),
            onTap: () => _navigate(AdminRoute.members),
          ),
          ClickableSummaryCard(
            icon: Icons.mark_email_unread_outlined,
            value: '${s['pending_requests'] ?? 0}',
            label: 'Pending Requests',
            description: 'Documentation awaiting review',
            color: AdminTheme.danger,
            onTap: () => _navigate(AdminRoute.docRequests, params: {'statusFilter': 'Pending'}),
          ),
          ClickableSummaryCard(
            icon: Icons.check_circle_outline,
            value: '${s['approved_requests'] ?? 0}',
            label: 'Approved Requests',
            description: 'Approved documentation requests',
            color: AdminTheme.success,
            onTap: () => _navigate(AdminRoute.docRequests, params: {'statusFilter': 'Approved'}),
          ),
          ClickableSummaryCard(
            icon: Icons.task_alt_outlined,
            value: '${s['completed_tasks'] ?? 0}',
            label: 'Completed Tasks',
            description: 'Finished member assignments',
            color: AdminTheme.accentBlue,
            onTap: () => _navigate(AdminRoute.taskAssignments),
          ),
          ClickableSummaryCard(
            icon: Icons.perm_media_outlined,
            value: '${s['media_uploads'] ?? 0}',
            label: 'Uploaded Media',
            description: 'Photos and videos in PostgreSQL',
            color: const Color(0xFF0891B2),
            onTap: () => _navigate(AdminRoute.mediaRepository),
          ),
          ClickableSummaryCard(
            icon: Icons.smart_toy_outlined,
            value: '${s['ai_flagged'] ?? 0}',
            label: 'AI-Detected Media',
            description: 'Flagged AI-generated results',
            color: const Color(0xFFDC2626),
            onTap: () => _navigate(AdminRoute.aiDetection),
          ),
          ClickableSummaryCard(
            icon: Icons.rate_review_outlined,
            value: '${s['feedback_count'] ?? 0}',
            label: 'Feedback Ratings',
            description: s['avg_feedback_rating'] != null
                ? 'Avg rating ${s['avg_feedback_rating']}'
                : 'Service feedback records',
            color: const Color(0xFFEA580C),
            onTap: () => _navigate(AdminRoute.feedbackReports),
          ),
          ClickableSummaryCard(
            icon: Icons.how_to_reg_outlined,
            value: '${s['pending_members'] ?? 0}',
            label: 'Member Approvals',
            description: 'Registrations pending approval',
            color: const Color(0xFFF59E0B),
            onTap: () => _navigate(AdminRoute.registrationApprovals),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AdminBreakpoints.desktop;
          return wide ? _wideBottomRow() : _stackedBottom();
        },
      ),
    );
  }

  Widget _wideBottomRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _recentActivityCard()),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _pendingActionsCard()),
        ],
      ),
    );
  }

  Widget _stackedBottom() {
    return Column(
      children: [
        _recentActivityCard(),
        const SizedBox(height: 20),
        _pendingActionsCard(),
      ],
    );
  }

  Widget _recentActivityCard() {
    return _dashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Recent Activity',
            subtitle: 'Latest documentation requests from the database',
            actions: [
              TextButton(
                onPressed: () => _navigate(AdminRoute.docRequests),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_activity.isEmpty)
            const AdminEmptyState(
              title: AdminDataConstants.emptyRecordsTitle,
              message: AdminDataConstants.emptyRecordsMessage,
            )
          else
            AdminActivityTimeline(items: _activity),
        ],
      ),
    );
  }

  Widget _pendingActionsCard() {
    final pendingReq = _stats['pending_requests'] as num? ?? 0;
    final pendingMem = _stats['pending_members'] as num? ?? 0;

    final actions = <_PendingAction>[
      if (pendingReq > 0)
        _PendingAction(
          icon: Icons.mark_email_unread_outlined,
          label: 'Review documentation requests',
          count: pendingReq.toInt(),
          color: AdminTheme.danger,
          route: AdminRoute.docRequests,
        ),
      if (pendingMem > 0)
        _PendingAction(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Approve new members',
          count: pendingMem.toInt(),
          color: const Color(0xFF7C3AED),
          route: AdminRoute.members,
        ),
    ];

    return _dashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Pending Actions',
            subtitle: 'Items that need attention',
          ),
          const SizedBox(height: 12),
          if (actions.isEmpty)
            const AdminEmptyState(
              title: 'All caught up',
              message: 'No pending approvals in the database.',
              icon: Icons.check_circle_outline,
            )
          else
            ...actions.map((a) => _PendingActionTile(action: a, onTap: () => _navigate(a.route))),
        ],
      ),
    );
  }

  Widget _dashboardPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AdminTheme.cardDecoration(),
      child: child,
    );
  }
}

class _PendingAction {
  const _PendingAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    this.count,
  });

  final IconData icon;
  final String label;
  final Color color;
  final AdminRoute route;
  final int? count;
}

class _PendingActionTile extends StatefulWidget {
  const _PendingActionTile({required this.action, required this.onTap});
  final _PendingAction action;
  final VoidCallback onTap;

  @override
  State<_PendingActionTile> createState() => _PendingActionTileState();
}

class _PendingActionTileState extends State<_PendingActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: _hovered ? AdminTheme.contentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.action.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.action.icon, size: 20, color: widget.action.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.action.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.action.count != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.action.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.action.count}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: widget.action.color,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AdminTheme.textSecondary.withValues(alpha: _hovered ? 1 : 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
