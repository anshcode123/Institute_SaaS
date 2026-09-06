import 'package:dio/dio.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_storage_keys.dart';

/// Attaches the access token to every request and transparently refreshes
/// it on a 401 (once), retrying the original request. If the refresh
/// itself fails, the session is cleared and [onSessionExpired] is called
/// so the app-level auth state can drop back to "unauthenticated".
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.onSessionExpired});

  final Dio dio;
  final Future<void> Function() onSessionExpired;

  bool _isRefreshing = false;

  static const _authFreeEndpoints = [
    '/auth/super-admin/login',
    '/auth/institute/login',
    '/auth/refresh',
  ];

  bool _isAuthFree(String path) => _authFreeEndpoints.any(path.endsWith);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isAuthFree(options.path)) {
      final token = await SecureStorage.instance.read(AuthStorageKeys.accessToken);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status != 401 || _isAuthFree(path) || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await SecureStorage.instance.read(AuthStorageKeys.refreshToken);
      if (refreshToken == null) {
        await onSessionExpired();
        handler.next(err);
        return;
      }

      final response = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final data = response.data['data'] as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await SecureStorage.instance.write(AuthStorageKeys.accessToken, newAccessToken);
      await SecureStorage.instance.write(AuthStorageKeys.refreshToken, newRefreshToken);

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await onSessionExpired();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
