/// ACCESS VisionCheck user roles from PostgreSQL.
enum AccessRole {
  admin,
  member,
  organization;

  static AccessRole fromApi(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AccessRole.admin;
      case 'organization':
        return AccessRole.organization;
      default:
        return AccessRole.member;
    }
  }

  String get apiValue {
    switch (this) {
      case AccessRole.admin:
        return 'Admin';
      case AccessRole.organization:
        return 'Organization';
      case AccessRole.member:
        return 'Member';
    }
  }

  bool get isAdmin => this == AccessRole.admin;
  bool get isMember => this == AccessRole.member;
  bool get isOrganization => this == AccessRole.organization;
}

class AuthUser {
  final int id;
  final String name;
  final String email;
  final AccessRole role;
  final String token;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json, String token) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: AccessRole.fromApi(json['role'] as String? ?? 'Member'),
      token: token,
    );
  }
}
