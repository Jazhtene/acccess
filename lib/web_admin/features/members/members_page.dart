import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/features/members/member_models.dart';
import 'package:access_mobile/web_admin/features/members/widgets/member_admin_dialogs.dart';
import 'package:access_mobile/web_admin/features/members/widgets/members_table.dart';
import 'package:access_mobile/web_admin/layout/admin_feature_page.dart';
import 'package:access_mobile/web_admin/layout/admin_route_breadcrumbs.dart';
import 'package:access_mobile/web_admin/layout/admin_session_scope.dart';
import 'package:access_mobile/web_admin/layout/confirm_dialog.dart';
import 'package:access_mobile/web_admin/layout/page_header.dart';
import 'package:access_mobile/web_admin/features/members/widgets/remove_member_dialog.dart';
import 'package:access_mobile/web_admin/navigation/admin_navigation_scope.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List<AdminMemberRow> _rows = [];
  bool _loading = true;
  String? _error;

  MemberListFilter _chipFilter = MemberListFilter.activeMembers;
  bool _removing = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  MemberSortColumn _sortCol = MemberSortColumn.name;
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyRouteIntent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyRouteIntent() {
    final params = AdminNavigationScope.consumeParams(context, AdminRoute.members);
    if (params == null) return;
    final status = params['statusFilter'] as String?;
    if (status == 'pending') {
      setState(() => _chipFilter = MemberListFilter.pending);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // PostgreSQL users via GET /api/users
      final list = await adminApi.allUsers();
      final rows = list.map(AdminMemberRow.fromMap).toList();
      if (mounted) {
        setState(() {
          _rows = rows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rows = [];
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<AdminMemberRow> get _filtered {
    var list = _rows.where((r) {
      if (_search.isNotEmpty) {
        final q = _search;
        final hit = r.name.toLowerCase().contains(q) ||
            r.email.toLowerCase().contains(q) ||
            r.role.toLowerCase().contains(q) ||
            r.status.contains(q);
        if (!hit) return false;
      }
      if (_chipFilter != MemberListFilter.all && !r.matchesFilter(_chipFilter)) return false;
      return true;
    }).toList();
    return sortMembers(list, _sortCol, _sortAsc);
  }

  void _toast(String msg, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AdminTheme.success : AdminTheme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _setStatus(AdminMemberRow row, String status, {String? rejectionReason}) async {
    try {
      await adminApi.setUserStatus(row.id, status, rejectionReason: rejectionReason);
      await _load();
      _toast('Member status updated to $status');
    } catch (e) {
      _toast(e.toString(), success: false);
    }
  }

  Future<void> _removeMember(AdminMemberRow row) async {
    final admin = AdminSessionScope.maybeOf(context);
    if (admin != null && row.id == admin.id) {
      _toast('You cannot remove your own admin account.', success: false);
      return;
    }
    if (!row.isMemberRole) {
      _toast('Only Member accounts can be removed here.', success: false);
      return;
    }

    final ok = await RemoveMemberDialog.show(context, row);
    if (ok != true) return;

    setState(() => _removing = true);
    try {
      await adminApi.removeMember(row.id);
      await _load();
      _toast('Member removed successfully.');
    } catch (e) {
      _toast(e.toString(), success: false);
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  Future<void> _setRole(AdminMemberRow row, String role) async {
    try {
      await adminApi.setUserRole(row.id, role);
      await _load();
      _toast('Role set to $role');
    } catch (e) {
      _toast(e.toString(), success: false);
    }
  }

  Future<void> _handleAction(AdminMemberRow row, MemberActionType type) async {
    if (type == MemberActionType.viewProfile) {
      await MemberAdminDialogs.showProfile(context, row);
      return;
    }

    if (type == MemberActionType.assignRole) {
      final role = await MemberAdminDialogs.pickRole(context, row.role);
      if (!mounted) return;
      if (role != null) await _setRole(row, role);
      return;
    }

    if (type == MemberActionType.assignTask) {
      if (!mounted) return;
      AdminNavigationScope.go(context, AdminRoute.taskAssignments);
      _toast('Open Task Assignments to assign coverage roles');
      return;
    }

    if (type == MemberActionType.changeStatus) {
      final st = await MemberAdminDialogs.pickStatus(context, row.status);
      if (!mounted) return;
      if (st == null) return;
      if (st == 'rejected') {
        final reason = await MemberAdminDialogs.rejectionReason(context, row);
        if (!mounted) return;
        if (reason == null) return;
        await _setStatus(row, st, rejectionReason: reason);
      } else {
        await _setStatus(row, st);
      }
      return;
    }

    if (type == MemberActionType.approve) {
      final ok = await ConfirmDialog.show(
        context,
        title: 'Approve member?',
        message: 'Grant ${row.name} access to ACCESS Sync.',
        confirmLabel: 'Approve',
        icon: Icons.check_circle_outline,
      );
      if (!mounted) return;
      if (ok == true) await _setStatus(row, 'approved');
      return;
    }

    if (type == MemberActionType.reject) {
      final reason = await MemberAdminDialogs.rejectionReason(context, row);
      if (!mounted) return;
      if (reason != null) await _setStatus(row, 'rejected', rejectionReason: reason);
      return;
    }

    if (type == MemberActionType.disable) {
      final ok = await ConfirmDialog.show(
        context,
        title: 'Disable account?',
        message: 'This will reject ${row.name}\'s access until re-approved.',
        confirmLabel: 'Disable',
        destructive: true,
        icon: Icons.block,
      );
      if (!mounted) return;
      if (ok == true) await _setStatus(row, 'rejected');
      return;
    }

    if (type == MemberActionType.remove) {
      await _removeMember(row);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return AdminFeaturePage(
      title: 'Members',
      subtitle:
          'Manage ACCESS members, approve registrations, assign roles, and track media evaluation performance.',
      breadcrumbs: breadcrumbsForRoute(AdminRoute.members),
      loading: _loading || _removing,
      error: _error,
      onRetry: _load,
      actions: [
        PageHeaderIconButton(icon: Icons.refresh, onPressed: _load, tooltip: 'Refresh'),
      ],
      filter: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AdminTheme.cardDecoration(),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by name, email, role, or status…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MemberListFilter.values.map((f) {
                final selected = _chipFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(memberFilterLabel(f), style: const TextStyle(fontSize: 11)),
                    selected: selected,
                    onSelected: (_) => setState(() => _chipFilter = f),
                    selectedColor: AdminTheme.accentCyan.withValues(alpha: 0.18),
                    checkmarkColor: AdminTheme.accentBlue,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: MembersTable(
        rows: filtered,
        sortColumn: _sortCol,
        sortAscending: _sortAsc,
        showRemovedColumns: _chipFilter == MemberListFilter.removed,
        currentAdminId: AdminSessionScope.maybeOf(context)?.id,
        onSort: (col) => setState(() {
          if (_sortCol == col) {
            _sortAsc = !_sortAsc;
          } else {
            _sortCol = col;
            _sortAsc = true;
          }
        }),
        onAction: _handleAction,
      ),
    );
  }
}
