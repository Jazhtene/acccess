import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      if (action != null)
        GestureDetector(onTap: onAction,
          child: Text(action!, style: const TextStyle(color: kCyan, fontSize: 9, letterSpacing: 0.8))),
    ],
  );
}

class StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const StatusDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 6, height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(color: color, fontSize: 10,
      fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  ]);
}

class TextBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const TextBtn(this.label, {super.key, this.color = kCyan, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class MetricChip extends StatelessWidget {
  final String label, value;
  const MetricChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final bool highlight;
  final VoidCallback? onTap;
  const ActionTile({super.key, required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, this.highlight = false, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? kCyanDim : kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: highlight ? kCyan.withOpacity(0.5) : kBorder)),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: highlight ? kCyan : kTextPrimary,
            fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        ])),
        Icon(Icons.chevron_right, color: highlight ? kCyan : kTextSecondary, size: 18),
      ]),
    ),
  );
}
