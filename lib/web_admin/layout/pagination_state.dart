import 'dart:math' as math;

/// Client-side pagination for admin tables.
class PaginationState {
  PaginationState({this.pageSize = 10});

  int page = 1;
  int pageSize;

  void reset() => page = 1;

  int totalPages(int totalItems) => math.max(1, (totalItems / pageSize).ceil());

  int startIndex(int totalItems) {
    if (totalItems == 0) return 0;
    return (page - 1) * pageSize;
  }

  int endIndex(int totalItems) {
    if (totalItems == 0) return 0;
    return math.min(page * pageSize, totalItems);
  }

  /// Clamps page when filters reduce result count.
  void clampPage(int totalItems) {
    final max = totalPages(totalItems);
    if (page > max) page = max;
    if (page < 1) page = 1;
  }

  List<T> slice<T>(List<T> items) {
    clampPage(items.length);
    if (items.isEmpty) return [];
    final start = startIndex(items.length);
    final end = endIndex(items.length);
    if (start >= items.length) return [];
    return items.sublist(start, end);
  }

  String rangeLabel(int totalItems) {
    if (totalItems == 0) return 'Showing 0 of 0 records';
    final start = startIndex(totalItems) + 1;
    final end = endIndex(totalItems);
    return 'Showing $start–$end of $totalItems records';
  }
}
