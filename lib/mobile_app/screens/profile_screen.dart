import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';
import 'package:access_mobile/shared/controllers/branding_controller.dart';
import 'package:access_mobile/shared/widgets/access_logo.dart';
import 'package:access_mobile/mobile_app/widgets/score_ring.dart';
import 'package:access_mobile/mobile_app/widgets/mobile_ui_kit.dart';
import 'package:access_mobile/mobile_app/widgets/stat_card.dart';
import 'package:access_mobile/mobile_app/screens/edit_profile_screen.dart';
import 'package:access_mobile/mobile_app/sheets/evaluation_detail_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) {
        final completedTasks = appState.challenges.where((c) => c.completed).length;
        final submissions = appState.evaluations.length;
        final avgScore = submissions == 0 ? 0.0
            : appState.evaluations
                .where((e) => e.score > 0)
                .fold(0.0, (s, e) => s + e.score) /
              appState.evaluations.where((e) => e.score > 0).length.clamp(1, 999);

        final skill = appState.profileBadge.label;

        return RefreshIndicator(
          color: kAccent,
          onRefresh: () => memberDataController.refreshAll(),
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(kMobilePagePadding, 8, kMobilePagePadding, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('My Profile', style: TextStyle(color: context.colors.textPrimary,
              fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            // ── Hero card ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kAccent, const Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kAccent.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(children: [
                Row(children: [
                  // Avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: appState.profileColor,
                    backgroundImage: appState.profileImageUrl != null
                        ? NetworkImage(appState.profileImageUrl!)
                        : null,
                    child: appState.profileImageUrl == null
                        ? Text(appState.profileInitials,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 22, fontWeight: FontWeight.w800))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(appState.profileName, style: const TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    _TitleBadge(),
                    const SizedBox(height: 6),
                    Text(appState.profileEmail,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                    const SizedBox(height: 4),
                    _RoleBadge(role: appState.profileTitle ?? 'ACCESS Member'),
                    const SizedBox(height: 4),
                    Text('Skill: $skill',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ])),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _HeroStat(label: 'Uploads', value: '${appState.profileUploads}'),
                  _divider(),
                  _HeroStat(label: 'Badges', value: '${appState.achievements.length}'),
                  _divider(),
                  _HeroStat(label: 'Submissions', value: '$submissions'),
                  _divider(),
                  _HeroStat(label: 'Tasks', value: '$completedTasks'),
                ]),
              ]),
            ),

            const SizedBox(height: 14),
            MobilePrimaryButton(
              label: 'Edit Profile',
              icon: Icons.edit_outlined,
              onPressed: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                if (saved == true && context.mounted) {
                  await memberDataController.refreshAll();
                }
              },
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: submissions == 0
                      ? null
                      : () => showEvaluationDetail(context, appState.evaluations.first),
                  icon: const Icon(Icons.insights_outlined, size: 18),
                  label: const Text('My Evaluations'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showMobileToast(context, 'Open Calendar tab for assigned tasks.'),
                  icon: const Icon(Icons.task_alt_outlined, size: 18),
                  label: const Text('My Tasks'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Performance ───────────────────────────────────────────────
            const AccessSectionHeader(title: 'Performance'),
            const SizedBox(height: 12),
            // Badge card — neutral surface, accent highlights only.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    appState.profileBadge.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.profileBadge.label,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appState.profileGoodEvaluations} good evals · ${_nextBadgeHint(appState.profileGoodEvaluations)}',
                        style: const TextStyle(color: kTextSecondary, fontSize: 11, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            AccessStatGrid(cards: [
              AccessStatCard(
                icon: Icons.camera_alt_rounded,
                label: 'Avg Photo Score',
                value: submissions == 0 ? '—' : '${(avgScore * 100).round()}%',
              ),
              AccessStatCard(
                icon: Icons.event_available_rounded,
                label: 'Events Covered',
                value: '${appState.evaluations.length}',
              ),
              AccessStatCard(
                icon: Icons.rate_review_rounded,
                label: 'Feedback Given',
                value: '${appState.feedbacks.length}',
              ),
              AccessStatCard(
                icon: Icons.task_alt_rounded,
                label: 'Completed Tasks',
                value: '$completedTasks',
              ),
            ]),

            // Score ring if has submissions
            if (submissions > 0 && avgScore > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: ScoreRing(score: avgScore, label: '${(avgScore * 100).round()}%'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Average Photo Score',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Based on $submissions submission${submissions > 1 ? 's' : ''}',
                          style: const TextStyle(color: kTextSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 10),
                        _ScoreBar(label: 'Composition', value: _avgMetric('composition')),
                        const SizedBox(height: 6),
                        _ScoreBar(label: 'Lighting', value: _avgMetric('lighting')),
                      ],
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            // ── Achievements ──────────────────────────────────────────────
            AccessSectionHeader(
              title: 'Achievements',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${appState.achievements.length}',
                  style: const TextStyle(
                    color: kAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (appState.achievements.isEmpty)
              const AccessEmptyCard(
                icon: Icons.workspace_premium_rounded,
                title: 'No achievements yet',
                subtitle: 'Submit and pass evaluations to earn badges.',
              )
            else
              ...appState.achievements.map((a) => _AchievementTile(a: a)),

            const SizedBox(height: 24),

            // ── Completed tasks ───────────────────────────────────────────
            const AccessSectionHeader(title: 'Completed Tasks'),
            const SizedBox(height: 12),
            if (appState.challenges.where((c) => c.completed).isEmpty)
              const AccessEmptyCard(
                icon: Icons.task_alt_rounded,
                title: 'No tasks completed yet',
                subtitle: 'Finish a documentation task to see it here.',
              )
            else
              ...appState.challenges.where((c) => c.completed).map(
                    (c) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check_rounded, color: kAccent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${c.xp} XP',
                            style: const TextStyle(
                              color: kAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  const AccessLogoImage(size: 48, circular: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brandingController.appName,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          brandingController.shortTagline,
                          style: const TextStyle(color: kTextSecondary, fontSize: 11, height: 1.35),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          brandingController.organization,
                          style: const TextStyle(color: kTextSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
        );
      },
    );
  }

  double _avgMetric(String field) {
    final scored = appState.evaluations.where((e) => e.score > 0).toList();
    if (scored.isEmpty) return 0;
    // Map label to numeric value
    double labelToVal(String l) => l == 'Excellent' ? 1.0
      : l == 'Good' ? 0.75 : l == 'Average' ? 0.5 : 0.25;
    final vals = scored.map((e) =>
      labelToVal(field == 'composition' ? e.composition : e.lighting));
    return vals.fold(0.0, (a, b) => a + b) / vals.length;
  }

  Widget _divider() => Container(width: 1, height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white.withValues(alpha: 0.15));
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: kAccent.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20)),
    child: Text(role, style: const TextStyle(color: Colors.white,
      fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _TitleBadge extends StatelessWidget {
  const _TitleBadge();

  @override
  Widget build(BuildContext context) {
    final title = appState.profileTitle;
    final scored = appState.evaluations.where((e) => e.score > 0).length;

    if (title != null) {
      // Title earned
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: kAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(title, style: const TextStyle(color: Colors.white,
            fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    // Not yet earned — show progress
    final needed = 3 - scored;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline, color: Colors.white54, size: 12),
        const SizedBox(width: 4),
        Text(
          needed > 0
            ? 'Title unlocks in $needed more eval${needed == 1 ? '' : 's'}'
            : 'Complete evaluations to earn title',
          style: const TextStyle(color: Colors.white54,
            fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10),
            ),
          ],
        ),
      );
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  const _ScoreBar({required this.label, required this.value});

  Color get _color => value >= 0.8 ? kGreen : value >= 0.6 ? kAccent : kYellow;

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 80, child: Text(label,
      style: const TextStyle(color: kTextSecondary, fontSize: 11))),
    Expanded(child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value, minHeight: 6,
        backgroundColor: kBorder,
        valueColor: AlwaysStoppedAnimation(_color)))),
    const SizedBox(width: 8),
    Text('${(value * 100).round()}%',
      style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w700)),
  ]);
}

class _AchievementTile extends StatelessWidget {
  final Achievement a;
  const _AchievementTile({required this.a});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(a.icon, color: kAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kTextSecondary, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            a.date,
            style: const TextStyle(color: kTextSecondary, fontSize: 10),
          ),
        ]),
      );
}

String _nextBadgeHint(int goodEvals) {
  if (goodEvals >= 15) return 'Max badge reached!';
  if (goodEvals >= 10) return '${15 - goodEvals} more to Master';
  if (goodEvals >= 6)  return '${10 - goodEvals} more to Expert';
  if (goodEvals >= 3)  return '${6 - goodEvals} more to Advanced';
  if (goodEvals >= 1)  return '${3 - goodEvals} more to Intermediate';
  return 'Get 1 good evaluation to earn Beginner badge';
}
