import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/shared/services/facebook_open_url.dart';
import 'package:access_mobile/web_admin/features/media_evaluation/media_evaluation_models.dart';
import 'package:access_mobile/web_admin/features/media_evaluation/widgets/media_evaluation_details_dialog.dart';
import 'package:access_mobile/web_admin/features/media_evaluation/widgets/media_evaluation_filter_bar.dart';
import 'package:access_mobile/web_admin/features/media_evaluation/widgets/media_evaluation_table.dart';
import 'package:access_mobile/web_admin/config/admin_permissions.dart';
import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/layout/admin_feature_page.dart';
import 'package:access_mobile/web_admin/layout/admin_route_breadcrumbs.dart';
import 'package:access_mobile/web_admin/layout/admin_session_scope.dart';
import 'package:access_mobile/web_admin/layout/confirm_dialog.dart';
import 'package:access_mobile/web_admin/layout/data_table_card.dart';
import 'package:access_mobile/web_admin/layout/page_header.dart';
import 'package:access_mobile/web_admin/layout/pagination_state.dart';
import 'package:access_mobile/web_admin/layout/search_filter_card.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Admin Media Evaluation — quality scores, AI detection, and member performance.
class MediaEvaluationPage extends StatefulWidget {
  const MediaEvaluationPage({super.key});

  @override
  State<MediaEvaluationPage> createState() => _MediaEvaluationPageState();
}

class _MediaEvaluationPageState extends State<MediaEvaluationPage> {
  List<MediaEvaluationRow> _allRows = [];
  MediaEvaluationSummary? _summary;
  bool _loading = true;
  String? _error;
  bool _showFilters = true;
  DateTime? _lastUpdated;
  final _pagination = PaginationState();
  final _filters = MediaEvaluationFilters();
  final _mediaSearch = TextEditingController();
  final _memberSearch = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mediaSearch.dispose();
    _memberSearch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // PostgreSQL media_evaluations via GET /api/admin/evaluations
      final list = await adminApi.allEvaluations();
      Map<String, dynamic> summaryMap;
      try {
        summaryMap = await adminApi.evaluationSummary();
      } catch (_) {
        summaryMap = {};
      }
      final rows = list.map(MediaEvaluationRow.fromMap).toList();

