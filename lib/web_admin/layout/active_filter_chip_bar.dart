import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Shows the active card/table filter with a clear action.
class ActiveFilterChipBar extends StatelessWidget {
  const ActiveFilterChipBar({
    super.key,
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AdminTheme.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminTheme.accentCyan.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_alt, size: 16, color: AdminTheme.accentBlue),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear filter'),
            style: TextButton.styleFrom(
              foregroundColor: AdminTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}
