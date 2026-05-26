import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/members/member_models.dart';
import 'package:access_mobile/web_admin/features/members/widgets/remove_member_dialog.dart';
import 'package:access_mobile/web_admin/features/member_rankings/member_ranking_models.dart';
import 'package:access_mobile/web_admin/features/member_rankings/widgets/skill_level_badge.dart';
import 'package:access_mobile/web_admin/features/member_rankings/widgets/ranking_progress_bar.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/data_table_card.dart';
import 'package:access_mobile/web_admin/layout/status_badge.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

typedef MemberRowAction = void Function(AdminMemberRow row, MemberActionType type);

enum MemberActionType {
  viewProfile,
  assignRole,
  assignTask,
  changeStatus,
  approve,
  reject,
  disable,
  remove,
}

class MembersTable extends StatelessWidget {
  const MembersTable({
    super.key,
    required this.rows,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onAction,
    this.showRemovedColumns = false,
    this.currentAdminId,
  });

  final List<AdminMemberRow> rows;
  final MemberSortColumn sortColumn;
  final bool sortAscending;
  final void Function(MemberSortColumn) onSort;
  final MemberRowAction onAction;
  final bool showRemovedColumns;
  final int? currentAdminId;

  @override
  Widget build(BuildContext context) {
    return DataTableCard(
      title: showRemovedColumns ? 'Removed members' : 'Member directory',
      shownCount: rows.length,
      totalCount: rows.length,
      emptyTitle: 'No records found',
      emptyMessage: showRemovedColumns
          ? 'No removed members yet.'
          : 'No records found yet.',
      emptyIcon: Icons.people_outline,
      child: AdminDataTableTheme(
        child: ResponsiveTableScroll(
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 72,
            columns: showRemovedColumns ? _removedColumns() : _activeColumns(),
            rows: rows.map((r) => showRemovedColumns ? _removedRow(r) : _activeRow(r)).toList(),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _activeColumns() => [
        _sortable('Member Name', MemberSortColumn.name),
        const DataColumn(label: Text('Email')),
        const DataColumn(label: Text('Role')),
        _sortable('Status', MemberSortColumn.status),
        _sortable('Skill Level', MemberSortColumn.skillLevel),
        const DataColumn(label: Text('Assigned Tasks')),
        _sortable('Media Score', MemberSortColumn.mediaScore),
        _sortable('Last Active', MemberSortColumn.lastActive),
        const DataColumn(label: Text('Actions')),
      ];

  List<DataColumn> _removedColumns() => [
        _sortable('Member Name', MemberSortColumn.name),
        const DataColumn(label: Text('Email')),
        const DataColumn(label: Text('Student ID')),
        const DataColumn(label: Text('Removed Date')),
        const DataColumn(label: Text('Removed By')),
        const DataColumn(label: Text('Status')),
        const DataColumn(label: Text('Actions')),
      ];

  DataColumn _sortable(String label, MemberSortColumn col) {
    return DataColumn(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      onSort: (_, __) => onSort(col),
    );
  }

  DataRow _activeRow(AdminMemberRow r) {
    return DataRow(
      cells: [
        _nameCell(r),
        DataCell(Text(r.email, style: const TextStyle(fontSize: 12))),
        DataCell(Text(r.role, style: const TextStyle(fontSize: 12))),
        DataCell(_statusBadge(r)),
        DataCell(SkillLevelBadge(tier: r.skillTier, label: r.skillLevel)),
        DataCell(Text(r.assignedLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        DataCell(
          SizedBox(
            width: 100,
            child: RankingProgressBar(
              value: r.mediaEvalScore.round(),
              max: 100,
              label: 'Media evaluation quality',
              color: AdminTheme.accentCyan,
            ),
          ),
        ),
        DataCell(Text(formatLastActivity(r.lastActive), style: const TextStyle(fontSize: 11))),
        DataCell(_actionsCell(r)),
      ],
    );
  }

  DataRow _removedRow(AdminMemberRow r) {
    return DataRow(
      cells: [
        _nameCell(r),
        DataCell(Text(r.email, style: const TextStyle(fontSize: 12))),
        DataCell(Text(r.studentId ?? '—', style: const TextStyle(fontSize: 12))),
        DataCell(Text(formatRemovedDate(r.removedAt), style: const TextStyle(fontSize: 11))),
        DataCell(Text(r.removedByName ?? '—', style: const TextStyle(fontSize: 12))),
        DataCell(_statusBadge(r)),
        DataCell(_actionsCell(r, showRemove: false)),
      ],
    );
  }

  DataCell _nameCell(AdminMemberRow r) {
    return DataCell(
      Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AdminTheme.accentBlue.withValues(alpha: 0.12),
            child: Text(
              r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AdminTheme.accentBlue,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              r.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(AdminMemberRow r) {
    if (r.isRemoved) return StatusBadge.inactive('Removed');
    if (r.isActive) return StatusBadge.active();
    if (r.isPending) return StatusBadge.pending('Pending');
    return StatusBadge.inactive(r.status == 'rejected' ? 'Rejected' : 'Inactive');
  }

  Widget _actionsCell(AdminMemberRow r, {bool showRemove = true}) {
    final canRemove = showRemove &&
        r.isMemberRole &&
        !r.isRemoved &&
        currentAdminId != null &&
        r.id != currentAdminId;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canRemove)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.danger,
                side: const BorderSide(color: AdminTheme.danger),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => onAction(r, MemberActionType.remove),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Remove', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        PopupMenuButton<MemberActionType>(
          tooltip: 'More actions',
          icon: const Icon(Icons.more_horiz, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onSelected: (a) => onAction(r, a),
          itemBuilder: (_) => [
            const PopupMenuItem(value: MemberActionType.viewProfile, child: Text('View Profile')),
            if (!r.isRemoved) ...[
              const PopupMenuItem(value: MemberActionType.assignRole, child: Text('Assign Role')),
              const PopupMenuItem(value: MemberActionType.assignTask, child: Text('Assign Task')),
              const PopupMenuItem(value: MemberActionType.changeStatus, child: Text('Change Status')),
            ],
            if (r.isPending) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(value: MemberActionType.approve, child: Text('Approve')),
              const PopupMenuItem(value: MemberActionType.reject, child: Text('Reject')),
            ],
            if (!r.isInactive && !r.isRemoved) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: MemberActionType.disable,
                child: Text('Disable Account', style: TextStyle(color: AdminTheme.danger)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
