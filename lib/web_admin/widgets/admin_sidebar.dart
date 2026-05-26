import 'package:flutter/material.dart';
import 'package:access_mobile/shared/controllers/auth_controller.dart';
import 'package:access_mobile/shared/models/user_model.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/config/admin_permissions.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';
import 'package:access_mobile/shared/widgets/access_branding.dart';

/// Dark navy sidebar with collapsible groups and profile footer.
class AdminSidebar extends StatefulWidget {
  const AdminSidebar({
    super.key,
    required this.user,
    required this.selectedRoute,
    required this.onRouteSelected,
    this.compact = false,
    this.onCloseDrawer,
    this.showCollapseToggle = false,
    this.sidebarCollapsed = false,
    this.onToggleCollapse,
  });

  final AuthUser user;
  final AdminRoute selectedRoute;
  final ValueChanged<AdminRoute> onRouteSelected;
  final bool compact;
  final VoidCallback? onCloseDrawer;
  final bool showCollapseToggle;
  final bool sidebarCollapsed;
  final VoidCallback? onToggleCollapse;

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  late final Map<String, bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = {for (final g in adminNavGroups) g.id: g.initiallyExpanded};
    _ensureActiveGroupExpanded();
  }

  @override
  void didUpdateWidget(AdminSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoute != widget.selectedRoute) {
      _ensureActiveGroupExpanded();
    }
  }

  void _ensureActiveGroupExpanded() {
    final group = groupContainingRoute(widget.selectedRoute);
    if (group != null) _expanded[group.id] = true;
  }

  void _select(AdminRoute route) {
    widget.onRouteSelected(route);
    widget.onCloseDrawer?.call();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will return to the login screen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) authController.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminTheme.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            compact: widget.compact,
            showCollapseToggle: widget.showCollapseToggle,
            sidebarCollapsed: widget.sidebarCollapsed,
            onToggleCollapse: widget.onToggleCollapse,
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: widget.compact ? 6 : 10),
                children: [
                  _NavTile(
                    icon: dashboardNavLeaf.icon,
                    label: dashboardNavLeaf.label,
                    selected: widget.selectedRoute == AdminRoute.dashboard,
                    onTap: () => _select(AdminRoute.dashboard),
                    compact: widget.compact,
                  ),
                  if (!widget.compact) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'MODULES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AdminTheme.sidebarMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 8),
                  ...adminNavGroups.map(_buildGroup),
                ],
              ),
            ),
          ),
          _UserFooter(user: widget.user, compact: widget.compact, onLogout: _confirmLogout),
        ],
      ),
    );
  }

  Widget _buildGroup(AdminNavGroup group) {
    final expanded = _expanded[group.id] ?? false;
    final hasActive = group.children.any((c) => c.route == widget.selectedRoute);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupHeader(
            group: group,
            expanded: expanded,
            hasActive: hasActive,
            compact: widget.compact,
            onTap: () => setState(() => _expanded[group.id] = !expanded),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: group.children.map((leaf) {
                final selected = widget.selectedRoute == leaf.route;
                if (leaf.card) {
                  return _NavCard(
                    icon: leaf.icon,
                    label: leaf.label,
                    subtitle: leaf.subtitle ?? '',
                    selected: selected,
                    onTap: () => _select(leaf.route),
                    compact: widget.compact,
                  );
                }
                return _NavTile(
                  icon: leaf.icon,
                  label: leaf.label,
                  selected: selected,
                  onTap: () => _select(leaf.route),
                  indent: widget.compact ? 0 : 6,
                  compact: widget.compact,
                );
              }).toList(),
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.compact,
    this.showCollapseToggle = false,
    this.sidebarCollapsed = false,
    this.onToggleCollapse,
  });

  final bool compact;
  final bool showCollapseToggle;
  final bool sidebarCollapsed;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 18, compact ? 16 : 22, compact ? 8 : 18, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: compact
                ? const Center(child: AccessBrandMark.iconOnly(logoSize: 40))
                : const AccessBrandMark(
                    logoSize: 52,
                    theme: AccessBrandTheme.dark,
                    showTagline: true,
                  ),
          ),
          if (showCollapseToggle && onToggleCollapse != null)
            IconButton(
              onPressed: onToggleCollapse,
              icon: Icon(sidebarCollapsed ? Icons.chevron_right : Icons.chevron_left, color: AdminTheme.sidebarMuted),
              tooltip: sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
              style: IconButton.styleFrom(
                hoverColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatefulWidget {
  const _GroupHeader({
    required this.group,
    required this.expanded,
    required this.hasActive,
    required this.compact,
    required this.onTap,
  });

  final AdminNavGroup group;
  final bool expanded;
  final bool hasActive;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<_GroupHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12, vertical: 10),
            child: widget.compact
                ? Tooltip(
                    message: widget.group.label,
                    child: Icon(
                      widget.group.icon,
                      size: 20,
                      color: widget.hasActive ? AdminTheme.accentCyan : AdminTheme.sidebarMuted,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        widget.group.icon,
                        size: 18,
                        color: widget.hasActive ? AdminTheme.accentCyan : AdminTheme.sidebarMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.group.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: widget.hasActive ? AdminTheme.sidebarText : AdminTheme.sidebarMuted,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: widget.expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down, size: 18, color: AdminTheme.sidebarMuted),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.indent = 0,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double indent;
  final bool compact;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: widget.indent, bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
            hoverColor: Colors.white.withValues(alpha: 0.06),
            child: Ink(
              decoration: widget.selected
                  ? const BoxDecoration(
                      gradient: AdminTheme.navActiveGradient,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x3306B6D4),
                          blurRadius: 12,
                          offset: Offset(-2, 2),
                        ),
                      ],
                    )
                  : _hovered
                      ? BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                        )
                      : null,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 10 : 14,
                vertical: widget.compact ? 10 : 11,
              ),
              child: widget.compact
                  ? Tooltip(
                      message: widget.label,
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: widget.selected ? Colors.white : AdminTheme.sidebarMuted,
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          widget.icon,
                          size: 20,
                          color: widget.selected ? Colors.white : AdminTheme.sidebarMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                              color: widget.selected ? Colors.white : AdminTheme.sidebarText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Prominent gradient tile used for merged hero entries inside a sidebar
/// group (e.g. Documentation Requests). The card is permanently styled with
/// the blue cyan→blue navActiveGradient so it stands out from regular tiles;
/// the `selected` state only adds a subtle ring + shadow.
class _NavCard extends StatefulWidget {
  const _NavCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_NavCard> createState() => _NavCardState();
}

class _NavCardState extends State<_NavCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final showSubtitle = !widget.compact && widget.subtitle.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 0 : 6,
        4,
        widget.compact ? 0 : 4,
        6,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                gradient: AdminTheme.navActiveGradient,
                borderRadius: radius,
                border: widget.selected
                    ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5)
                    : Border.all(color: Colors.white.withValues(alpha: 0.10)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: widget.selected || _hovered ? 0.40 : 0.22),
                    blurRadius: widget.selected ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 10 : 14,
                vertical: widget.compact ? 10 : 12,
              ),
              child: widget.compact
                  ? Tooltip(
                      message: widget.subtitle.isEmpty
                          ? widget.label
                          : '${widget.label}\n${widget.subtitle}',
                      child: Icon(widget.icon, size: 22, color: Colors.white),
                    )
                  : Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(widget.icon, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.1,
                                  height: 1.15,
                                ),
                              ),
                              if (showSubtitle) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({
    required this.user,
    required this.compact,
    required this.onLogout,
  });

  final AuthUser user;
  final bool compact;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AdminTheme.accentCyan.withValues(alpha: 0.2),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
              style: const TextStyle(color: AdminTheme.accentCyan, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.role.displayLabel,
                    style: const TextStyle(color: AdminTheme.sidebarMuted, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20, color: AdminTheme.sidebarMuted),
            tooltip: 'Sign out',
            onPressed: onLogout,
            style: IconButton.styleFrom(
              hoverColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}
