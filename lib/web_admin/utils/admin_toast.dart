import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Deployment-ready snackbar toasts for admin actions.
abstract final class AdminToast {
  static void show(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AdminTheme.danger : AdminTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  static void created(BuildContext context, [String what = 'Record']) =>
      show(context, '$what created successfully');

  static void updated(BuildContext context, [String what = 'Record']) =>
      show(context, '$what updated successfully');

  static void deleted(BuildContext context, [String what = 'Record']) =>
      show(context, '$what deleted successfully');

  static void exportCompleted(BuildContext context) =>
      show(context, 'Export completed — report copied to clipboard');

  static void loadFailed(BuildContext context) =>
      show(context, 'Failed to load data. Please try again.', isError: true);

  static void connectionError(BuildContext context) =>
      show(context, 'Connection error. Check the server and try again.', isError: true);
}
