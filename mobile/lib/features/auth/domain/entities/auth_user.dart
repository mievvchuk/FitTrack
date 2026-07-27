class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.apiUserId,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.roles = const <String>['user'],
    this.permissions = const <String>[],
  });

  final String id;
  final String? apiUserId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final List<String> roles;
  final List<String> permissions;

  bool get isUser => hasRole('user');
  bool get isTrainer => hasRole('trainer');
  bool get isAdmin => hasRole('admin');

  bool hasRole(String roleCode) {
    return roles.contains(roleCode);
  }

  bool can(String permissionCode) {
    return permissions.contains(permissionCode);
  }

  AuthUser copyWith({
    String? id,
    String? apiUserId,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    List<String>? roles,
    List<String>? permissions,
  }) {
    return AuthUser(
      id: id ?? this.id,
      apiUserId: apiUserId ?? this.apiUserId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }
}
