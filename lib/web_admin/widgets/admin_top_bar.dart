import 'package:flutter/material.dart';

import 'package:access_mobile/shared/models/user_model.dart';

import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/last_updated_text.dart';
import 'package:access_mobile/web_admin/layout/notification_center.dart';
import 'package:access_mobile/shared/widgets/access_branding.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

import 'package:access_mobile/web_admin/widgets/profile_dropdown.dart';

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.user,
    this.onSearch,
    this.notificationCount = 0,
    this.onOpenNotifications,
    this.onRefresh,
    this.lastRefreshed,
    this.isRefreshing = false,
    this.compact = false,
  });

  final AuthUser user;
  final ValueChanged<String>? onSearch;
  final int notificationCount;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onRefresh;
  final DateTime? lastRefreshed;
  final bool isRefreshing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = AdminBreakpoints.widthOf(context);
    final hideSearch = width < 900;
    final hideLastUpdated = width < 1100;
    final profileIconOnly = width < 960;

    return Material(
      elevation: 0,
      color: AdminTheme.surface,
      child: Container(
        height: compact ? 60 : 68,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
        decoration: const BoxDecoration(
          color: AdminTheme.surface,
          border: Border(bottom: BorderSide(color: AdminTheme.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A0F2744),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AccessBrandMark.iconOnly(logoSize: compact ? 36 : 42),
            const SizedBox(width: 12),
            if (!hideSearch)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: c.maxWidth.clamp(120, 480)),
                      child: TextField(
                        onChanged: onSearch,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search events, members, media…',
                          hintStyle: TextStyle(
                            color: AdminTheme.textSecondary.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(Icons.search, color: AdminTheme.textSecondary, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AdminTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AdminTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AdminTheme.accentCyan, width: 1.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Spacer(),
            if (onRefresh != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Refresh current view',
                child: IconButton(
                  onPressed: isRefreshing ? null : onRefresh,
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 22),
                  style: IconButton.styleFrom(
                    foregroundColor: AdminTheme.textSecondary,
                    backgroundColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ),
            ],
            if (lastRefreshed != null && !hideLastUpdated) ...[
              const SizedBox(width: 8),
              LastUpdatedText(updatedAt: lastRefreshed),
            ],
            const SizedBox(width: 4),
            NotificationBell(
              unreadCount: notificationCount,
              onOpen: onOpenNotifications ?? () {},
            ),
            const SizedBox(width: 8),
            if (!profileIconOnly) ...[
              const VerticalDivider(width: 1, indent: 16, endIndent: 16, color: AdminTheme.border),
              const SizedBox(width: 8),
            ],
            ProfileDropdown(user: user, iconOnly: profileIconOnly),
          ],
        ),
      ),
    );
  }
}
