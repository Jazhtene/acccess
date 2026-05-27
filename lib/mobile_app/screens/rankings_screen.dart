import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';
import 'package:access_mobile/mobile_app/widgets/mobile_ui_kit.dart';
import 'package:access_mobile/mobile_app/widgets/stat_card.dart';

class RankingsScreen extends StatelessWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([appState, memberDataController]),
      builder: (_, __) {
        if (memberDataController.isLoading && appState.members.isEmpty) {
          return const MobileLoadingView(message: 'Loading rankings…');
        }
        if (appState.members.isEmpty) {
          return MobileEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No rankings yet',
            subtitle: 'Member rankings appear after evaluations are recorded.',
            actionLabel: 'Refresh',
            onAction: () => memberDataController.refreshAll(),
          );
        }

        final colors = context.colors;
    final members = [...appState.members]..sort((a, b) => b.goodEvaluations.compareTo(a.goodEvaluations));
    final top3 = members.length >= 3 ? members.take(3).toList() : members;

    // Badge breakdown counts
    final badges = ['Master', 'Expert', 'Advanced', 'Intermediate', 'Beginner', 'Novice'];
    final badgeColors = [kPurple, kBlue, kGreen, kYellow, const Color(0xFFCD7C2F), kTextSecondary];

    return RefreshIndicator(
      color: kAccent,
      onRefresh: () => memberDataController.refreshAll(),
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(kMobilePagePadding, 8, kMobilePagePadding, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const MobilePageTitle(
          title: 'Rankings',
          subtitle: 'Members ranked by good evaluations (score ≥ 70%).',
        ),
        const SizedBox(height: 8),
        AccessStatGrid(cards: [
          AccessStatCard(
            icon: Icons.groups_rounded,
            value: '${members.length}',
            label: 'Total Members',
            compact: true,
          ),
          AccessStatCard(
            icon: Icons.emoji_events_rounded,
            value: '${members.isNotEmpty ? members.first.goodEvaluations : 0}',
            label: 'Top Good Evals',
            compact: true,
          ),
        ]),
        const SizedBox(height: 12),

        // Badge breakdown chips
        Wrap(spacing: 8, runSpacing: 8,
          children: List.generate(badges.length, (i) {
            final count = members.where((m) => m.badge.label == badges[i]).length;
            return _BadgeChip(label: badges[i], count: count, color: badgeColors[i]);
          })),

        const SizedBox(height: 28),

        // Top 3 podium
        const AccessSectionHeader(title: 'Top 3 Members'),
        if (top3.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Podium(top3: top3),
          const SizedBox(height: 20),
        ],

        // Full leaderboard
        const AccessSectionHeader(title: 'Full Leaderboard'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: List.generate(members.length, (i) {
              final m = members[i];
              final badge = m.badge;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    SizedBox(width: 32,
                      child: Text('#${i + 1}', style: TextStyle(
                        color: i < 3 ? kAccent : kTextSecondary,
                        fontSize: 13, fontWeight: FontWeight.w700))),
                    CircleAvatar(radius: 18, backgroundColor: m.avatarColor,
                      child: Text(m.initials, style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.name, style: const TextStyle(color: kTextPrimary,
                        fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      _BadgeWidget(badge: badge),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${m.goodEvaluations}', style: const TextStyle(color: kTextPrimary,
                        fontSize: 15, fontWeight: FontWeight.w800)),
                      const Text('good evals', style: TextStyle(color: kTextSecondary, fontSize: 10)),
                      if (m.avgMediaScore > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'avg ${(m.avgMediaScore * 100).round()}%',
                          style: const TextStyle(color: kCyan, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ]),
                  ]),
                ),
                if (i < members.length - 1)
                  const Divider(height: 1, color: kBorder),
              ]);
            }),
          ),
        ),

        const SizedBox(height: 28),

        // Badge legend
        const AccessSectionHeader(title: 'Badge Guide'),
        const SizedBox(height: 12),
        _BadgeLegend(),
      ]),
    ),
    );
      },
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<Member> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();
    if (top3.length == 1) {
      final m = top3[0];
      return Column(
        children: [
          CircleAvatar(radius: 32, backgroundColor: m.avatarColor,
            child: Text(m.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${m.goodEvaluations} good evals', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        ],
      );
    }
    final padded = top3.length == 2 ? [top3[1], top3[0], top3[0]] : top3;
    final order = padded.length >= 3 ? [padded[1], padded[0], padded[2]] : padded;
    final heights = [80.0, 100.0, 60.0];
    final podiumColors = [
      const Color(0xFF94A3B8),
      const Color(0xFFF59E0B),
      const Color(0xFFCD7C2F),
    ];
    final medals = ['🥈', '🥇', '🥉'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final m = order[i];
        return Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(medals[i], style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            CircleAvatar(radius: 28, backgroundColor: m.avatarColor,
              child: Text(m.initials, style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
            const SizedBox(height: 8),
            Text(m.name, style: const TextStyle(color: kTextPrimary,
              fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
            Text('${m.goodEvaluations} good evals', style: const TextStyle(
              color: kTextSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            _BadgeWidget(badge: m.badge),
            const SizedBox(height: 8),
            Container(
              height: heights[i],
              decoration: BoxDecoration(
                color: podiumColors[i],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
              child: Center(child: Text('${[2, 1, 3][i]}',
                style: const TextStyle(color: Colors.white,
                  fontSize: 22, fontWeight: FontWeight.w800))),
            ),
          ]),
        );
      }),
    );
  }
}

// ── Badge widget ──────────────────────────────────────────────────────────────
class _BadgeWidget extends StatelessWidget {
  final BadgeInfo badge;
  const _BadgeWidget({required this.badge});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: badge.color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: badge.color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(badge.emoji, style: const TextStyle(fontSize: 10)),
      const SizedBox(width: 4),
      Text(badge.label, style: TextStyle(color: badge.color,
        fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );
}

// ── Badge breakdown chip ──────────────────────────────────────────────────────
class _BadgeChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _BadgeChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(color: color,
        fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Text('$count', style: const TextStyle(color: Colors.white,
          fontSize: 10, fontWeight: FontWeight.w700))),
    ]),
  );
}

// ── Badge legend ──────────────────────────────────────────────────────────────
class _BadgeLegend extends StatelessWidget {
  final _tiers = const [
    (15, '🟣', 'Master',       Color(0xFF6B21E8), '15+ good evaluations'),
    (10, '🔵', 'Expert',       Color(0xFF3B82F6), '10–14 good evaluations'),
    (6,  '🟢', 'Advanced',     Color(0xFF22C55E), '6–9 good evaluations'),
    (3,  '🟡', 'Intermediate', Color(0xFFF59E0B), '3–5 good evaluations'),
    (1,  '🟤', 'Beginner',     Color(0xFFCD7C2F), '1–2 good evaluations'),
    (0,  '⚪', 'Novice',       Color(0xFF94A3B8), '0 good evaluations'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder)),
    child: Column(
      children: List.generate(_tiers.length, (i) {
        final t = _tiers[i];
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Text(t.$2, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.$3, style: TextStyle(color: t.$4,
                  fontSize: 13, fontWeight: FontWeight.w700)),
                Text(t.$5, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
              ])),
            ]),
          ),
          if (i < _tiers.length - 1) const Divider(height: 1, color: kBorder),
        ]);
      }),
    ),
  );
}
