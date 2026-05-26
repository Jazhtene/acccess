import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Reusable confirmation dialog for destructive or important actions.
class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: icon != null
            ? Icon(icon, size: 32, color: destructive ? AdminTheme.danger : AdminTheme.accentBlue)
            : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(message, style: const TextStyle(color: AdminTheme.textSecondary, height: 1.45)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: AdminTheme.danger) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
