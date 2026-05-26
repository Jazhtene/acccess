import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';
import 'package:access_mobile/mobile_app/widgets/score_ring.dart';
import 'package:access_mobile/mobile_app/widgets/shared_widgets.dart';
import 'package:access_mobile/mobile_app/sheets/evaluation_detail_sheet.dart';
import 'package:access_mobile/mobile_app/sheets/member_evaluate_sheet.dart';
import 'package:access_mobile/mobile_app/widgets/mobile_ui_kit.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'High Score', 'Needs Improvement', 'Pending Evaluation'];

  List<Evaluation> get _filtered {
    final list = appState.evaluations;
    switch (_filter) {
      case 'High Score':
        return list.where((e) => e.score >= 0.7).toList();
      case 'Needs Improvement':
        return list.where((e) => e.score > 0 && e.score < 0.7).toList();
      case 'Pending Evaluation':
        return list.where((e) => e.isPending).toList();
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final atLimit = appState.evaluationsTodayCount >= AppState.dailyEvaluationLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MobilePageTitle(
          title: 'Evaluations',
          subtitle: 'Photo submissions with AI quality scores and feedback.',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(kMobilePagePadding, 0, kMobilePagePadding, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: atLimit ? kTextSecondary : kAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: atLimit
                  ? () => showMobileToast(context, 'Daily limit reached — 2 evaluations per day.', success: false)
                  : () => _showEvaluateSheet(context),
              icon: Icon(atLimit ? Icons.block : Icons.photo_camera_outlined, size: 18),
              label: Text(
                atLimit
                    ? 'Limit reached (${appState.evaluationsTodayCount}/${AppState.dailyEvaluationLimit})'
                    : 'Evaluate photos (${appState.evaluationsTodayCount}/${AppState.dailyEvaluationLimit})',
              ),
            ),
          ),
        ),
        MobileFilterChips(
          filters: _filters,
          selected: _filter,
          onSelected: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([appState, memberDataController]),
            builder: (_, __) {
              if (memberDataController.isLoading && appState.evaluations.isEmpty) {
                return const MobileLoadingView(message: 'Loading evaluations…');
              }
              if (appState.memberSyncError != null && appState.evaluations.isEmpty) {
                return MobileErrorState(
                  message: appState.memberSyncError!,
                  onRetry: () => memberDataController.refreshAll(),
                );
              }
              if (_filtered.isEmpty) {
                return MobileEmptyState(
                  icon: Icons.photo_camera_outlined,
                  title: _filter == 'All' ? 'No submissions yet' : 'No matches for "$_filter"',
                  subtitle: _filter == 'All'
                      ? 'Tap Evaluate photos to submit your first submission.'
                      : 'Try another filter or submit new media.',
                  actionLabel: _filter == 'All' ? 'Evaluate photos' : null,
                  onAction: _filter == 'All' ? () => _showEvaluateSheet(context) : null,
                );
              }
              return RefreshIndicator(
                color: kAccent,
                onRefresh: () => memberDataController.refreshAll(),
                child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(kMobilePagePadding, 4, kMobilePagePadding, 24),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _EvaluationCard(
                  ev: _filtered[i],
                  onTap: () => showEvaluationDetail(context, _filtered[i]),
                ),
              ),
              );
            },
          ),
        ),
      ],
    );
  }
}

void _showEvaluateSheet(BuildContext context) => showMemberEvaluateSheet(context);

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.ev, required this.onTap});

  final Evaluation ev;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = (ev.score * 100).round();
    final feedbackColor = ev.feedbackStatus == 'Ready' ? kGreen : kYellow;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ev.isPending
                      ? Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: kYellow.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: kYellow.withValues(alpha: 0.5), width: 2),
                          ),
                          child: const Center(
                            child: Text('—', style: TextStyle(color: kYellow, fontWeight: FontWeight.w800)),
                          ),
                        )
                      : SizedBox(
                          width: 56,
                          height: 56,
                          child: ScoreRing(score: ev.score, label: '$pct%'),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ev.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ev.date,
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: feedbackColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Feedback: ${ev.feedbackStatus}',
                            style: TextStyle(color: feedbackColor, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  MetricChip(label: 'COMPOSITION', value: ev.composition),
                  MetricChip(label: 'LIGHTING', value: ev.lighting),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: kAccent,
                    side: const BorderSide(color: kAccent),
                  ),
                  child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
