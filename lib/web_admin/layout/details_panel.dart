import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Standard admin details dialog shell with header and scrollable body.
class DetailsPanel {
  DetailsPanel._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
    List<Widget>? actions,
    double maxWidth = 560,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AdminBreakpoints.dialogMaxWidth(ctx, desktopMax: maxWidth),
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AdminTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
              if (actions != null && actions.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget detailRow(String label, String value, {Widget? trailing}) {
    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 480;
        if (stacked) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary)),
                if (trailing != null) ...[const SizedBox(height: 6), trailing],
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        );
      },
    );
  }
}
