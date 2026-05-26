import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/features/media_evaluation/media_evaluation_models.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

enum ReviewStatus {
  pendingReview,
  verifiedHuman,
  confirmedAiGenerated,
  needsFurtherReview,
  acceptedWithWarning,
  reuploadRequested,
  rejected,
}

enum ConfidenceLevel { high, medium, low }

class AiReviewHistoryEntry {
  const AiReviewHistoryEntry({
    required this.id,
    required this.previousStatus,
    required this.newStatus,
    required this.adminRemarks,
    required this.reviewedByName,
    required this.reviewedAt,
    this.aiResult,
    this.confidenceScore,
  });

  final int id;
  final String? previousStatus;
  final String newStatus;
  final String? adminRemarks;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? aiResult;
  final double? confidenceScore;

  factory AiReviewHistoryEntry.fromMap(Map<String, dynamic> m) => AiReviewHistoryEntry(
        id: m['id'] as int? ?? 0,
        previousStatus: m['previous_status'] as String?,
        newStatus: m['new_status'] as String? ?? '',
        adminRemarks: m['admin_remarks'] as String?,
        reviewedByName: m['reviewed_by_name'] as String?,
        reviewedAt: DateTime.tryParse(m['reviewed_at']?.toString() ?? ''),
        aiResult: m['ai_result'] as String?,
        confidenceScore: (m['confidence_score'] as num?)?.toDouble(),
      );
}

