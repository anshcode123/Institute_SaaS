import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_storage_keys.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.onSessionExpired});

  final Dio dio;
  final Future<void> Function() onSessionExpired;
  Future<String>? _refreshFuture;

  static const _authFreeEndpoints = [
    '/auth/super-admin/login',
    '/auth/institute/login',
    '/auth/refresh',
  ];

  bool _isAuthFree(String path) => _authFreeEndpoints.any(path.endsWith);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthFree(options.path)) {
      final token =
          await SecureStorage.instance.read(AuthStorageKeys.accessToken);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    if (status != 401 ||
        _isAuthFree(path) ||
        err.requestOptions.extra['authRetry'] == true) {
      handler.next(err);
      return;
    }

    final refreshFuture = _refreshFuture ??= _refreshAccessToken();
    try {
      final newAccessToken = await refreshFuture;
      final retryOptions = err.requestOptions;
      retryOptions.extra['authRetry'] = true;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      handler.resolve(await dio.fetch(retryOptions));
    } on _InvalidRefreshToken {
      await SecureStorage.instance.delete(AuthStorageKeys.accessToken);
      await SecureStorage.instance.delete(AuthStorageKeys.refreshToken);
      await SecureStorage.instance.delete(AuthStorageKeys.userJson);
      await onSessionExpired();
      handler.next(err);
    } on DioException {
      handler.next(err);
    } finally {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    }
  }

  Future<String> _refreshAccessToken() async {
    final refreshToken =
        await SecureStorage.instance.read(AuthStorageKeys.refreshToken);
    if (refreshToken == null) throw _InvalidRefreshToken();

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    try {
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await SecureStorage.instance.write(
        AuthStorageKeys.accessToken,
        newAccessToken,
      );
      await SecureStorage.instance.write(
        AuthStorageKeys.refreshToken,
        newRefreshToken,
      );
      return newAccessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw _InvalidRefreshToken();
      }
      rethrow;
    }
  }
}

class _InvalidRefreshToken implements Exception {}
