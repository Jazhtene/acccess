import 'package:access_mobile/web_admin/features/members/member_models.dart';
import 'package:access_mobile/web_admin/features/member_rankings/member_ranking_models.dart';

String membersCsvReport(List<AdminMemberRow> rows) {
  final buf = StringBuffer(
    'Member Name,Email,Role,Status,Skill Level,Assigned Tasks,Completed Tasks,Media Score,Last Active,Task Role\n',
  );
  for (final r in rows) {
    buf.writeln(
      '"${r.name}","${r.email}","${r.role}","${r.status}","${r.skillLevel ?? ""}",'
      '"${r.assignedLabel}","${r.completedTasks}","${r.mediaScoreLabel}",'
      '"${formatLastActivity(r.lastActive)}","${r.primaryTaskRole ?? ""}"',
    );
  }
  return buf.toString();
}

String skillClassificationCsvReport(List<AdminMemberRow> rows) {
  final buf = StringBuffer('Skill Level,Member Name,Email,Media Evaluation Score,Assigned Tasks\n');
  final sorted = List<AdminMemberRow>.from(rows)
    ..sort((a, b) => (b.skillLevel ?? '').compareTo(a.skillLevel ?? ''));
  for (final r in sorted) {
    if (r.role.toLowerCase() != 'member') continue;
    buf.writeln(
      '"${r.skillLevel ?? "Unclassified"}","${r.name}","${r.email}",'
      '"${r.mediaScoreLabel}","${r.assignedLabel}"',
    );
  }
  return buf.toString();
}

String membersPrintableReport(List<AdminMemberRow> rows, {required String title}) {
  final buf = StringBuffer('$title\nGenerated: ${DateTime.now().toLocal()}\n\n');
  for (final r in rows) {
    buf.writeln('${r.name} <${r.email}>');
    buf.writeln('  Role: ${r.role} | Status: ${r.status} | Skill: ${r.skillLevel ?? "—"}');
    buf.writeln('  Media score: ${r.mediaScoreLabel} | Tasks: ${r.assignedLabel}');
    buf.writeln('  Last active: ${formatLastActivity(r.lastActive)}\n');
  }
  return buf.toString();
}
