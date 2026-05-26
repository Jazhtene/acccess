import 'package:access_mobile/web_admin/features/notifications/notification_models.dart';

List<AdminNotificationItem> notificationsFromApi(List<Map<String, dynamic>> list) {
  return list.map(AdminNotificationItem.fromMap).toList();
}
