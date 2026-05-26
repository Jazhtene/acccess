import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/data/admin_notification_helpers.dart';
import 'package:access_mobile/web_admin/features/notifications/notification_models.dart';
import 'package:access_mobile/web_admin/navigation/admin_navigation_scope.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';
import 'package:access_mobile/web_admin/widgets/admin_shell_scaffold.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _audience = 'all';
  List<AdminNotificationItem> _items = [];
  NotificationFilterTab _tab = NotificationFilterTab.all;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await adminApi.myNotifications();
      if (mounted) {
        setState(() {
          _items = notificationsFromApi(list);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _broadcast() async {
    if (_titleCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final count = await adminApi.broadcastNotification(
        title: _titleCtrl.text.trim(),
        message: _msgCtrl.text.trim(),
        audience: _audience,
      );
      _titleCtrl.clear();
      _msgCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Broadcast sent to $count users')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  List<AdminNotificationItem> get _filtered => _items.where((n) => n.matchesFilter(_tab)).toList();

  int get _unread => _items.where((n) => n.unread).length;

  @override
  Widget build(BuildContext context) {
    return AdminShellScaffold(
      title: 'Notification Center',
      subtitle: 'Activity feed, broadcasts, and system alerts.',
      actions: [
        IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        TextButton(
          onPressed: _unread == 0
              ? null
              : () async {
                  await adminApi.markAllNotificationsRead();
                  await _load();
                },
          child: const Text('Mark all read'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Broadcast alert', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _msgCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _audience,
                    decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All approved users')),
                      DropdownMenuItem(value: 'member', child: Text('Members only')),
                      DropdownMenuItem(value: 'organization', child: Text('Organizations only')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins only')),
                    ],
                    onChanged: (v) => setState(() => _audience = v ?? 'all'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _sending ? null : _broadcast,
                    icon: _sending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.campaign),
                    label: const Text('Send broadcast'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(NotificationFilterTab.all, 'All'),
                _filterChip(NotificationFilterTab.unread, 'Unread'),
                _filterChip(NotificationFilterTab.requests, 'Requests'),
                _filterChip(NotificationFilterTab.mediaEvaluation, 'Media Evaluation'),
                _filterChip(NotificationFilterTab.aiAlerts, 'AI Alerts'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 48, color: AdminTheme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('No notifications', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _NotificationRow(
                          item: _filtered[i],
                          onTap: () async {
                            final n = _filtered[i];
                            if (n.unread && n.id > 0) {
                              await adminApi.markNotificationRead(n.id);
                              await _load();
                            }
                            if (n.route != null && context.mounted) {
                              AdminNavigationScope.go(context, n.route!);
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(NotificationFilterTab tab, String label) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        selected: selected,
        onSelected: (_) => setState(() => _tab = tab),
        selectedColor: AdminTheme.accentBlue.withValues(alpha: 0.12),
        checkmarkColor: AdminTheme.accentBlue,
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onTap});
  final AdminNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = item;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: n.unread ? AdminTheme.accentBlue.withValues(alpha: 0.08) : AdminTheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: n.unread ? AdminTheme.accentBlue.withValues(alpha: 0.35) : AdminTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: n.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(n.icon, color: n.accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.unread ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (n.unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AdminTheme.accentBlue, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n.message, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _badge(n.categoryLabel, n.accentColor),
                          _badge(n.priorityLabel, AdminTheme.textSecondary),
                          Text(n.timeAgo, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                      if (n.actionButtonLabel != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(n.actionButtonLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
