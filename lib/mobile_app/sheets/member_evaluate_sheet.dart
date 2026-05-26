import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:access_mobile/mobile_app/widgets/score_ring.dart';
import 'package:access_mobile/shared/api/gemini_service.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';
import 'package:access_mobile/shared/models/photo_evaluation_result.dart' hide AiDetectionResult;
import 'package:access_mobile/shared/models/photo_evaluation_result.dart' as eval_models show AiDetectionResult;
import 'package:access_mobile/shared/services/image_evaluation_service.dart';
import 'package:access_mobile/shared/services/image_validation_service.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/web_admin/services/file_picker_service.dart';

void showMemberEvaluateSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const MemberEvaluateSheet(),
  );
}

class _PickedImage {
  _PickedImage(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

enum _EvalPhase { idle, validating, analyzing, generating }

class MemberEvaluateSheet extends StatefulWidget {
  const MemberEvaluateSheet({super.key});

  @override
  State<MemberEvaluateSheet> createState() => _MemberEvaluateSheetState();
}

class _MemberEvaluateSheetState extends State<MemberEvaluateSheet> {
  final _picker = ImagePicker();
  final List<_PickedImage> _images = [];
  _EvalPhase _phase = _EvalPhase.idle;
  String _progressText = '';
  PhotoEvaluationResult? _result;
  String? _hardError;
  List<String> _qualityWarnings = const [];

  Future<void> _pickGallery() async {
    if (kIsWeb) {
      final picked = await pickImagesFromWeb();
      if (picked.isNotEmpty) {
        setState(() {
          _images
            ..clear()
            ..add(_PickedImage(picked.first.name, picked.first.bytes));
          _result = null;
          _hardError = null;
          _qualityWarnings = const [];
        });
      }
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _images
        ..clear()
        ..add(_PickedImage(picked.name, bytes));
      _result = null;
      _hardError = null;
      _qualityWarnings = const [];
    });
  }

  Future<void> _pickCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _images
        ..clear()
        ..add(_PickedImage(picked.name, bytes));
      _result = null;
      _hardError = null;
      _qualityWarnings = const [];
    });
  }

  Future<void> _runEvaluation() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload or capture a photo first'),
        backgroundColor: kRed,
      ));
      return;
    }

    final img = _images.first;
    setState(() {
      _phase = _EvalPhase.validating;
      _progressText = 'Checking image quality...';
      _result = null;
      _hardError = null;
      _qualityWarnings = const [];
    });

    final validation = await ImageValidationService.validate(
      bytes: img.bytes,
      fileName: img.name,
    );
    if (!mounted) return;
    if (!validation.isValid) {
      setState(() {
        _phase = _EvalPhase.idle;
        _hardError = validation.hardReject
            ? ImageValidationResult.hardRejectMessage
            : validation.message;
      });
      return;
    }

    final warnings = validation.qualityWarnings;

    setState(() {
      _phase = _EvalPhase.analyzing;
      _progressText = 'Analyzing photo...';
      _qualityWarnings = warnings;
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final evaluated = ImageEvaluationService.evaluate(
      bytes: img.bytes,
      qualityWarnings: warnings,
    );
    if (evaluated == null) {
      setState(() {
        _phase = _EvalPhase.idle;
        _hardError = ImageValidationResult.hardRejectMessage;
      });
      return;
    }

    setState(() {
      _phase = _EvalPhase.generating;
      _progressText = 'Generating evaluation...';
    });

    final scores = {for (final c in evaluated.criteria) c.name: c.score};
    final gemini = await GeminiService.generateFeedback(
      scores: scores,
      title: 'ACCESS Event Documentation',
      totalScore: evaluated.criteria.fold<int>(0, (s, c) => s + c.score),
      maxScore: evaluated.criteria.length * 5,
    );

    if (!mounted) return;
    final feedback = gemini ?? evaluated.feedback;
    setState(() {
      _phase = _EvalPhase.idle;
      _result = PhotoEvaluationResult(
        criteria: evaluated.criteria,
        overallScore: evaluated.overallScore,
        qualityLevel: evaluated.qualityLevel,
        feedback: feedback,
        improvementSuggestions: evaluated.improvementSuggestions,
        recommendation: evaluated.recommendation,
        aiDetection: evaluated.aiDetection,
      );
    });
  }

  Future<void> _save() async {
    if (_result == null || _images.isEmpty) return;

    if (appState.evaluationsTodayCount >= AppState.dailyEvaluationLimit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Daily limit reached — you can submit 2 evaluations per day.'),
        backgroundColor: kRed,
      ));
      return;
    }

    final requestId = memberDataController.defaultRequestId;
    if (requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No assigned documentation request. Contact admin.'),
        backgroundColor: kRed,
      ));
      return;
    }

    try {
      final metadata = jsonEncode(_result!.toJson());
      await memberDataController.uploadMedia(
        bytes: _images.first.bytes,
        fileName: _images.first.name,
        requestId: requestId,
        title: 'Photo Submission',
        evaluationMetadata: metadata,
      );
      if (!mounted) return;
      Navigator.pop(context);
      final remaining = AppState.dailyEvaluationLimit - appState.evaluationsTodayCount;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Uploaded and evaluated. '
          '$remaining submission${remaining == 1 ? '' : 's'} remaining today.',
        ),
        backgroundColor: kGreen,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Evaluation failed. Please try again.\n$e'),
        backgroundColor: kRed,
      ));
    }
  }

  bool get _busy =>
      _phase == _EvalPhase.validating ||
      _phase == _EvalPhase.analyzing ||
      _phase == _EvalPhase.generating;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.97,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Evaluate Photo',
              style: TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload one event photo. We validate quality before scoring.',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),
            if (kIsWeb)
              _actionBtn(Icons.upload_file_outlined, 'Select Photo', _pickGallery)
            else
              Row(
                children: [
                  Expanded(child: _actionBtn(Icons.photo_library_outlined, 'Gallery', _pickGallery)),
                  const SizedBox(width: 10),
                  Expanded(child: _actionBtn(Icons.camera_alt_outlined, 'Camera', _pickCamera)),
                ],
              ),
            const SizedBox(height: 14),
            if (_images.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.memory(_images.first.bytes, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _images.clear();
                          _result = null;
                          _hardError = null;
      _qualityWarnings = const [];
                        }),
                  child: const Text('Remove photo', style: TextStyle(color: kRed, fontSize: 12)),
                ),
              ),
            ] else
              GestureDetector(
                onTap: _busy ? null : _pickGallery,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: kSurfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kAccent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: kAccent, size: 32),
                      SizedBox(height: 8),
                      Text('Tap to upload or capture', style: TextStyle(color: kAccent, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            if (_hardError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kRed.withValues(alpha: 0.35)),
                ),
                child: Text(_hardError!, style: const TextStyle(color: kRed, fontSize: 12, height: 1.4)),
              ),
            ],
            const SizedBox(height: 14),
            if (_result == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _busy ? null : _runEvaluation,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    _busy ? _progressText : 'Validate & Evaluate',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            if (_result != null) ...[
              _EvaluationResultCard(
                result: _result!,
                preview: _images.first.bytes,
                qualityWarnings: _qualityWarnings,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _result = null;
                        _hardError = null;
      _qualityWarnings = const [];
                      }),
                      child: const Text('Re-evaluate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _save,
                      child: const Text('Save Result', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kSurfaceAlt,
          foregroundColor: kAccent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: kBorder),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _EvaluationResultCard extends StatelessWidget {
  const _EvaluationResultCard({
    required this.result,
    required this.preview,
    this.qualityWarnings = const [],
  });

  final PhotoEvaluationResult result;
  final Uint8List preview;
  final List<String> qualityWarnings;

  Color _levelColor(String level) => switch (level) {
        'Excellent' => kGreen,
        'Good' => kAccent,
        'Fair' => kYellow,
        _ => kRed,
      };

  @override
  Widget build(BuildContext context) {
    final ringScore = result.overallScore / 5;
    final levelColor = _levelColor(result.qualityLevel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: ScoreRing(score: ringScore, label: '${result.overallScore.toStringAsFixed(1)}/5'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _badge(result.qualityLevel, levelColor),
                    const SizedBox(height: 6),
                    Text(
                      'Recommendation: ${result.recommendation}',
                      style: const TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(preview, height: 100, width: double.infinity, fit: BoxFit.cover),
          ),
          if (qualityWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kYellow.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ImageValidationResult.acceptedWithIssuesMessage,
                    style: const TextStyle(color: kTextPrimary, fontSize: 11, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  ...qualityWarnings.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• $w', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _aiBanner(result.aiDetection),
          const SizedBox(height: 12),
          const Text(
            'CRITERIA BREAKDOWN',
            style: TextStyle(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          ...result.criteria.map((c) => _criterionTile(c)),
          const Divider(color: kBorder, height: 24),
          const Text('AI Feedback', style: TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(result.feedback, style: const TextStyle(color: kTextSecondary, fontSize: 12, height: 1.5)),
          if (result.improvementSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Suggested improvements', style: TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              result.improvementSuggestions,
              style: const TextStyle(color: kTextSecondary, fontSize: 12, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  Widget _aiBanner(eval_models.AiDetectionResult ai) {
    final color = ai.isSuspicious ? kYellow : kGreen;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ai.isSuspicious ? 'AI detection: Review advised' : 'AI detection: No block',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(ai.detail, style: const TextStyle(color: kTextSecondary, fontSize: 11, height: 1.35)),
        ],
      ),
    );
  }

  Widget _criterionTile(CriterionScore c) {
    final color = c.score >= 4 ? kGreen : c.score == 3 ? kAccent : kYellow;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.name,
                  style: const TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: i < c.score ? color : kBorder,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${c.score}/5 ${c.label}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 3),
          Text(c.explanation, style: const TextStyle(color: kTextSecondary, fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }
}
