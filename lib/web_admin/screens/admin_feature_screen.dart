import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/layout/admin_data_constants.dart';
import 'package:access_mobile/web_admin/layout/admin_feature_page.dart';
import 'package:access_mobile/web_admin/layout/admin_route_breadcrumbs.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/widgets/admin_empty_state.dart';

/// Placeholder admin module page — shows feature list until a dedicated screen is wired.
class AdminFeatureScreen extends StatelessWidget {
  const AdminFeatureScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.features,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> features;
  final AdminRoute? route;

  @override
  Widget build(BuildContext context) {
    final breadcrumbs = route != null ? breadcrumbsForRoute(route!) : const ['Dashboard'];

    return AdminFeaturePage(
      title: title,
      subtitle: subtitle,
      breadcrumbs: breadcrumbs,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: features
                .map(
                  (f) => Chip(
                    avatar: Icon(Icons.check_circle, size: 18, color: color),
                    label: Text(f),
                    backgroundColor: color.withValues(alpha: 0.08),
                  ),
                )
                .toList(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: AdminEmptyState(
              title: AdminDataConstants.emptyRecordsTitle,
              message: AdminDataConstants.emptyRecordsMessage,
            ),
          ),
        ],
      ),
    );
  }
}
