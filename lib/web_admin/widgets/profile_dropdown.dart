import 'package:flutter/material.dart';
import 'package:access_mobile/shared/controllers/auth_controller.dart';
import 'package:access_mobile/shared/models/user_model.dart';
import 'package:access_mobile/web_admin/config/admin_permissions.dart';
import 'package:access_mobile/web_admin/layout/confirm_dialog.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class ProfileDropdown extends StatelessWidget {
  const ProfileDropdown({super.key, required this.user, this.iconOnly = false});

  final AuthUser user;
  final bool iconOnly;

  Future<void> _logout(BuildContext context) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Sign out?',
      message: 'You will return to the login screen.',
      confirmLabel: 'Sign out',
      icon: Icons.logout_rounded,
    );
    if (ok == true) authController.logout();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (ctx) => [
        PopupMenuItem<void>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(user.email, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(user.role.displayLabel, style: const TextStyle(fontSize: 11, color: AdminTheme.accentBlue)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          onTap: () => _logout(context),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AdminTheme.danger),
              SizedBox(width: 10),
              Text('Sign out', style: TextStyle(color: AdminTheme.danger, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!iconOnly) ...[
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.role.displayLabel,
                    style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          CircleAvatar(
            radius: iconOnly ? 18 : 20,
            backgroundColor: AdminTheme.accentBlue,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: iconOnly ? 14 : 15,
              ),
            ),
          ),
          if (!iconOnly)
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AdminTheme.textSecondary),
        ],
      ),
    );
  }
}
