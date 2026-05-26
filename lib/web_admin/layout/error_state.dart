import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/layout/alert_banner.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Clean error display with optional retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Unable to load data',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AlertBanner.error(message),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminTheme.border),
          ),
          child: Column(
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: AdminTheme.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