class AiDetectionRow {
  AiDetectionRow({
    required this.id,
    required this.mediaId,
    this.memberId,
    required this.mediaName,
    required this.mediaUrl,
    required this.memberName,
    required this.aiResult,
    required this.aiProbability,
    required this.confidenceScore,
    required this.confidenceLevel,
    required this.reviewStatus,
    required this.adminRemarks,
    required this.detectionRemarks,
    required this.reviewedByAdmin,
    required this.scannedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  final int id;
  final int mediaId;
  final int? memberId;
  final String mediaName;
  final String mediaUrl;
  final String memberName;
  final String? aiResult;
  final double aiProbability;
  final double confidenceScore;
  final ConfidenceLevel confidenceLevel;
  final ReviewStatus reviewStatus;
  final String? adminRemarks;
  final String? detectionRemarks;
  final bool reviewedByAdmin;
  final DateTime? scannedAt;
  final int? reviewedBy;
  final DateTime? reviewedAt;

  factory AiDetectionRow.fromMap(Map<String, dynamic> m) {
    final aiProb = (m['ai_probability'] as num?)?.toDouble() ?? 0;
    final conf = (m['confidence_score'] as num?)?.toDouble();
    final result = m['ai_result'] as String? ?? m['detection_result'] as String?;
    final label = aiLabelForDetection(result, aiProb);
    final score = conf ?? _confidenceFor(label, aiProb);

    return AiDetectionRow(
      id: m['id'] as int? ?? 0,
      mediaId: m['media_id'] as int? ?? 0,
      memberId: m['member_id'] as int?,
      mediaName: m['media_name'] as String? ?? m['file_name'] as String? ?? 'Untitled',
      mediaUrl: m['media_url'] as String? ?? m['file_url'] as String? ?? '',
      memberName: m['member_name'] as String? ?? m['uploader_name'] as String? ?? 'Unknown',
      aiResult: result,
      aiProbability: aiProb,
      confidenceScore: score,
      confidenceLevel: confidenceLevelFromString(m['confidence_level'] as String?) ??
          confidenceLevelForScore(score),
      reviewStatus: _parseReviewStatus(m, label),
      adminRemarks: m['admin_remarks'] as String?,
      detectionRemarks: m['detection_remarks'] as String?,
      reviewedByAdmin: m['reviewed_by_admin'] as bool? ?? false,
      scannedAt: _parseDate(m['created_at']),
      reviewedBy: m['reviewed_by'] as int?,
      reviewedAt: _parseDate(m['reviewed_at']),
    );
  }

  AiResultLabel get aiLabel => aiLabelForDetection(aiResult, aiProbability);

  bool get isPendingReview =>
      reviewStatus == ReviewStatus.pendingReview || reviewStatus == ReviewStatus.needsFurtherReview;

  String get confidenceText {
    final pct = (confidenceScore * 100).round();
    return switch (aiLabel) {
      AiResultLabel.aiGenerated => '$pct% AI-generated confidence',
      AiResultLabel.suspicious => '$pct% Suspicious confidence',
      AiResultLabel.pending => 'Pending scan',
      AiResultLabel.human => '$pct% Human confidence',
    };
  }

  String get statusLabel => reviewStatusLabel(reviewStatus);

  AiDetectionRow copyWith({
    ReviewStatus? reviewStatus,
    String? adminRemarks,
    bool? reviewedByAdmin,
  }) =>
      AiDetectionRow(
        id: id,
        mediaId: mediaId,
        memberId: memberId,
        mediaName: mediaName,
        mediaUrl: mediaUrl,
        memberName: memberName,
        aiResult: aiResult,
        aiProbability: aiProbability,
        confidenceScore: confidenceScore,
        confidenceLevel: confidenceLevel,
        reviewStatus: reviewStatus ?? this.reviewStatus,
        adminRemarks: adminRemarks ?? this.adminRemarks,
        detectionRemarks: detectionRemarks,
        reviewedByAdmin: reviewedByAdmin ?? this.reviewedByAdmin,
        scannedAt: scannedAt,
        reviewedBy: reviewedBy,
        reviewedAt: reviewedAt,
      );

  static double _confidenceFor(AiResultLabel label, double aiProb) {
    if (label == AiResultLabel.aiGenerated) return aiProb.clamp(0.0, 1.0);
    if (label == AiResultLabel.pending) return 0;
    return (1.0 - aiProb).clamp(0.0, 1.0);
  }

  static ReviewStatus _parseReviewStatus(Map<String, dynamic> m, AiResultLabel label) {
    final raw = m['review_status'] as String?;
    if (raw != null && raw.isNotEmpty) return reviewStatusFromString(raw);
    return _reviewFromLegacy(m['reviewed_by_admin'] as bool? ?? false, label);
  }

  static ReviewStatus _reviewFromLegacy(bool reviewed, AiResultLabel label) {
    if (!reviewed) return ReviewStatus.pendingReview;
    if (label == AiResultLabel.aiGenerated) return ReviewStatus.confirmedAiGenerated;
    return ReviewStatus.verifiedHuman;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

AiResultLabel aiLabelForDetection(String? raw, double aiProb) {
  if (raw == null || raw.isEmpty) return AiResultLabel.pending;
  final base = aiLabelForResult(raw);
  if (base == AiResultLabel.human && aiProb >= 0.18) return AiResultLabel.suspicious;
  return base;
}

ConfidenceLevel confidenceLevelForScore(double score) {
  final pct = score * 100;
  if (pct >= 80) return ConfidenceLevel.high;
  if (pct >= 50) return ConfidenceLevel.medium;
  return ConfidenceLevel.low;
}

ConfidenceLevel? confidenceLevelFromString(String? raw) {
  if (raw == null) return null;
  return switch (raw.toLowerCase()) {
    'high' => ConfidenceLevel.high,
    'medium' => ConfidenceLevel.medium,
    'low' => ConfidenceLevel.low,
    _ => null,
  };
}

String reviewStatusLabel(ReviewStatus s) => switch (s) {
      ReviewStatus.pendingReview => 'Pending Review',
      ReviewStatus.verifiedHuman => 'Verified Human',
      ReviewStatus.confirmedAiGenerated => 'Confirmed AI-Generated',
      ReviewStatus.needsFurtherReview => 'Suspicious / Needs Further Review',
      ReviewStatus.acceptedWithWarning => 'Accepted with Warning',
      ReviewStatus.reuploadRequested => 'Reupload Requested',
      ReviewStatus.rejected => 'Rejected',
    };

ReviewStatus reviewStatusFromString(String? raw) {
  if (raw == null || raw.isEmpty) return ReviewStatus.pendingReview;
  final n = raw.toLowerCase();
  if (n.contains('verified_human') || n == 'verified human') {
    return ReviewStatus.verifiedHuman;
  }
  if (n.contains('confirmed_ai') || n.contains('verified_ai') || n.contains('verified ai')) {
    return ReviewStatus.confirmedAiGenerated;
  }
  if (n.contains('accepted') && n.contains('warning')) return ReviewStatus.acceptedWithWarning;
  if (n.contains('reupload')) return ReviewStatus.reuploadRequested;
  if (n.contains('reject')) return ReviewStatus.rejected;
  if (n.contains('further') || n.contains('suspicious') || n.contains('needs')) {
    return ReviewStatus.needsFurtherReview;
  }
  return ReviewStatus.pendingReview;
}

String reviewStatusToApi(ReviewStatus s) => switch (s) {
      ReviewStatus.pendingReview => 'pending_review',
      ReviewStatus.verifiedHuman => 'verified_human',
      ReviewStatus.confirmedAiGenerated => 'confirmed_ai_generated',
      ReviewStatus.needsFurtherReview => 'needs_further_review',
      ReviewStatus.acceptedWithWarning => 'accepted_with_warning',
      ReviewStatus.reuploadRequested => 'reupload_requested',
      ReviewStatus.rejected => 'rejected',
    };

Color reviewStatusColor(ReviewStatus s) => switch (s) {
      ReviewStatus.pendingReview => AdminTheme.textSecondary,
      ReviewStatus.verifiedHuman => AdminTheme.success,
      ReviewStatus.confirmedAiGenerated => const Color(0xFFEA580C),
      ReviewStatus.needsFurtherReview => AdminTheme.warning,
      ReviewStatus.acceptedWithWarning => const Color(0xFFEA580C),
      ReviewStatus.reuploadRequested => AdminTheme.accentBlue,
      ReviewStatus.rejected => AdminTheme.danger,
    };

String formatScannedDate(DateTime? dt) {
  if (dt == null) return '—';
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class AiDetectionSummary {
  const AiDetectionSummary({
    required this.totalScanned,
    required this.humanCount,
    required this.aiGeneratedCount,
    required this.suspiciousCount,
    this.pendingReviewCount = 0,
  });

  final int totalScanned;
  final int humanCount;
  final int aiGeneratedCount;
  final int suspiciousCount;
  final int pendingReviewCount;

  factory AiDetectionSummary.fromMap(Map<String, dynamic> m) => AiDetectionSummary(
        totalScanned: m['total_scanned'] as int? ?? 0,
        humanCount: m['human_count'] as int? ?? 0,
        aiGeneratedCount: m['ai_generated_count'] as int? ?? 0,
        suspiciousCount: m['suspicious_count'] as int? ?? 0,
        pendingReviewCount: m['pending_review_count'] as int? ?? 0,
      );
}
