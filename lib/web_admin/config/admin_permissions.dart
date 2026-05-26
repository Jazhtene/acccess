import 'package:access_mobile/shared/models/user_model.dart';

/// Capabilities for role-based admin UI visibility.
enum AdminCapability {
  deleteRecords,
  exportData,
  approveMembers,
  manageRoles,
  addRemarks,
  reviewMedia,
  archiveRecords,
}

extension AdminRolePermissions on AccessRole {
  bool can(AdminCapability capability) {
    switch (this) {
      case AccessRole.admin:
        return true;
      case AccessRole.organization:
        return switch (capability) {
          AdminCapability.deleteRecords => false,
          AdminCapability.manageRoles => false,
          AdminCapability.approveMembers => false,
          _ => true,
        };
      case AccessRole.member:
        return false;
    }
  }

  String get displayLabel => switch (this) {
        AccessRole.admin => 'System Administrator',
        AccessRole.organization => 'Admin / Officer',
        AccessRole.member => 'Member',
      };
}
