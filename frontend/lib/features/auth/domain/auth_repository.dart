import 'auth_models.dart';

/// Domain-layer contract. The presentation layer (providers/screens) talks
/// only to this interface, never directly to Dio - so the data layer can be
/// swapped/mocked without touching UI or state logic.
abstract class AuthRepository {
  Future<AuthSession> loginSuperAdmin(
      {required String email, required String password});

  Future<AuthSession> loginInstitute(
      {required String instituteCode, required String password});

  Future<AuthSession> loginTeacher(
      {required String email, required String password});

  Future<AuthSession> loginStudent(
      {required String email, required String password});

  Future<AuthSession> loginParent(
      {required String email, required String password});

  /// Restores a session from secure storage on app start, if one exists
  /// and the refresh token is still usable. Returns null if not logged in.
  Future<AuthSession?> restoreSession();

  Future<void> logout();
}
