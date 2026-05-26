import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Breadcrumb trail — e.g. Dashboard / Media Management / Media Evaluation
class Breadcrumbs extends StatelessWidget {
  const Breadcrumbs({super.key, required this.segments});

  final List<String> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.chevron_right, size: 14, color: AdminTheme.textSecondary),
            ),
          Text(
            segments[i],
            style: TextStyle(
              fontSize: 12,
              fontWeight: i == segments.length - 1 ? FontWeight.w700 : FontWeight.w500,
              color: i == segments.length - 1 ? AdminTheme.accentBlue : AdminTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
