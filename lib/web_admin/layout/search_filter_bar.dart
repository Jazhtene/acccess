import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Compact search + filter row for use inside [SearchFilterCard].
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.searchController,
    this.searchHint = 'Search…',
    this.onSearchChanged,
    this.filters = const [],
    this.onClear,
    this.showClear = false,
  });

  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> filters;
  final VoidCallback? onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 720;
        final searchField = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search, size: 20, color: AdminTheme.textSecondary),
            isDense: true,
          ),
        );

        final filterRow = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...filters,
            if (showClear && onClear != null)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear filters'),
              ),
          ],
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              if (filters.isNotEmpty || showClear) ...[const SizedBox(height: 12), filterRow],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: searchField),
            if (filters.isNotEmpty || showClear) ...[
              const SizedBox(width: 12),
              Expanded(flex: 3, child: filterRow),
            ],
          ],
        );
      },
    );
  }
}

/// Styled dropdown for filter bars.
Widget adminFilterDropdown<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  double? width,
}) {
  return LayoutBuilder(
    builder: (context, c) {
      final fieldWidth = width ?? (c.maxWidth < 720 && c.maxWidth > 0 ? c.maxWidth : 160.0);
      return SizedBox(
    width: fieldWidth,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text('All', style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary.withValues(alpha: 0.9))),
          items: items,
          onChanged: onChanged,
        ),
      ),
    ),
      );
    },
  );
}
