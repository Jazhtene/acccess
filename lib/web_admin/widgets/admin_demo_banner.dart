import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/config/admin_ui_config.dart';

/// Shown only in debug when UI is using sample/demo data.
class AdminDemoBanner extends StatelessWidget {
  const AdminDemoBanner({
    super.key,
    this.message = 'Preview mode — showing sample data until live API data is available.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    if (!AdminUiConfig.showDemoData) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
            ),
          ),
        ],
      ),
    );
  }
}
