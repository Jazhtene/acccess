import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class RankingSummaryCard extends StatefulWidget {
  const RankingSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.description,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final String description;
  final Color? color;

  @override
  State<RankingSummaryCard> createState() => _RankingSummaryCardState();
}

class _RankingSummaryCardState extends State<RankingSummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AdminTheme.accentCyan;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AdminTheme.cardDecoration().copyWith(
            border: Border.all(
              color: _hovered ? accent.withValues(alpha: 0.35) : AdminTheme.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, AdminTheme.accentBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Text(
                widget.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