      if (mounted) {
        setState(() {
          _allRows = rows;
          _summary = summaryMap.isNotEmpty
              ? MediaEvaluationSummary.fromMap(summaryMap)
              : _summaryFromRows(rows);
          _loading = false;
          _lastUpdated = DateTime.now();
          _pagination.reset();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _allRows = [];
          _summary = const MediaEvaluationSummary(
            totalEvaluated: 0,
            averageOverallScore: 0,
            humanMediaCount: 0,
            aiSuspiciousCount: 0,
          );
          _loading = false;
          _lastUpdated = DateTime.now();
        });
      }
    }
  }

  MediaEvaluationSummary _summaryFromRows(List<MediaEvaluationRow> rows) {
    if (rows.isEmpty) {
      return const MediaEvaluationSummary(
        totalEvaluated: 0,
        averageOverallScore: 0,
        humanMediaCount: 0,
        aiSuspiciousCount: 0,
      );
    }
    final avg = rows.map((r) => r.overallScore).reduce((a, b) => a + b) / rows.length;
    var human = 0;
    var ai = 0;
    for (final r in rows) {
      if (r.aiLabel == AiResultLabel.human) {
        human++;
      } else if (r.aiLabel != AiResultLabel.pending) {
        ai++;
      } else {
        ai++;
      }
    }
    return MediaEvaluationSummary(
      totalEvaluated: rows.length,
      averageOverallScore: avg,
      humanMediaCount: human,
      aiSuspiciousCount: ai,
    );
  }

  List<MediaEvaluationRow> get _filteredRows {
    var rows = _allRows.where((r) {
      if (_filters.mediaQuery.isNotEmpty &&
          !r.mediaName.toLowerCase().contains(_filters.mediaQuery.toLowerCase())) {
        return false;
      }
      if (_filters.memberQuery.isNotEmpty &&
          !r.memberName.toLowerCase().contains(_filters.memberQuery.toLowerCase())) {
        return false;
      }
      if (_filters.aiFilter != null && r.aiLabel != _filters.aiFilter) return false;
      if (_filters.qualityFilter != null && r.qualityStatus != _filters.qualityFilter) {
        return false;
      }
      return true;
    }).toList();
    if (_filters.sortByOverallDesc) {
      rows.sort((a, b) => b.overallScore.compareTo(a.overallScore));
    }
    return rows;
  }

  void _clearFilters() {
    _filters.mediaQuery = '';
    _filters.memberQuery = '';
    _filters.aiFilter = null;
    _filters.qualityFilter = null;
    _filters.sortByOverallDesc = false;
    _mediaSearch.clear();
    _memberSearch.clear();
    _pagination.reset();
    setState(() {});
  }

  Future<void> _saveRemarks(MediaEvaluationRow row, String remarks) async {
    await adminApi.updateEvaluationRemarks(row.id, remarks);
    await _load();
  }

  Future<void> _archive(MediaEvaluationRow row) async {
    final ok = await _confirm('Archive "${row.mediaName}"?', 'It will be moved to archives.');
    if (ok != true) return;
    await adminApi.archiveEvaluatedMedia(row.id);
    await _load();
    _snack('Media archived');
  }

  Future<void> _delete(MediaEvaluationRow row) async {
    final ok = await _confirm(
      'Delete "${row.mediaName}"?',
      'This permanently removes the media file.',
      destructive: true,
    );
    if (ok != true) return;
    await adminApi.deleteMedia(row.mediaId);
    await _load();
    _snack('Media deleted');
  }

  Future<bool?> _confirm(String title, String body, {bool destructive = false}) {
    return ConfirmDialog.show(
      context,
      title: title,
      message: body,
      destructive: destructive,
      confirmLabel: destructive ? 'Delete' : 'Confirm',
      icon: destructive ? Icons.delete_outline : Icons.archive_outlined,
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _reviewMedia(MediaEvaluationRow row) async {
    final url = AdminApiService.mediaUrl(row.fileUrl.isNotEmpty ? row.fileUrl : null);
    if (url.isEmpty) {
      _snack('No media URL available');
      return;
    }
    await openExternalUrl(url);
  }

  void _exportReport() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Media Name,Member,Sharpness,Brightness,Contrast,Overall,AI Result,Quality,Date,Remarks',
    );
    for (final r in _filteredRows) {
      buffer.writeln(
        '"${r.mediaName}","${r.memberName}",${scoreToPercent(r.sharpnessScore)},'
        '${scoreToPercent(r.brightnessScore)},${scoreToPercent(r.contrastScore)},'
        '${scoreToPercent(r.overallScore)},${r.aiLabel.name},${r.qualityStatus.name},'
        '"${formatEvaluatedDate(r.evaluatedAt)}","${(r.adminRemarks ?? '').replaceAll('"', '""')}"',
      );
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export report'),
        content: SizedBox(
          width: AdminBreakpoints.panelMaxWidth(ctx),
          child: SelectableText(buffer.toString(), style: const TextStyle(fontSize: 11)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              Navigator.pop(ctx);
              _snack('Report copied to clipboard');
            },
            child: const Text('Copy CSV'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AdminSessionScope.of(context);
    final filtered = _filteredRows;
    final pageRows = _pagination.slice(filtered);
    final canExport = session.role.can(AdminCapability.exportData);
    final canDelete = session.role.can(AdminCapability.deleteRecords);
    final canArchive = session.role.can(AdminCapability.archiveRecords);

    return AdminFeaturePage(
      title: 'Media Evaluation',
      subtitle: 'Review media quality scores, AI detection results, and member upload performance.',
      breadcrumbs: breadcrumbsForRoute(AdminRoute.mediaEvaluation),
      lastUpdated: _lastUpdated,
      loading: _loading,
      error: _error,
      errorTitle: 'Unable to load media evaluations',
      onRetry: _load,
      actions: [
        PageHeaderButton(
          label: _showFilters ? 'Hide filters' : 'Filter results',
          icon: _showFilters ? Icons.filter_list_off : Icons.filter_list,
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        PageHeaderButton(
          label: 'Export report',
          icon: Icons.download_outlined,
          onPressed: canExport ? _exportReport : null,
          enabled: canExport,
        ),
        PageHeaderIconButton(icon: Icons.refresh, onPressed: _load, tooltip: 'Refresh'),
      ],
      filter: SearchFilterCard(
        child: MediaEvaluationFilterBar(
          filters: _filters,
          mediaSearchController: _mediaSearch,
          memberSearchController: _memberSearch,
          showFilters: _showFilters,
          onToggleFilters: () => setState(() => _showFilters = !_showFilters),
          onChanged: () {
            _pagination.reset();
            setState(() {});
          },
          onClear: _clearFilters,
        ),
      ),
      body: DataTableCard(
        title: 'Media evaluations',
        shownCount: pageRows.length,
        totalCount: filtered.length,
        pagination: _pagination,
        rangeLabel: _pagination.rangeLabel(filtered.length),
        onPageChanged: (p) => setState(() => _pagination.page = p),
        onPageSizeChanged: (size) => setState(() {
          _pagination.pageSize = size;
          _pagination.reset();
        }),
        emptyTitle: 'No media evaluations found',
        emptyMessage: 'Uploaded media will appear here once evaluated.',
        emptyIcon: Icons.fact_check_outlined,
        emptyActionLabel: _allRows.isEmpty ? 'Refresh' : 'Clear filters',
        onEmptyAction: _allRows.isEmpty ? _load : _clearFilters,
        minHeight: 280,
        child: MediaEvaluationTable(
          rows: pageRows,
          canArchive: canArchive,
          canDelete: canDelete,
          onViewDetails: (r) => MediaEvaluationDetailsDialog.show(
            context,
            row: r,
            onSaveRemarks: (remarks) => _saveRemarks(r, remarks),
          ),
          onReviewMedia: _reviewMedia,
          onArchive: _archive,
          onDelete: _delete,
        ),
      ),
    );
  }
}
