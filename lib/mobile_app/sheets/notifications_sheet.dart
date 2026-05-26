import 'package:flutter/material.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/widgets/access_branding.dart';
import 'package:access_mobile/web_admin/features/notifications/notification_models.dart';

void showNotifications(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _MemberNotificationCenter(),
  );
}

class _MemberNotificationCenter extends StatefulWidget {
  const _MemberNotificationCenter();

  @override
  State<_MemberNotificationCenter> createState() => _MemberNotificationCenterState();
}

class _MemberNotificationCenterState extends State<_MemberNotificationCenter> {
  NotificationFilterTab _tab = NotificationFilterTab.all;
  bool _loading = false;

  int get _unread => appState.notifications.where((n) => !n.read).length;

  List<AppNotification> get _filtered {
    final all = appState.notifications;
    return switch (_tab) {
      NotificationFilterTab.unread => all.where((n) => !n.read).toList(),
      _ => all,
    };
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await memberDataController.refreshAll();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        final colors = context.colors;
        return Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const AccessBrandMark.iconOnly(logoSize: 22),
                  const SizedBox(width: 10),
                  const Icon(Icons.notifications_active_outlined, color: kAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _unread > 0 ? '$_unread unread' : 'All caught up',
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh, size: 20)),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _filterChip(NotificationFilterTab.all, 'All'),
                  _filterChip(NotificationFilterTab.unread, 'Unread'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kAccent))
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text('No notifications', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final n = _filtered[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: n.read ? colors.surfaceAlt : kAccent.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: n.read ? colors.border : kAccent.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: kAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(n.icon, color: kAccent, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.title,
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(n.body, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (!n.read)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _unread == 0
                        ? null
                        : () async {
                            await memberDataController.markAllNotificationsRead();
                            if (mounted) setState(() {});
                          },
                    child: const Text('Mark all read', style: TextStyle(color: kAccent, fontSize: 12)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  Widget _filterChip(NotificationFilterTab tab, String label) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        selected: selected,
        onSelected: (_) => setState(() => _tab = tab),
        selectedColor: kAccent.withValues(alpha: 0.12),
        checkmarkColor: kAccent,
      ),
    );
  }
}
