/// Central place for secure-storage keys so the auth data layer and the
/// Dio interceptor agree on exactly what's stored where.
class AuthStorageKeys {
  AuthStorageKeys._();

  static const accessToken = 'auth.access_token';
  static const refreshToken = 'auth.refresh_token';
  static const userJson = 'auth.user_json';
}
