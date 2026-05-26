import 'package:flutter/material.dart';
import 'package:access_mobile/shared/models/user_model.dart';
import 'package:access_mobile/web_admin/config/admin_permissions.dart';

/// Provides the signed-in admin user to descendant widgets (permissions, labels).
class AdminSessionScope extends InheritedWidget {
  const AdminSessionScope({
    super.key,
    required this.user,
    required super.child,
  });

  final AuthUser user;

  static AuthUser of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdminSessionScope>();
    assert(scope != null, 'AdminSessionScope not found');
    return scope!.user;
  }

  static AuthUser? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminSessionScope>()?.user;
  }

  bool can(AdminCapability capability) => user.role.can(capability);

  @override
  bool updateShouldNotify(AdminSessionScope oldWidget) => oldWidget.user.id != user.id;
}
