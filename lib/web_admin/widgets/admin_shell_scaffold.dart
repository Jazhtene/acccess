import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';
import 'package:access_mobile/shared/widgets/access_branding.dart';

class AdminShellScaffold extends StatelessWidget {
  const AdminShellScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminTheme.contentBg,
      child: Padding(
        padding: AdminBreakpoints.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final compact = c.maxWidth < AdminBreakpoints.tablet;
                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 22 : 28,
                        fontWeight: FontWeight.w800,
                        color: AdminTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13, height: 1.4),
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const AccessBrandMark.iconOnly(logoSize: 36),
                          const SizedBox(width: 12),
                          Expanded(child: titleBlock),
                        ],
                      ),
                      if (actions != null && actions!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: actions!),
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 14),
                      child: AccessBrandMark.iconOnly(logoSize: 42),
                    ),
                    Expanded(child: titleBlock),
                    if (actions != null) Wrap(spacing: 8, runSpacing: 8, children: actions!),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
