import 'package:access_mobile/web_admin/navigation/admin_routes.dart';

/// Breadcrumb segments for each admin route.
List<String> breadcrumbsForRoute(AdminRoute route) {
  if (route == AdminRoute.dashboard) return const ['Dashboard'];

  final group = groupContainingRoute(route);
  final leaf = group?.children.where((c) => c.route == route).firstOrNull;

  if (group == null || leaf == null) {
    return ['Dashboard', _fallbackLabel(route)];
  }

  return ['Dashboard', group.label, leaf.label];
}

String _fallbackLabel(AdminRoute route) {
  return route.name
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
      .trim()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
