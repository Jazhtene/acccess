import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/auth_controller.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';
import 'package:access_mobile/mobile_app/widgets/score_ring.dart';
import 'package:access_mobile/mobile_app/widgets/shared_widgets.dart';
import 'package:access_mobile/mobile_app/widgets/mobile_ui_kit.dart';
import 'package:access_mobile/mobile_app/widgets/stat_card.dart';
import 'package:access_mobile/mobile_app/sheets/evaluation_detail_sheet.dart';

/// Dashboard spacing + card contract (matches [kAccessCardRadius]).
const _kSectionGap = 16.0;
const _kCardPad = 16.0;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([appState, memberDataController]),
      builder: (_, __) {
        if (memberDataController.isLoading && appState.evaluations.isEmpty) {
          return const MobileLoadingView(message: 'Loading your dashboard…');
        }
        final colors = context.colors;
        return RefreshIndicator(
          color: kAccent,
          backgroundColor: colors.surface,
          onRefresh: () => memberDataController.refreshAll(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              kMobilePagePadding,
              12,
              kMobilePagePadding,
              28,
            ),
            children: [
              const MobilePageTitle(
                title: 'Dashboard',
                subtitle: 'Your activity, submissions, and performance at a glance.',
              ),
              const SizedBox(height: 8),
              _SystemStatusChip(),
              const SizedBox(height: _kSectionGap),
              _WelcomeSection(),
              const SizedBox(height: _kSectionGap),
              _MemberRoleCard(),
              const SizedBox(height: _kSectionGap),
              _StatsSection(),
              const SizedBox(height: 20),
              const AccessSectionHeader(title: 'Latest Submission'),
              const SizedBox(height: 12),
              _LatestSubmissionCard(
                onOpenDetail: (ev) => showEvaluationDetail(context, ev),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  const _DashCard({required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(_kCardPad),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(kAccessCardRadius),
        border: Border.all(color: colors.border.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kAccessCardRadius),
        child: content,
      ),
    );
  }
}

// ── Sections ──────────────────────────────────────────────────────────────────

class _SystemStatusChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGreen.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 7,
            height: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'SYSTEM STATUS: ACTIVE',
            style: TextStyle(
              color: kGreen,
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fallbackName = authController.user?.name ?? '';
    final fullName = appState.profileName.trim().isNotEmpty
        ? appState.profileName
        : fallbackName;
    final first = fullName.split(' ').first;
    final greetName = first.isEmpty ? 'there' : first;
    final pending = appState.evaluations.where((e) => e.isPending).length;
    final title = appState.profileTitle;

    return _DashCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            greetName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title != null
                ? 'Your title: $title.${pending > 0 ? ' $pending submission${pending > 1 ? 's' : ''} pending review.' : ' All submissions reviewed.'}'
                : 'Complete evaluations to earn your photographer title.${pending > 0 ? ' $pending pending review.' : ''}',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRoleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final role = appState.profileTitle ?? 'ACCESS Member';

    Widget activeBadge() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kGreen.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 6,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle),
                ),
              ),
              SizedBox(width: 6),
              Text(
                'ACTIVE',
                style: TextStyle(
                  color: kGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 340;
        return _DashCard(
          child: Row(
            crossAxisAlignment:
                narrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: kAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEMBER ROLE',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      maxLines: narrow ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (narrow) ...[
                      const SizedBox(height: 10),
                      activeBadge(),
                    ],
                  ],
                ),
              ),
              if (!narrow) ...[
                const SizedBox(width: 8),
                activeBadge(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final submissions = appState.evaluations.length;
    final scored = appState.evaluations.where((e) => e.score > 0).toList();
    final avgScore = scored.isEmpty
        ? 0.0
        : scored.fold(0.0, (s, e) => s + e.score) / scored.length;
    final pending = appState.evaluations.where((e) => e.isPending).length;
    final tasksDone = appState.challenges.where((c) => c.completed).length;

    return AccessStatGrid(
      spacing: 12,
      cards: [
        AccessStatCard(
          dashboardLayout: true,
          icon: Icons.cloud_upload_rounded,
          value: '$submissions',
          label: 'Submissions',
        ),
        AccessStatCard(
          dashboardLayout: true,
          icon: Icons.camera_alt_rounded,
          value: scored.isEmpty ? '—' : '${(avgScore * 100).round()}%',
          label: 'Avg Score',
        ),
        AccessStatCard(
          dashboardLayout: true,
          icon: Icons.auto_awesome_rounded,
          value: '$pending',
          label: 'Pending Review',
        ),
        AccessStatCard(
          dashboardLayout: true,
          icon: Icons.task_alt_rounded,
          value: '$tasksDone',
          label: 'Tasks Done',
        ),
      ],
    );
  }
}

class _LatestSubmissionCard extends StatelessWidget {
  const _LatestSubmissionCard({required this.onOpenDetail});

  final void Function(Evaluation ev) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (appState.evaluations.isEmpty) {
      return _EmptyLatestSubmission();
    }
    return _LatestSubmissionBody(
      evaluation: appState.evaluations.first,
      onOpenDetail: onOpenDetail,
    );
  }
}

class _EmptyLatestSubmission extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _DashCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.photo_camera_rounded, color: kAccent, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            'No submissions yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload from Gallery or start an evaluation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => memberDataController.refreshAll(),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: kAccent),
            label: const Text('Refresh', style: TextStyle(color: kAccent)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kAccent.withValues(alpha: 0.6)),
              minimumSize: const Size(0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestSubmissionBody extends StatelessWidget {
  const _LatestSubmissionBody({
    required this.evaluation,
    required this.onOpenDetail,
  });

  final Evaluation evaluation;
  final void Function(Evaluation ev) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ev = evaluation;
    final pct = (ev.score * 100).round();
    final qualityLabel = ev.isPending
        ? 'Pending evaluation'
        : ev.score >= 0.7
            ? 'Meets standards'
            : 'Needs improvement';
    final statusColor = ev.isPending ? kYellow : (ev.score >= 0.7 ? kGreen : kOrange);

    return _DashCard(
      onTap: () => onOpenDetail(ev),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: kAccent,
                  size: 24,
                ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ev.date.isNotEmpty ? ev.date : 'Recent upload',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MediaIdBadge(id: ev.id),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
                size: 22,
              ),
            ],
          ),
          if (ev.imageUrl != null && ev.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ev.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: ev.isPending
                ? Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: kYellow.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kYellow.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'PENDING',
                        style: TextStyle(
                          color: kYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                : ScoreRing(score: ev.score, label: '$pct%'),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Photo quality score',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: colors.border.withValues(alpha: 0.7), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Overall quality',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  qualityLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 320;
              final chips = [
                MetricChip(label: 'COMPOSITION', value: ev.composition),
                MetricChip(label: 'LIGHTING', value: ev.lighting),
                MetricChip(label: 'SHARPNESS', value: ev.sharpness),
                MetricChip(label: 'OVERALL', value: ev.isPending ? '—' : '$pct%'),
              ];
              if (narrow) {
                return Column(
                  children: chips
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(width: double.infinity, child: c),
                          ))
                      .toList(),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips,
              );
            },
          ),
          if (ev.feedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '"${ev.feedback}"',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          MobilePrimaryButton(
            label: 'View Evaluation Details',
            icon: Icons.insights_rounded,
            onPressed: () => onOpenDetail(ev),
          ),
        ],
      ),
    );
  }
}

class _MediaIdBadge extends StatelessWidget {
  const _MediaIdBadge({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        id,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
