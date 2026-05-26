import 'package:flutter/material.dart';
import 'package:access_mobile/shared/controllers/branding_controller.dart';
import 'package:access_mobile/shared/widgets/access_logo.dart';

/// Branded loading state with official ACCESS logo (web admin + shared).
class AccessBrandedLoading extends StatelessWidget {
  const AccessBrandedLoading({
    super.key,
    this.message = 'Loading…',
    this.logoSize = 72,
    this.backgroundColor,
    this.textColor,
  });

  final String message;
  final double logoSize;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AccessLogoImage(size: logoSize),
            const SizedBox(height: 20),
            Text(
              brandingController.appName,
              style: TextStyle(
                color: textColor ?? const Color(0xFF0F2744),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: textColor?.withValues(alpha: 0.7) ?? const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
