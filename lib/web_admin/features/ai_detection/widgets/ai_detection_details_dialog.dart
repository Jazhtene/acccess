import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/features/ai_detection/ai_detection_models.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/admin_remarks_box.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/ai_result_badge.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/ai_review_action_buttons.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/ai_review_status_badge.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/confidence_progress_bar.dart';
import 'package:access_mobile/web_admin/features/ai_detection/widgets/review_history_timeline.dart';
import 'package:access_mobile/web_admin/layout/confirm_dialog.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Full AI review details dialog with actions, remarks, and history.
class AiReviewDetailsDialog extends StatefulWidget {
  const AiReviewDetailsDialog({
    super.key,
    required this.row,
    required this.onSave,
    required this.onArchive,
    this.loadHistory,
    this.usingSample = false,
  });

  final AiDetectionRow row;
  final Future<void> Function(ReviewStatus status, String remarks) onSave;
  final Future<void> Function() onArchive;
  final Future<List<AiReviewHistoryEntry>> Function(int aiId)? loadHistory;
  final bool usingSample;

  static Future<void> show(
    BuildContext context, {
    required AiDetectionRow row,
    required Future<void> Function(ReviewStatus status, String remarks) onSave,
    required Future<void> Function() onArchive,
    Future<List<AiReviewHistoryEntry>> Function(int aiId)? loadHistory,
    bool usingSample = false,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AiReviewDetailsDialog(
        row: row,
        onSave: onSave,
        onArchive: onArchive,
        loadHistory: loadHistory,
        usingSample: usingSample,
      ),
    );
  }

  @override
  State<AiReviewDetailsDialog> createState() => _AiReviewDetailsDialogState();
}

/// Backward-compatible alias.
typedef AiDetectionDetailsDialog = AiReviewDetailsDialog;

class _AiReviewDetailsDialogState extends State<AiReviewDetailsDialog> {
  late ReviewStatus _status;
  late final TextEditingController _remarks;
  bool _saving = false;
  bool _loadingHistory = true;
  List<AiReviewHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _status = widget.row.reviewStatus;
    _remarks = TextEditingController(text: widget.row.adminRemarks ?? '');
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (widget.loadHistory == null) {
      setState(() => _loadingHistory = false);
      return;
    }
    try {
      final list = await widget.loadHistory!(widget.row.id);
      if (mounted) setState(() {
        _history = list;
        _loadingHistory = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save([ReviewStatus? status]) async {
    setState(() => _saving = true);
    try {
      await widget.onSave(status ?? _status, _remarks.text.trim());
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirm(String title, String message, {IconData icon = Icons.help_outline}) {
    return ConfirmDialog.show(context, title: title, message: message, icon: icon);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final url = AdminApiService.mediaUrl(row.mediaUrl.isNotEmpty ? row.mediaUrl : null);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('AI Review Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  AiReviewStatusBadge(status: _status),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (url.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, height: 160, width: double.infinity, fit: BoxFit.cover),
                        )
                      else
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AdminTheme.contentBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image_outlined, size: 48, color: AdminTheme.textSecondary),
                        ),
                      const SizedBox(height: 16),
                      _row('Media name', row.mediaName),
                      _row('Uploaded by', row.memberName),
                      _row('Upload date', formatScannedDate(row.scannedAt)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('AI result', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(width: 10),
                          AiResultBadge(label: row.aiLabel),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConfidenceProgressBar(
                        score: row.confidenceScore,
                        label: row.confidenceText,
                        confidenceLevel: row.confidenceLevel,
                      ),
                      if (row.detectionRemarks != null && row.detectionRemarks!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _row('Detection remarks', row.detectionRemarks!),
                      ],
                      const SizedBox(height: 16),
                      const Text('Review status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ReviewStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(isDense: true),
                        items: ReviewStatus.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(reviewStatusLabel(s))))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v ?? _status),
                      ),
                      const SizedBox(height: 16),
                      AdminRemarksBox(controller: _remarks),
                      const SizedBox(height: 16),
                      const Text('Quick review actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 8),
                      AiReviewActionButtons(
                        row: row,
                        onAction: (status, remarks) async {
                          _remarks.text = remarks;
                          setState(() => _status = status);
                          await _save(status);
                        },
                        onConfirm: _confirm,
                      ),
                      const SizedBox(height: 16),
                      if (_loadingHistory)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else
                        ReviewHistoryTimeline(entries: _history),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final ok = await _confirm(
                              'Archive media?',
                              'Archive "${row.mediaName}"? This removes it from active results.',
                              icon: Icons.archive_outlined,
                            );
                            if (ok == true) {
                              await widget.onArchive();
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('Archive'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save review'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
