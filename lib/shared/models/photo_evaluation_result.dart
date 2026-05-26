/// Structured photo evaluation result (1–5 per criterion).
class CriterionScore {
  const CriterionScore({
    required this.name,
    required this.score,
    required this.explanation,
    required this.suggestion,
  });

  final String name;
  final int score;
  final String explanation;
  final String suggestion;

  String get label => scoreLabel(score);

  static String scoreLabel(int score) => switch (score) {
        5 => 'Excellent',
        4 => 'Good',
        3 => 'Fair',
        2 => 'Needs Improvement',
        _ => 'Poor',
      };

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'label': label,
        'explanation': explanation,
        'suggestion': suggestion,
      };

  factory CriterionScore.fromJson(Map<String, dynamic> j) => CriterionScore(
        name: j['name'] as String? ?? '',
        score: (j['score'] as num?)?.round().clamp(1, 5) ?? 3,
        explanation: j['explanation'] as String? ?? '',
        suggestion: j['suggestion'] as String? ?? '',
      );
}

class AiDetectionResult {
  const AiDetectionResult({
    required this.verdict,
    required this.confidence,
    required this.detail,
  });

  final String verdict;
  final double confidence;
  final String detail;

  bool get isSuspicious => verdict == 'suspicious';
  bool get isBlocked => false;

  Map<String, dynamic> toJson() => {
        'verdict': verdict,
        'confidence': confidence,
        'detail': detail,
      };
}

class PhotoEvaluationResult {
  const PhotoEvaluationResult({
    required this.criteria,
    required this.overallScore,
    required this.qualityLevel,
    required this.feedback,
    required this.improvementSuggestions,
    required this.recommendation,
    required this.aiDetection,
  });

  final List<CriterionScore> criteria;
  final double overallScore;
  final String qualityLevel;
  final String feedback;
  final String improvementSuggestions;
  final String recommendation;
  final AiDetectionResult aiDetection;

  int get overallPercent => ((overallScore / 5) * 100).round().clamp(0, 100);

  Map<String, dynamic> toJson() {
    final byName = {for (final c in criteria) c.name: c.score};
    int s(String name) => byName[name] ?? 3;
    return {
      'criteria': criteria.map((c) => c.toJson()).toList(),
      'overall_score': overallScore,
      'quality_level': qualityLevel,
      'ai_feedback': feedback,
      'improvement_suggestions': improvementSuggestions,
      'recommendation': recommendation,
      'ai_detection': aiDetection.toJson(),
      'composition_score': s('Composition and Framing'),
      'lighting_score': s('Lighting and Exposure'),
      'focus_score': s('Focus and Sharpness'),
      'color_score': s('Color and White Balance'),
      'subject_clarity_score': s('Subject Clarity'),
      'creativity_score': s('Creativity and Storytelling'),
      'relevance_score': s('Relevance to Event Theme'),
      'technical_quality_score': s('Technical Quality'),
      'documentation_value_score': s('Overall Documentation Value'),
      'legacy': {
        'sharpness_score': s('Focus and Sharpness') / 5,
        'brightness_score': s('Lighting and Exposure') / 5,
        'contrast_score': s('Color and White Balance') / 5,
        'blur_score': s('Focus and Sharpness') / 5,
        'noise_score': 1 - s('Technical Quality') / 5,
        'overall_score': overallScore / 5,
      },
    };
  }

  static PhotoEvaluationResult? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final raw = j['criteria'];
    final list = raw is List
        ? raw.map((e) => CriterionScore.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : <CriterionScore>[];
    final ai = j['ai_detection'];
    return PhotoEvaluationResult(
      criteria: list,
      overallScore: (j['overall_score'] as num?)?.toDouble() ?? 3,
      qualityLevel: j['quality_level'] as String? ?? 'Fair',
      feedback: j['ai_feedback'] as String? ?? j['feedback'] as String? ?? '',
      improvementSuggestions: j['improvement_suggestions'] as String? ?? '',
      recommendation: j['recommendation'] as String? ?? 'Needs Improvement',
      aiDetection: ai is Map
          ? AiDetectionResult(
              verdict: ai['verdict'] as String? ?? 'authentic',
              confidence: (ai['confidence'] as num?)?.toDouble() ?? 0.85,
              detail: ai['detail'] as String? ?? '',
            )
          : const AiDetectionResult(
              verdict: 'authentic',
              confidence: 0.85,
              detail: 'No AI-generation artifacts detected.',
            ),
    );
  }
}

class ImageValidationResult {
  const ImageValidationResult({
    required this.isValid,
    required this.message,
    this.issues = const [],
    this.qualityWarnings = const [],
    this.hardReject = false,
  });

  final bool isValid;
  final String message;
  final List<String> issues;
  /// Non-blocking hints (blur, lighting, etc.) — evaluation still runs.
  final List<String> qualityWarnings;
  /// True only for corrupt / unreadable / blank files.
  final bool hardReject;

  static const hardRejectMessage =
      'This file cannot be evaluated because it is not a valid or readable image.';

  static const acceptedWithIssuesMessage =
      'This image was accepted for evaluation, but some quality issues were detected. '
      'Please review the suggestions below.';

  factory ImageValidationResult.accepted({List<String> qualityWarnings = const []}) =>
      ImageValidationResult(
        isValid: true,
        message: qualityWarnings.isEmpty ? 'Image ready for evaluation.' : acceptedWithIssuesMessage,
        qualityWarnings: qualityWarnings,
      );

  factory ImageValidationResult.hardReject([List<String>? issues]) => ImageValidationResult(
        isValid: false,
        hardReject: true,
        message: hardRejectMessage,
        issues: issues ?? const [],
      );
}
