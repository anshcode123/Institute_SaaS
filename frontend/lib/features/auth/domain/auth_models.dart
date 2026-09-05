/// Which portal is authenticating. Kept distinct from the User.role coming
/// back from the server - this only decides which login form/endpoint the
/// UI uses; the server is always the source of truth for the actual role.
enum LoginPortal { superAdmin, institute }

class AuthUser {
  final String id;
  final String? email;
  final String name;
  final String role;
  final String? instituteId;

  const AuthUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.instituteId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        email: json['email'] as String?,
        instituteId: json['instituteId'] as String?,
      );
}

class AuthSession {
  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}
