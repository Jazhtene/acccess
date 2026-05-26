import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/members/member_models.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Confirmation before soft-removing a member account.
class RemoveMemberDialog {
  RemoveMemberDialog._();

  static Future<bool?> show(BuildContext context, AdminMemberRow row) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.person_remove_outlined, size: 32, color: AdminTheme.danger),
        title: const Text('Remove Member', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to remove this member? '
                'This will disable the member\'s access to the system.',
                style: TextStyle(color: AdminTheme.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 16),
              _detailRow('Full Name', row.name),
              _detailRow('Email', row.email),
              if (row.studentId != null && row.studentId!.trim().isNotEmpty)
                _detailRow('Student ID', row.studentId!),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Remove'),
          ),
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
            width: 88,
            child: Text(label, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

String formatRemovedDate(DateTime? dt) {
  if (dt == null) return '—';
  final local = dt.toLocal();
  final y = local.year;
  final mo = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final mi = local.minute.toString().padLeft(2, '0');
  return '$y-$mo-$d $h:$mi';
}
