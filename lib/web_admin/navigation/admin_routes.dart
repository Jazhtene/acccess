import 'package:flutter/material.dart';

/// Unique route ids for every admin page (used by sidebar + content router).
enum AdminRoute {
  dashboard,

  // Documentation Management
  //
  // NOTE: there is intentionally NO separate route for approve / reject. The
  // single `docRequests` page handles list, approve, AND reject inline via the
  // status filter + action buttons. Do not re-introduce per-action routes —
  // they create dead navigation paths that all point to the same page.
  docRequests,
  requestStatus,
  eventCalendar,
  taskAssignments,

  // Media Management
  mediaRepository,
  mediaEvaluation,
  aiDetection,

  // User Management
  registrationApprovals,
  members,
  roles,
  skillClassification,
  rankings,

  // Reports & Analytics
  analyticsDashboard,
  participationReports,
  feedbackReports,

  // System
  notifications,
  systemMonitor,
  branding,
}

class AdminNavLeaf {
  const AdminNavLeaf({
    required this.route,
    required this.label,
    required this.icon,
    this.subtitle,
    this.card = false,
  });

  final AdminRoute route;
  final String label;
  final IconData icon;

  /// Optional helper line shown below [label]. Only used when [card] is true.
  final String? subtitle;

  /// When true, the sidebar renders this leaf as a prominent gradient card
  /// (icon + label + subtitle) instead of the standard nav tile. Use for
  /// merged or "hero" entries like Documentation Requests.
  final bool card;
}

class AdminNavGroup {
  const AdminNavGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<AdminNavLeaf> children;
  final bool initiallyExpanded;
}

/// Grouped sidebar structure — related features under one parent menu.
const adminNavGroups = [
  AdminNavGroup(
    id: 'documentation',
    label: 'Documentation Management',
    icon: Icons.description_outlined,
    color: Color(0xFFDC2626),
    initiallyExpanded: true,
    children: [
      // Single merged entry — list, approve, and reject all happen on the
      // Documentation Requests page. Rendered as a gradient card by the
      // sidebar (see `_NavCard` in admin_sidebar.dart).
      AdminNavLeaf(
        route: AdminRoute.docRequests,
        label: 'Documentation Requests',
        subtitle: 'Approve and reject requests',
        icon: Icons.mark_email_unread_rounded,
        card: true,
      ),
      AdminNavLeaf(route: AdminRoute.requestStatus, label: 'Request Status', icon: Icons.pending_actions_outlined),
      AdminNavLeaf(route: AdminRoute.eventCalendar, label: 'Event Calendar', icon: Icons.calendar_month_outlined),
      AdminNavLeaf(route: AdminRoute.taskAssignments, label: 'Task Assignments', icon: Icons.assignment_outlined),
    ],
  ),
  AdminNavGroup(
    id: 'media',
    label: 'Media Management',
    icon: Icons.perm_media_outlined,
    color: Color(0xFF9333EA),
    children: [
      AdminNavLeaf(route: AdminRoute.mediaRepository, label: 'Gallery', icon: Icons.photo_library_outlined),
      AdminNavLeaf(route: AdminRoute.mediaEvaluation, label: 'Media Evaluation', icon: Icons.high_quality_outlined),
      AdminNavLeaf(route: AdminRoute.aiDetection, label: 'AI Detection Results', icon: Icons.smart_toy_outlined),
    ],
  ),
  AdminNavGroup(
    id: 'users',
    label: 'User Management',
    icon: Icons.people_outline,
    color: Color(0xFF7C3AED),
    children: [
      AdminNavLeaf(
        route: AdminRoute.registrationApprovals,
        label: 'Registration Approvals',
        icon: Icons.verified_user_outlined,
      ),
      AdminNavLeaf(route: AdminRoute.members, label: 'Members', icon: Icons.group_outlined),
      AdminNavLeaf(route: AdminRoute.roles, label: 'Roles', icon: Icons.admin_panel_settings_outlined),
      AdminNavLeaf(route: AdminRoute.skillClassification, label: 'Skill Classification', icon: Icons.military_tech_outlined),
      AdminNavLeaf(route: AdminRoute.rankings, label: 'Rankings', icon: Icons.leaderboard_outlined),
    ],
  ),
  AdminNavGroup(
    id: 'reports',
    label: 'Reports & Analytics',
    icon: Icons.insights_outlined,
    color: Color(0xFF6366F1),
    children: [
      AdminNavLeaf(route: AdminRoute.analyticsDashboard, label: 'Analytics Dashboard', icon: Icons.analytics_outlined),
      AdminNavLeaf(route: AdminRoute.participationReports, label: 'Participation Reports', icon: Icons.assessment_outlined),
      AdminNavLeaf(route: AdminRoute.feedbackReports, label: 'Feedback Reports', icon: Icons.forum_outlined),
    ],
  ),
  AdminNavGroup(
    id: 'system',
    label: 'System',
    icon: Icons.settings_outlined,
    color: Color(0xFF059669),
    children: [
      AdminNavLeaf(route: AdminRoute.notifications, label: 'Notifications', icon: Icons.notifications_outlined),
      AdminNavLeaf(route: AdminRoute.systemMonitor, label: 'System Monitor', icon: Icons.monitor_heart_outlined),
      AdminNavLeaf(route: AdminRoute.branding, label: 'Branding & Names', icon: Icons.branding_watermark_outlined),
    ],
  ),
];

const dashboardNavLeaf = AdminNavLeaf(
  route: AdminRoute.dashboard,
  label: 'Dashboard',
  icon: Icons.dashboard_outlined,
);

AdminNavGroup? groupContainingRoute(AdminRoute route) {
  for (final g in adminNavGroups) {
    if (g.children.any((c) => c.route == route)) return g;
  }
  return null;
}
