import 'package:access_mobile/web_admin/features/member_rankings/member_ranking_models.dart';

enum MemberListFilter {
  all,
  activeMembers,
  removed,
  active,
  inactive,
  pending,
  organization,
  beginner,
  intermediate,
  advanced,
  photographer,
  videographer,
  editor,
}

enum MemberSortColumn { name, skillLevel, mediaScore, status, lastActive }

class AdminMemberRow {
  AdminMemberRow({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.isActiveAccount = true,
    this.removedAt,
    this.removedByName,
    this.studentId,
    this.skillLevel,
    this.assignedTasks = 0,
    this.completedTasks = 0,
    this.mediaEvalScore = 0,
    this.lastActive,
    this.primaryTaskRole,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final bool isActiveAccount;
  final DateTime? removedAt;
  final String? removedByName;
  final String? studentId;
  final String? skillLevel;
  final int assignedTasks;
  final int completedTasks;
  final double mediaEvalScore;
  final DateTime? lastActive;
  final String? primaryTaskRole;

  factory AdminMemberRow.fromMap(Map<String, dynamic> m) {
    return AdminMemberRow(
      id: m['user_id'] as int? ?? -1,
      name: m['name'] as String? ?? '',
      email: m['email'] as String? ?? '',
      role: m['role'] as String? ?? 'Member',
      status: (m['status'] as String? ?? 'pending').toLowerCase(),
      isActiveAccount: m['is_active'] as bool? ?? true,
      removedAt: _parseDate(m['removed_at']),
      removedByName: m['removed_by_name'] as String?,
      studentId: m['student_id'] as String?,
      skillLevel: m['skill_level'] as String?,
      assignedTasks: m['assigned_tasks'] as int? ?? 0,
      completedTasks: m['completed_tasks'] as int? ?? 0,
      mediaEvalScore: (m['media_eval_score'] as num?)?.toDouble() ??
          (m['avg_score'] as num?)?.toDouble() ??
          0,
      lastActive: _parseDate(m['last_active'] ?? m['created_at']),
      primaryTaskRole: m['primary_task_role'] as String?,
    );
  }

  SkillLevelTier get skillTier {
    final raw = skillLevel ?? '';
    if (raw.toLowerCase().contains('novice')) return SkillLevelTier.beginner;
    return skillLevelFromString(raw.isEmpty ? 'Beginner' : raw);
  }

  String get assignedLabel =>
      assignedTasks == 0 ? '—' : '$completedTasks / $assignedTasks';

  String get mediaScoreLabel =>
      mediaEvalScore > 0 ? '${mediaEvalScore.round()}%' : '—';

  bool get isPending => status == 'pending';
  bool get isActive => status == 'approved' && isActiveAccount;
  bool get isInactive => status == 'rejected' || status == 'inactive';
  bool get isRemoved => !isActiveAccount;
  bool get isMemberRole => role.toLowerCase() == 'member';

  AdminMemberRow copyWith({String? status, String? role, bool? isActiveAccount}) => AdminMemberRow(
        id: id,
        name: name,
        email: email,
        role: role ?? this.role,
        status: status ?? this.status,
        isActiveAccount: isActiveAccount ?? this.isActiveAccount,
        removedAt: removedAt,
        removedByName: removedByName,
        studentId: studentId,
        skillLevel: skillLevel,
        assignedTasks: assignedTasks,
        completedTasks: completedTasks,
        mediaEvalScore: mediaEvalScore,
        lastActive: lastActive,
        primaryTaskRole: primaryTaskRole,
      );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  bool matchesFilter(MemberListFilter filter) {
    return switch (filter) {
      MemberListFilter.all => isActiveAccount,
      MemberListFilter.activeMembers => isMemberRole && isActiveAccount && isActive,
      MemberListFilter.removed => isMemberRole && isRemoved,
      MemberListFilter.active => isActive,
      MemberListFilter.inactive => isInactive,
      MemberListFilter.pending => isPending && isActiveAccount,
      MemberListFilter.organization =>
        role.toLowerCase() == 'organization' && isActive,
      MemberListFilter.beginner =>
        skillTier == SkillLevelTier.beginner || (skillLevel?.toLowerCase().contains('novice') ?? false),
      MemberListFilter.intermediate => skillTier == SkillLevelTier.intermediate,
      MemberListFilter.advanced =>
        skillTier == SkillLevelTier.advanced || skillTier == SkillLevelTier.expert,
      MemberListFilter.photographer =>
        (primaryTaskRole ?? '').toLowerCase().contains('photo'),
      MemberListFilter.videographer =>
        (primaryTaskRole ?? '').toLowerCase().contains('video'),
      MemberListFilter.editor => (primaryTaskRole ?? '').toLowerCase().contains('edit'),
    };
  }
}

List<AdminMemberRow> sortMembers(List<AdminMemberRow> rows, MemberSortColumn col, bool asc) {
  final list = List<AdminMemberRow>.from(rows);
  int cmp<T extends Comparable>(T a, T b) => asc ? a.compareTo(b) : b.compareTo(a);

  list.sort((a, b) {
    return switch (col) {
      MemberSortColumn.name => cmp(a.name.toLowerCase(), b.name.toLowerCase()),
      MemberSortColumn.skillLevel => cmp(a.skillLevel ?? '', b.skillLevel ?? ''),
      MemberSortColumn.mediaScore => cmp(a.mediaEvalScore, b.mediaEvalScore),
      MemberSortColumn.status => cmp(a.status, b.status),
      MemberSortColumn.lastActive => cmp(
          a.lastActive?.millisecondsSinceEpoch ?? 0,
          b.lastActive?.millisecondsSinceEpoch ?? 0,
        ),
    };
  });
  return list;
}

String memberFilterLabel(MemberListFilter f) => switch (f) {
      MemberListFilter.all => 'All Active',
      MemberListFilter.activeMembers => 'Active Members',
      MemberListFilter.removed => 'Removed Members',
      MemberListFilter.active => 'Approved',
      MemberListFilter.inactive => 'Inactive',
      MemberListFilter.pending => 'Pending Approval',
      MemberListFilter.organization => 'Organizations',
      MemberListFilter.beginner => 'Beginner',
      MemberListFilter.intermediate => 'Intermediate',
      MemberListFilter.advanced => 'Advanced',
      MemberListFilter.photographer => 'Photographer',
      MemberListFilter.videographer => 'Videographer',
      MemberListFilter.editor => 'Editor',
    };
