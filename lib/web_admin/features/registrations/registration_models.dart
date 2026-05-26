class MemberRegistrationRow {
  MemberRegistrationRow({
    required this.id,
    required this.fullName,
    this.studentId,
    required this.email,
    this.contactNumber,
    this.skillLevel,
    required this.status,
    this.rejectionReason,
    this.dateRegistered,
  });

  final int id;
  final String fullName;
  final String? studentId;
  final String email;
  final String? contactNumber;
  final String? skillLevel;
  final String status;
  final String? rejectionReason;
  final DateTime? dateRegistered;

  factory MemberRegistrationRow.fromMap(Map<String, dynamic> m) {
    return MemberRegistrationRow(
      id: m['user_id'] as int? ?? -1,
      fullName: m['full_name'] as String? ?? '',
      studentId: m['student_id'] as String?,
      email: m['email'] as String? ?? '',
      contactNumber: m['contact_number'] as String?,
      skillLevel: m['skill_level'] as String?,
      status: (m['status'] as String? ?? 'pending').toLowerCase(),
      rejectionReason: m['rejection_reason'] as String?,
      dateRegistered: _parseDate(m['date_registered']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

class OrganizationRegistrationRow {
  OrganizationRegistrationRow({
    required this.id,
    required this.organizationName,
    required this.organizationEmail,
    this.adviserName,
    this.contactNumber,
    required this.status,
    this.rejectionReason,
    this.dateRegistered,
  });

  final int id;
  final String organizationName;
  final String organizationEmail;
  final String? adviserName;
  final String? contactNumber;
  final String status;
  final String? rejectionReason;
  final DateTime? dateRegistered;

  factory OrganizationRegistrationRow.fromMap(Map<String, dynamic> m) {
    return OrganizationRegistrationRow(
      id: m['user_id'] as int? ?? -1,
      organizationName: m['organization_name'] as String? ?? '',
      organizationEmail: m['organization_email'] as String? ?? '',
      adviserName: m['adviser_name'] as String?,
      contactNumber: m['contact_number'] as String?,
      status: (m['status'] as String? ?? 'pending').toLowerCase(),
      rejectionReason: m['rejection_reason'] as String?,
      dateRegistered: _parseDate(m['date_registered']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

String registrationStatusLabel(String status) => switch (status.toLowerCase()) {
      'pending' => 'Pending',
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ => status,
    };
