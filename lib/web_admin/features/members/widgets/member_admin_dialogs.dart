import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/members/member_models.dart';
import 'package:access_mobile/web_admin/features/member_rankings/member_ranking_models.dart';
import 'package:access_mobile/web_admin/features/member_rankings/widgets/skill_level_badge.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class MemberAdminDialogs {
  MemberAdminDialogs._();

  static Future<void> showProfile(BuildContext context, AdminMemberRow row) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(row.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Email', row.email),
              _detailRow('Role', row.role),
              _detailRow('Status', row.status),
              Row(
                children: [
                  const Text('Skill level', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
                  const SizedBox(width: 12),
                  SkillLevelBadge(tier: row.skillTier, label: row.skillLevel),
                ],
              ),
              const SizedBox(height: 8),
              _detailRow('Assigned tasks', row.assignedLabel),
              _detailRow('Media evaluation', row.mediaScoreLabel),
              _detailRow('Task role', row.primaryTaskRole ?? '—'),
              _detailRow('Last active', formatLastActivity(row.lastActive)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  static Future<String?> pickRole(BuildContext context, String current) async {
    const roles = ['Admin', 'Member', 'Organization'];
    var selected = roles.contains(current) ? current : 'Member';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign role', style: TextStyle(fontWeight: FontWeight.w800)),
        content: DropdownButtonFormField<String>(
          initialValue: selected,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => selected = v ?? selected,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Save')),
        ],
      ),
    );
  }

  static Future<String?> pickStatus(BuildContext context, String current) async {
    const statuses = ['approved', 'pending', 'rejected'];
    var selected = statuses.contains(current) ? current : 'approved';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change status', style: TextStyle(fontWeight: FontWeight.w800)),
        content: DropdownButtonFormField<String>(
          initialValue: selected,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'approved', child: Text('Active (approved)')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'rejected', child: Text('Inactive (rejected)')),
          ],
          onChanged: (v) => selected = v ?? selected,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Update')),
        ],
      ),
    );
  }

  static Future<String?> rejectionReason(BuildContext context, AdminMemberRow row) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject ${row.name}?', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A rejection reason is required for audit records.',
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.danger),
            onPressed: () {
              final reason = ctrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx, reason);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
