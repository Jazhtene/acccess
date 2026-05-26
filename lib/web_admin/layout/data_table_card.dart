import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/layout/pagination_footer.dart';
import 'package:access_mobile/web_admin/layout/pagination_state.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';
import 'package:access_mobile/web_admin/layout/admin_data_constants.dart';
import 'package:access_mobile/web_admin/widgets/admin_empty_state.dart';

/// Table inside a white card with gray header, footer, pagination, and empty state.
class DataTableCard extends StatelessWidget {
  const DataTableCard({
    super.key,
    this.title,
    required this.shownCount,
    required this.totalCount,
    required this.child,
    this.emptyTitle = AdminDataConstants.emptyRecordsTitle,
    this.emptyMessage = AdminDataConstants.emptyRecordsMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.onEmptyAction,
    this.emptyActionLabel,
    this.minHeight = 200,
    this.pagination,
    this.rangeLabel,
    this.onPageChanged,
    this.onPageSizeChanged,
  });

  final String? title;
  final int shownCount;
  final int totalCount;
  final Widget child;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final VoidCallback? onEmptyAction;
  final String? emptyActionLabel;
  final double minHeight;
  final PaginationState? pagination;
  final String? rangeLabel;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final isEmpty = totalCount == 0;
    final footerLabel = rangeLabel ??
        (pagination != null
            ? pagination!.rangeLabel(totalCount)
            : 'Showing $shownCount of $totalCount records');

    return Container(
      width: double.infinity,
      decoration: AdminTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Text(
                title!,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AdminTheme.textPrimary),
              ),
            ),
          if (isEmpty)
            SizedBox(
              height: minHeight,
              child: AdminEmptyState(
                title: emptyTitle,
                message: emptyMessage,
                icon: emptyIcon,
                actionLabel: emptyActionLabel,
                onAction: onEmptyAction,
              ),
            )
          else
            ClipRect(child: child),
          if (pagination != null && onPageChanged != null && onPageSizeChanged != null && !isEmpty)
            PaginationFooter(
              rangeLabel: footerLabel,
              page: pagination!.page,
              totalPages: pagination!.totalPages(totalCount),
              pageSize: pagination!.pageSize,
              onPageChanged: onPageChanged!,
              onPageSizeChanged: onPageSizeChanged!,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: AdminTheme.border)),
              ),
              child: Text(
                footerLabel,
                style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}

/// Light gray header styling and row hover for DataTable rows.
class AdminDataTableTheme extends StatelessWidget {
  const AdminDataTableTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AdminTheme.textSecondary,
            letterSpacing: 0.2,
          ),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFF8FAFC);
            }
            return null;
          }),
          dataRowMinHeight: 56,
          dataRowMaxHeight: 88,
          dividerThickness: 1,
          horizontalMargin: 16,
          columnSpacing: 20,
        ),
      ),
      child: child,
    );
  }
}
