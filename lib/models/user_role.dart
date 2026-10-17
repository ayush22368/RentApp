enum UserRole {
  superAdmin,
  owner,
  normal,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.owner:
        return 'Property Owner / Agent';
      case UserRole.normal:
        return 'User';
    }
  }

  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isOwner => this == UserRole.owner;
  bool get canManageProperties => this == UserRole.superAdmin || this == UserRole.owner;
}
