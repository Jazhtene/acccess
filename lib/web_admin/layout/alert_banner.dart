import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/config/admin_ui_config.dart';

enum AlertBannerType { info, warning, error, sample, success }

/// Shown only when there is something the admin should know.
class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.message,
    this.type = AlertBannerType.info,
    this.onDismiss,
  });

  final String message;
  final AlertBannerType type;
  final VoidCallback? onDismiss;

  /// Preview / sample data — hidden in release builds.
  factory AlertBanner.sample(String message) {
    return AlertBanner(message: message, type: AlertBannerType.sample);
  }

  factory AlertBanner.error(String message, {VoidCallback? onRetry}) {
    return AlertBanner(message: message, type: AlertBannerType.error);
  }

  @override
  Widget build(BuildContext context) {
    if (type == AlertBannerType.sample && !AdminUiConfig.showDemoData) {
      return const SizedBox.shrink();
    }

    final (bg, border, fg, icon) = switch (type) {
      AlertBannerType.error => (
          const Color(0xFFFEF2F2),
          const Color(0xFFFECACA),
          const Color(0xFFB91C1C),
          Icons.error_outline,
        ),
      AlertBannerType.warning => (
          const Color(0xFFFEF3C7),
          const Color(0xFFFDE68A),
          const Color(0xFFB45309),
          Icons.warning_amber_outlined,
        ),
      AlertBannerType.success => (
          const Color(0xFFF0FDF4),
          const Color(0xFFBBF7D0),
          const Color(0xFF15803D),
          Icons.check_circle_outline,
        ),
      AlertBannerType.sample => (
          const Color(0xFFFEF3C7),
          const Color(0xFFFDE68A),
          const Color(0xFFB45309),
          Icons.science_outlined,
        ),
      AlertBannerType.info => (
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
          const Color(0xFF1D4ED8),
          Icons.info_outline,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg, height: 1.35),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, size: 18, color: fg),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}
