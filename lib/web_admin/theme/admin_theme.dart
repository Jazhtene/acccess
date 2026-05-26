import 'package:flutter/material.dart';

/// Web admin visual system (gallery mockup — navy sidebar, light content).
abstract final class AdminTheme {
  static const Color sidebarBg = Color(0xFF0A1F38);
  static const Color sidebarText = Color(0xFFE2E8F0);
  static const Color sidebarMuted = Color(0xFF94A3B8);

  static const Color contentBg = Color(0xFFF1F5F9);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F2744);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color facebookBlue = Color(0xFF1877F2);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F2744).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: cardShadow,
      );

  static const LinearGradient navActiveGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const List<LinearGradient> albumGradients = [
    LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF22D3EE), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF1E3A5F), Color(0xFF0E7490)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static LinearGradient albumGradientAt(int index) =>
      albumGradients[index % albumGradients.length];

  static ThemeData materialTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: contentBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBlue,
        surface: surface,
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentCyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}
