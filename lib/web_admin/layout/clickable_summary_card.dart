import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Interactive summary card — hover, tooltip, keyboard, optional active highlight.
class ClickableSummaryCard extends StatefulWidget {
  const ClickableSummaryCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.description,
    this.color,
    this.onTap,
    this.tooltip,
    this.filterKey,
    this.activeFilterKey,
    this.compact = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final String description;
  final Color? color;
  final VoidCallback? onTap;
  final String? tooltip;
  /// Identifies this card's filter; matches [activeFilterKey] when its filter is applied.
  final String? filterKey;
  final String? activeFilterKey;
  final bool compact;

  @override
  State<ClickableSummaryCard> createState() => _ClickableSummaryCardState();
}

class _ClickableSummaryCardState extends State<ClickableSummaryCard> {
  bool _hovered = false;
  bool _focused = false;

  bool get _isActive =>
      widget.filterKey != null &&
      widget.activeFilterKey != null &&
      widget.filterKey == widget.activeFilterKey;

  bool get _interactive => widget.onTap != null;

  void _activate() {
    if (widget.onTap != null) widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AdminTheme.accentCyan;
    final tooltip = widget.tooltip ?? widget.description;

    Widget card = AnimatedScale(
      scale: _interactive && _hovered ? 1.015 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(widget.compact ? 12 : 18),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isActive
              ? AdminTheme.accentCyan
              : (_interactive && (_hovered || _focused)
                  ? AdminTheme.accentCyan.withValues(alpha: 0.55)
                  : AdminTheme.border),
          width: _isActive ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2744).withValues(alpha: _hovered || _isActive ? 0.10 : 0.06),
            blurRadius: _hovered || _isActive ? 20 : 16,
            offset: Offset(0, _hovered ? 6 : 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: widget.compact ? 40 : 48,
            height: widget.compact ? 40 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, AdminTheme.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
            ),
            child: Icon(widget.icon, color: Colors.white, size: widget.compact ? 20 : 24),
          ),
          SizedBox(width: widget.compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.compact ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                if (!widget.compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdminTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                if (_interactive && !widget.compact) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Click to filter or view',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.accentCyan.withValues(alpha: _hovered ? 1 : 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_interactive)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AdminTheme.textSecondary.withValues(alpha: _hovered ? 0.9 : 0.45),
            ),
        ],
      ),
    ),
    );

    if (!_interactive) return card;

    card = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: card,
    );

    card = FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): _ActivateIntent()},
      actions: {
        _ActivateIntent: CallbackAction<_ActivateIntent>(onInvoke: (_) {
          _activate();
          return null;
        }),
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _activate,
          borderRadius: BorderRadius.circular(14),
          splashColor: AdminTheme.accentCyan.withValues(alpha: 0.08),
          child: card,
        ),
      ),
    );

    return Tooltip(message: tooltip, waitDuration: const Duration(milliseconds: 400), child: card);
  }
}

class _ActivateIntent extends Intent {
  const _ActivateIntent();
}

class SummaryCardGrid extends StatelessWidget {
  const SummaryCardGrid({super.key, required this.children, this.compact = false});

  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cross = AdminBreakpoints.summaryGridColumns(c.maxWidth);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cross,
          crossAxisSpacing: compact ? 12 : 16,
          mainAxisSpacing: compact ? 12 : 16,
          childAspectRatio: compact
              ? (cross == 1 ? 3.4 : 3.8)
              : (cross == 1 ? 2.6 : 2.35),
          children: children,
        );
      },
    );
  }
}

/// Backward-compatible alias.
typedef SummaryCard = ClickableSummaryCard;
