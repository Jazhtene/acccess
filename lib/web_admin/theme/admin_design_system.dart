import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Global ACCESS VisionCheck admin design tokens.
abstract final class AdminDesignSystem {
  // Spacing
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;

  // Radius
  static const double radiusSm = 8;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusPill = 20;

  // Typography
  static const TextStyle pageTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AdminTheme.textPrimary,
    letterSpacing: -0.5,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AdminTheme.textPrimary,
  );
  static const TextStyle body = TextStyle(fontSize: 13, color: AdminTheme.textSecondary, height: 1.45);
  static const TextStyle caption = TextStyle(fontSize: 11, color: AdminTheme.textSecondary, fontWeight: FontWeight.w500);

  // Buttons
  static ButtonStyle get primaryButton => FilledButton.styleFrom(
        backgroundColor: AdminTheme.accentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      );

  static ButtonStyle get outlineButton => OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      );

  // Table
  static const Color tableHeaderBg = Color(0xFFF8FAFC);
  static const Color tableRowHover = Color(0xFFF8FAFC);

  // Focus ring for accessibility
  static BoxDecoration focusRing(Color color) => BoxDecoration(
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: color, width: 2),
      );
}
