import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';

/// One-time navigation params consumed by destination pages (e.g. card → filter).
class AdminNavigationScope extends InheritedWidget {
  const AdminNavigationScope({
    super.key,
    required this.navigate,
    this.takeParams,
    required super.child,
  });

  final void Function(AdminRoute route, {Map<String, dynamic>? params}) navigate;
  final Map<String, dynamic>? Function(AdminRoute route)? takeParams;

  static AdminNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminNavigationScope>();
  }

  static void go(BuildContext context, AdminRoute route, {Map<String, dynamic>? params}) {
    maybeOf(context)?.navigate(route, params: params);
  }

  /// Returns and clears params for [route] (call once after navigation).
  static Map<String, dynamic>? consumeParams(BuildContext context, AdminRoute route) {
    return maybeOf(context)?.takeParams?.call(route);
  }

  @override
  bool updateShouldNotify(AdminNavigationScope oldWidget) =>
      navigate != oldWidget.navigate || takeParams != oldWidget.takeParams;
}
