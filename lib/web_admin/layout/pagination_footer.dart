import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Table footer with range label, page controls, and rows-per-page selector.
class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.rangeLabel,
    required this.page,
    required this.totalPages,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.pageSizeOptions = const [10, 25, 50],
  });

  final String rangeLabel;
  final int page;
  final int totalPages;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final List<int> pageSizeOptions;

  @override
  Widget build(BuildContext context) {
    final canPrev = page > 1;
    final canNext = page < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: AdminTheme.border)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 640;
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rows per page', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: pageSizeOptions.contains(pageSize) ? pageSize : pageSizeOptions.first,
                  items: pageSizeOptions
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n', style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onPageSizeChanged(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: canPrev ? () => onPageChanged(page - 1) : null,
                icon: const Icon(Icons.chevron_left, size: 22),
                tooltip: 'Previous page',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledForegroundColor: AdminTheme.textSecondary.withValues(alpha: 0.4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Page $page of $totalPages',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary),
                ),
              ),
              IconButton(
                onPressed: canNext ? () => onPageChanged(page + 1) : null,
                icon: const Icon(Icons.chevron_right, size: 22),
                tooltip: 'Next page',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledForegroundColor: AdminTheme.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(rangeLabel, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: controls),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Text(
                  rangeLabel,
                  style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
              controls,
            ],
          );
        },
      ),
    );
  }
}
