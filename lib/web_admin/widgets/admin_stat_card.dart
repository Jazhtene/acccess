import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class AdminStatCard extends StatefulWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.description,
    this.trend,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? description;
  final String? trend;
  final VoidCallback? onTap;

  @override
  State<AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<AdminStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -2.0 : 0, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: AdminTheme.cardDecoration().copyWith(
                border: Border.all(
                  color: _hovered ? widget.color.withValues(alpha: 0.35) : AdminTheme.border,
                ),
                boxShadow: _hovered
                    ? [
                        ...AdminTheme.cardShadow,
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : AdminTheme.cardShadow,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 22),
                      ),
                      const Spacer(),
                      if (widget.trend != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AdminTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.trend!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AdminTheme.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: widget.color,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
