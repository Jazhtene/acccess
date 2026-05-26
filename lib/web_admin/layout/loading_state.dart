import 'package:flutter/material.dart';
import 'package:access_mobile/shared/widgets/access_branded_loading.dart';
import 'package:access_mobile/web_admin/layout/skeleton_loading.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'Loading…', this.useSkeleton = false});

  final String message;
  final bool useSkeleton;

  @override
  Widget build(BuildContext context) {
    if (useSkeleton) return const AdminPageSkeleton();

    return AccessBrandedLoading(
      message: message,
      logoSize: 64,
      textColor: AdminTheme.textSecondary,
    );
  }
}
