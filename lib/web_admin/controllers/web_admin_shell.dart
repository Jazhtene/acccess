import 'dart:async';

import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/shared/models/user_model.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/navigation/admin_navigation_scope.dart';
import 'package:access_mobile/web_admin/navigation/admin_page_router.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';
import 'package:access_mobile/web_admin/data/admin_notification_helpers.dart';
import 'package:access_mobile/web_admin/layout/admin_session_scope.dart';
import 'package:access_mobile/web_admin/layout/notification_center.dart';
import 'package:access_mobile/web_admin/features/notifications/notification_models.dart';
import 'package:access_mobile/web_admin/widgets/admin_sidebar.dart';
import 'package:access_mobile/web_admin/widgets/admin_top_bar.dart';
import 'package:access_mobile/web_admin/widgets/backend_offline_banner.dart';
import 'package:access_mobile/web_admin/widgets/profile_dropdown.dart';
import 'package:access_mobile/shared/widgets/access_branding.dart';

/// Web admin layout: responsive sidebar + top bar + main content.
class WebAdminShell extends StatefulWidget {
  const WebAdminShell({super.key, required this.user});

  final AuthUser user;

  @override
  State<WebAdminShell> createState() => _WebAdminShellState();
}

class _WebAdminShellState extends State<WebAdminShell> {
  AdminRoute _route = AdminRoute.dashboard;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _notificationCount = 0;
  List<AdminNotificationItem> _notifications = [];
  bool _notificationsLoading = false;
  DateTime? _lastRefreshed;
  bool _refreshing = false;
  Timer? _notificationPoll;
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _lastRefreshed = DateTime.now();
    _loadNotifications();
    _notificationPoll = Timer.periodic(const Duration(seconds: 30), (_) => _loadNotifications(silent: true));
  }

  @override
  void dispose() {
    _notificationPoll?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) setState(() => _notificationsLoading = true);
    try {
      final list = await adminApi.myNotifications();
      final items = notificationsFromApi(list);
      final unread = items.where((n) => n.unread).length;
      if (mounted) {
        setState(() {
          _notifications = items;
          _notificationCount = unread;
          _notificationsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _notificationCount = _notifications.where((n) => n.unread).length;
          _notificationsLoading = false;
        });
      }
    }
  }

  Future<void> _openNotificationCenter() async {
    await NotificationCenterPanel.show(
      context,
      notifications: _notifications,
      loading: _notificationsLoading,
      onRefresh: () => _loadNotifications(),
      onMarkAllRead: () async {
        try {
          await adminApi.markAllNotificationsRead();
        } catch (_) {}
        await _loadNotifications();
      },
      onClearRead: () async {
        try {
          await adminApi.clearReadNotifications();
        } catch (_) {}
        await _loadNotifications();
      },
      onMarkRead: (id) async {
        if (id <= 0) return;
        try {
          await adminApi.markNotificationRead(id);
        } catch (_) {}
        await _loadNotifications(silent: true);
      },
    );
  }

  AdminRoute? _intentRoute;
  Map<String, dynamic>? _intentParams;

  void _onRouteSelected(AdminRoute route, {Map<String, dynamic>? params}) {
    setState(() {
      _route = route;
      _intentRoute = params != null && params.isNotEmpty ? route : null;
      _intentParams = params;
    });
  }

  Map<String, dynamic>? _takeParams(AdminRoute route) {
    if (_intentRoute == route && _intentParams != null) {
      final p = Map<String, dynamic>.from(_intentParams!);
      _intentRoute = null;
      _intentParams = null;
      return p;
    }
    return null;
  }

  Future<void> _refreshCurrentView() async {
    setState(() => _refreshing = true);
    await _loadNotifications();
    if (mounted) {
      setState(() {
        _refreshing = false;
        _lastRefreshed = DateTime.now();
      });
    }
  }

  void _toggleSidebarCollapsed() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final width = AdminBreakpoints.widthOf(context);
    final useDrawer = AdminBreakpoints.useDrawer(context);
    final isTablet = AdminBreakpoints.isTablet(context);
    final sidebarCompact = isTablet && _sidebarCollapsed;
    final sidebarWidth = useDrawer
        ? 0.0
        : AdminBreakpoints.sidebarWidth(context, collapsed: _sidebarCollapsed);

    return AdminSessionScope(
      user: widget.user,
      child: AdminNavigationScope(
        navigate: _onRouteSelected,
        takeParams: _takeParams,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AdminTheme.contentBg,
          drawer: useDrawer
              ? Drawer(
                  width: AdminBreakpoints.drawerWidth,
                  backgroundColor: AdminTheme.sidebarBg,
                  child: AdminSidebar(
                    user: widget.user,
                    selectedRoute: _route,
                    onRouteSelected: _onRouteSelected,
                    onCloseDrawer: () => Navigator.of(context).pop(),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!useDrawer)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: sidebarWidth,
                  child: _SidebarHost(
                    compact: sidebarCompact,
                    showCollapseToggle: isTablet,
                    collapsed: _sidebarCollapsed,
                    onToggleCollapse: _toggleSidebarCollapsed,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (!useDrawer)
                      AdminTopBar(
                        user: widget.user,
                        notificationCount: _notificationCount,
                        onOpenNotifications: _openNotificationCenter,
                        onRefresh: _refreshCurrentView,
                        lastRefreshed: _lastRefreshed,
                        isRefreshing: _refreshing,
                        compact: width < AdminBreakpoints.desktop,
                      ),
                    if (useDrawer) _MobileHeader(
                      scaffoldKey: _scaffoldKey,
                      user: widget.user,
                      notificationCount: _notificationCount,
                      onOpenNotifications: _openNotificationCenter,
                      onRefresh: _refreshCurrentView,
                      isRefreshing: _refreshing,
                    ),
                    Expanded(
                      child: BackendOfflineBanner(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey(_route),
                            child: AdminPageRouter.pageFor(_route),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarHost extends StatelessWidget {
  const _SidebarHost({
    required this.compact,
    required this.showCollapseToggle,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  final bool compact;
  final bool showCollapseToggle;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final shell = context.findAncestorStateOfType<_WebAdminShellState>()!;
    return AdminSidebar(
      user: shell.widget.user,
      selectedRoute: shell._route,
      onRouteSelected: shell._onRouteSelected,
      compact: compact,
      showCollapseToggle: showCollapseToggle,
      sidebarCollapsed: collapsed,
      onToggleCollapse: onToggleCollapse,
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.scaffoldKey,
    required this.user,
    required this.notificationCount,
    required this.onOpenNotifications,
    required this.onRefresh,
    required this.isRefreshing,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final AuthUser user;
  final int notificationCount;
  final VoidCallback onOpenNotifications;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final narrow = AdminBreakpoints.widthOf(context) < 430;

    return Material(
      color: AdminTheme.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
              ),
              Expanded(
                child: AccessHeaderBrand(logoSize: narrow ? 34 : 40, theme: AccessBrandTheme.light),
              ),
              IconButton(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 22),
                tooltip: 'Refresh',
              ),
              NotificationBell(unreadCount: notificationCount, onOpen: onOpenNotifications),
              ProfileDropdown(user: user, iconOnly: narrow),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
