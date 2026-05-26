import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/error_state.dart';
import 'package:access_mobile/web_admin/layout/page_header.dart';
import 'package:access_mobile/web_admin/layout/skeleton_loading.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Standard scrollable admin feature page shell.
class AdminFeaturePage extends StatelessWidget {
  const AdminFeaturePage({
    super.key,
    required this.title,
    required this.subtitle,
    this.breadcrumbs = const [],
    this.actions = const [],
    this.lastUpdated,
    this.alert,
    this.summary,
    this.filter,
    this.activeFilter,
    this.loading = false,
    this.useSkeleton = true,
    this.error,
    this.onRetry,
    this.errorTitle,
    required this.body,
  });

  final String title;
  final String subtitle;
  final List<String> breadcrumbs;
  final List<Widget> actions;
  final DateTime? lastUpdated;
  final Widget? alert;
  final Widget? summary;
  final Widget? filter;
  final Widget? activeFilter;
  final bool loading;
  final bool useSkeleton;
  final String? error;
  final VoidCallback? onRetry;
  final String? errorTitle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminTheme.contentBg,
      child: loading && useSkeleton
          ? const AdminPageSkeleton()
          : SingleChildScrollView(
              clipBehavior: Clip.hardEdge,
              padding: AdminBreakpoints.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: title,
                    subtitle: subtitle,
                    breadcrumbs: breadcrumbs,
                    actions: actions,
                    lastUpdated: lastUpdated,
                  ),
                  if (loading && !useSkeleton) ...[
                    const SizedBox(height: 48),
                    const Center(child: CircularProgressIndicator()),
                  ] else ...[
                    if (alert != null) ...[const SizedBox(height: 16), alert!],
                    if (error != null && onRetry != null) ...[
                      const SizedBox(height: 16),
                      ErrorState(
                        title: errorTitle ?? 'Unable to load data',
                        message: _friendlyError(error!),
                        onRetry: onRetry,
                      ),
                    ],
                    if (summary != null) ...[const SizedBox(height: 22), summary!],
                    if (filter != null) ...[const SizedBox(height: 18), filter!],
                    if (activeFilter != null) ...[const SizedBox(height: 12), activeFilter!],
                    if (error == null) ...[const SizedBox(height: 18), body],
                  ],
                ],
              ),
            ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('Connection') || raw.contains('SocketException') || raw.contains('Failed host')) {
      return 'Please check your connection and ensure the backend server is running, then try again.';
    }
    return raw.length > 180 ? '${raw.substring(0, 180)}…' : raw;
  }
}
