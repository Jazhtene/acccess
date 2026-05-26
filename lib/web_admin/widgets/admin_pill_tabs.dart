import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class AdminPillTabs extends StatelessWidget {
  const AdminPillTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: labels.map((label) {
        final active = label == selected;
        return Material(
          color: active ? AdminTheme.accentBlue : AdminTheme.surface,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => onSelected(label),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: active ? null : Border.all(color: AdminTheme.border),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AdminTheme.accentBlue.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AdminTheme.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
