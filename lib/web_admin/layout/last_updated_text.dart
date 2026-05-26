import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class LastUpdatedText extends StatelessWidget {
  const LastUpdatedText({super.key, required this.updatedAt});

  final DateTime? updatedAt;

  static String format(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = dt.toLocal();
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year}, $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (updatedAt == null) return const SizedBox.shrink();
    return Text(
      'Last updated: ${format(updatedAt!)}',
      style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary, fontWeight: FontWeight.w500),
    );
  }
}
