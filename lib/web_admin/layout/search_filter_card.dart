import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// White card wrapper for search + filter controls.
class SearchFilterCard extends StatelessWidget {
  const SearchFilterCard({
    super.key,
    required this.child,
    this.footerHint,
  });

  final Widget child;
  final String? footerHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AdminTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          if (footerHint != null) ...[
            const SizedBox(height: 10),
            Text(footerHint!, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
          ],
        ],
      ),
    );
  }
}
