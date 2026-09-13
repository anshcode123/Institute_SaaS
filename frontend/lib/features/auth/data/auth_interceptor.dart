import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_storage_keys.dart';

/// Attaches the access token to every request and transparently refreshes
/// it on a 401 (once), retrying all in-flight requests with the fresh token.
/// If the refresh itself fails, the session is cleared and [onSessionExpired]
/// is called so the app-level auth state can drop back to "unauthenticated".
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.onSessionExpired});

  final Dio dio;
  final Future<void> Function() onSessionExpired;

  Completer<String?>? _refreshCompleter;

  static const _authFreeEndpoints = [
    '/auth/super-admin/login',
    '/auth/institute/login',
    '/auth/teacher/login',
    '/auth/student/login',
    '/auth/parent/login',
    '/auth/refresh',
    '/auth/logout',
  ];

  bool _isAuthFree(String path) =>
      path.startsWith('/auth') || _authFreeEndpoints.any(path.endsWith);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isAuthFree(options.path)) {
      final token =
          await SecureStorage.instance.read(AuthStorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status != 401 || _isAuthFree(path)) {
      handler.next(err);
      return;
    }

    // If a refresh is already in progress, await the new token and retry.
    if (_refreshCompleter != null) {
      try {
        final newToken = await _refreshCompleter!.future;
        if (newToken != null) {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(retryOptions);
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {}
      handler.next(err);
      return;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final refreshToken =
          await SecureStorage.instance.read(AuthStorageKeys.refreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(null);
        await onSessionExpired();
        handler.next(err);
        return;
      }

      final response =
          await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final data = response.data['data'] as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await SecureStorage.instance
          .write(AuthStorageKeys.accessToken, newAccessToken);
      await SecureStorage.instance
          .write(AuthStorageKeys.refreshToken, newRefreshToken);

      completer.complete(newAccessToken);

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      completer.complete(null);
      await onSessionExpired();
      handler.next(err);
    } finally {
      if (_refreshCompleter == completer) {
        _refreshCompleter = null;
      }
    }
  }
}
